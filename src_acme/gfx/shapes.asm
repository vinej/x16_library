;ACME
; =====================================================================
; x16lib :: gfx/shapes.asm -- circle, disc, flood fill (any bitmap)
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does,
; under X16_USE_SHAPES).
;
; The shapes are ENGINE-AGNOSTIC and live here ONCE, not per engine:
; they draw through three entry symbols and read the canvas bounds
; through two, all overridable BEFORE this file is sourced. Left alone
; they bind to the 2bpp module (bitmap2). Any engine with the same call
; shapes can sit behind them:
;   - bitmap2 (2bpp): the default, no work.
;   - bitmap (8bpp): predefine SHP_PSET / SHP_HLINE to small shims that
;     move the colour from A into X16_P3 (where gfx_pset wants it), then
;     jmp gfx_pset / gfx_hline; SHP_READ = gfx_read; SHP_W/H = 320/240.
;   - CXGEOS points them at its graphics port and gets every mode at once.
;
;   SHP_PSET   pset:  P0/P1 = x, P2/P3 = y, A = colour (must clip)
;   SHP_READ   read:  P0/P1 = x, P2/P3 = y -> A = the pixel
;   SHP_HLINE  hline: P0/P1 = x, P2/P3 = y, P4/P5 = len, A = colour
;   SHP_W/H    the ADDRESS of a little-endian word: canvas w / h
;
; The P block is reloaded before every call, so the bound routines may
; clobber it freely; X16_T0..T7 are never touched here.
;
;   shape_circle  in: P0/P1 = cx, P2/P3 = cy, P4 = r (0-255), A = colour
;                 An outline, by the midpoint walk, plotted with
;                 SHP_PSET -- so it clips wherever pset clips.
;   shape_disc    same arguments, filled with spans. SHP_HLINE does not
;                 clip (the module policy), so keep a disc on screen.
;   shape_ellipse in: P0/P1 = cx, P2/P3 = cy, P4 = rx, P5 = ry (each
;                 0-255), A = colour. An axis-aligned outline by the
;                 midpoint walk, plotted with SHP_PSET -- so it clips
;                 wherever pset clips.
;   shape_fellipse same arguments, filled with spans. Like shape_disc
;                 it draws with SHP_HLINE, so keep it on screen.
;   shape_flood   in: P0/P1 = x, P2/P3 = y, A = colour. Scanline seed
;                 fill of the region containing (x,y). Bounds-checked
;                 against SHP_W/SHP_H, so it never reads off canvas.
;                 Carry set if the seed stack overflowed -- a very
;                 tortured region may come back incomplete.
; =====================================================================

!zone x16_shapes {

; ---------------------------------------------------------------------
; shape_circle / shape_disc -- one walk for both, like the ellipse:
; .efl routes each plot through .eplot to the octant points (outline)
; or the spans (fill).
; ---------------------------------------------------------------------
shape_circle
	sta .col
	stz .efl                    ; outline: the octant point pairs
	bra .cgo
shape_disc
	sta .col
	lda #1                      ; filled: spans at cy +/- b instead
	sta .efl
.cgo
	jsr .take_cxy               ; cx/cy out of the P block, x=r, y=0
.cloop
	lda .y                      ; while y <= x
	cmp .x
	beq .cplot                  ; the diagonal point still plots
	bcs .cdone
.cplot
	lda .x                      ; the (x,y) octant pair...
	sta .a
	lda .y
	sta .b
	jsr .eplot
	lda .y                      ; ...and the (y,x) pair
	sta .a
	lda .x
	sta .b
	jsr .eplot
	jsr .step                   ; the midpoint error walk
	bra .cloop
.cdone
	rts

; --- shared circle/disc/ellipse machinery -------------------------------
.take_cxy                       ; P -> locals; x = r, y = 0, err = 1 - r
	lda X16_P0
	sta .cx
	lda X16_P1
	sta .cx+1
	lda X16_P2
	sta .cy
	lda X16_P3
	sta .cy+1
	lda X16_P4
	sta .x
	lda #0
	sta .y
	sec                         ; err = 1 - r, signed 16-bit
	lda #1
	sbc .x
	sta .err
	lda #0
	sbc #0
	sta .err+1
	rts

.step                           ; y++; err < 0 ? err += 2y+1
	inc .y                      ;      else x--, err += 2(y-x)+1
	bit .err+1
	bmi .grow
	dec .x
	sec                         ; t = y - x, sign-extended
	lda .y
	sbc .x
	sta .t
	lda #0
	sbc #0
	sta .t+1
	bra .apply
.grow
	lda .y                      ; t = y (positive)
	sta .t
	lda #0
	sta .t+1
.apply
	asl .t                      ; err += 2t + 1
	rol .t+1
	inc .t
	bne +
	inc .t+1
+	clc
	lda .err
	adc .t
	sta .err
	lda .err+1
	adc .t+1
	sta .err+1
	rts

.pair4                          ; pset the 4 sign combos of (cx±a, cy±b)
	lda #0
	sta .sx
	sta .sy
.p4go
	jsr .emit1
	lda .sx                     ; walk ++, -+, +-, -- via two flags
	eor #1
	sta .sx
	bne .p4go
	lda .sy
	eor #1
	sta .sy
	bne .p4go
	rts

.emit1                          ; one pset at (cx sx? -a : +a, cy sy? -b : +b)
	lda .sx
	bne .e1xm
	clc                         ; x = cx + a
	lda .cx
	adc .a
	sta X16_P0
	lda .cx+1
	adc #0
	sta X16_P1
	bra .e1y
.e1xm
	jsr .subx                   ; x = cx - a
.e1y
	jsr .sety
	lda .col
	jmp SHP_PSET

.span2                          ; hline half-width a at cy+b and cy-b
	lda #0
	sta .sy
	jsr .espan
	lda #1
	sta .sy
	; fall through
.espan
	jsr .subx                   ; x = cx - a
	jsr .sety
	lda .a                      ; len = 2a + 1
	sta X16_P4
	lda #0
	sta X16_P5
	asl X16_P4
	rol X16_P5
	inc X16_P4
	bne +
	inc X16_P5
+	lda .col
	jmp SHP_HLINE

.subx                           ; P0/P1 = cx - a
	sec
	lda .cx
	sbc .a
	sta X16_P0
	lda .cx+1
	sbc #0
	sta X16_P1
	rts

.sety                           ; P2/P3 = cy + b, or cy - b when .sy
	lda .sy
	bne .sym
	clc
	lda .cy
	adc .b
	sta X16_P2
	lda .cy+1
	adc #0
	sta X16_P3
	rts
.sym
	sec
	lda .cy
	sbc .b
	sta X16_P2
	lda .cy+1
	sbc #0
	sta X16_P3
	rts

; ---------------------------------------------------------------------
; shape_ellipse / shape_fellipse
; ---------------------------------------------------------------------
; One walk serves both: the error-form midpoint ellipse (Zingl),
; quadrant II from (-rx, 0) up to (0, ry), mirrored 4 ways by the
; circle's own .pair4 / .span2. The decision terms reach 2*rx*ry^2
; (about 33M at 255/255), so the arithmetic is 32-bit; the one setup
; product rx * 2ry^2 is a repeated subtract, a few thousand cycles at
; the very worst -- noise against the drawing itself.
;   dx = ry^2 - rx*2ry^2, dy = rx^2, err = dx + dy
;   each step: e2 = 2*err;
;     e2 >= dx ?  x++, err += dx += 2ry^2
;     e2 <= dy ?  y++, err += dy += 2rx^2
;   while x <= 0; then a centre column finishes the flat tips (small
;   rx). A row's widest span always lands before its narrower echoes,
;   so the fill's overdraw is harmless, same as the disc's.
; ---------------------------------------------------------------------
shape_ellipse
	sta .col
	stz .efl
	bra .etake
shape_fellipse
	sta .col
	lda #1
	sta .efl
.etake
	lda X16_P0                  ; centre out of the P block
	sta .cx
	lda X16_P1
	sta .cx+1
	lda X16_P2
	sta .cy
	lda X16_P3
	sta .cy+1
	lda X16_P4
	sta .ew
	lda X16_P5
	sta .eh

	lda .eh                     ; .sq = ry^2
	jsr .sq16
	lda .sq                     ; dx = ry^2 (the rx*2ry^2 comes off below)
	sta .edx
	lda .sq+1
	sta .edx+1
	stz .edx+2
	stz .edx+3
	lda .sq                     ; .e2b = 2ry^2
	sta .e2b
	lda .sq+1
	sta .e2b+1
	stz .e2b+2
	stz .e2b+3
	asl .e2b
	rol .e2b+1
	rol .e2b+2
	ldx .ew                     ; dx -= rx * 2ry^2, one 2ry^2 at a time
	beq .exset
.emul
	sec
	lda .edx
	sbc .e2b
	sta .edx
	lda .edx+1
	sbc .e2b+1
	sta .edx+1
	lda .edx+2
	sbc .e2b+2
	sta .edx+2
	lda .edx+3
	sbc .e2b+3
	sta .edx+3
	dex
	bne .emul
.exset
	lda .ew                     ; .sq = rx^2
	jsr .sq16
	lda .sq                     ; dy = rx^2
	sta .edy
	lda .sq+1
	sta .edy+1
	stz .edy+2
	stz .edy+3
	lda .sq                     ; .e2a = 2rx^2
	sta .e2a
	lda .sq+1
	sta .e2a+1
	stz .e2a+2
	stz .e2a+3
	asl .e2a
	rol .e2a+1
	rol .e2a+2
	clc                         ; err = dx + dy
	lda .edx
	adc .edy
	sta .eerr
	lda .edx+1
	adc .edy+1
	sta .eerr+1
	lda .edx+2
	adc .edy+2
	sta .eerr+2
	lda .edx+3
	adc .edy+3
	sta .eerr+3
	sec                         ; x = -rx (16-bit signed), y = 0
	lda #0
	sbc .ew
	sta .ex
	lda #0
	sbc #0
	sta .ex+1
	stz .ey

.eloop
	sec                         ; this step's quadrant point: (|x|, y)
	lda #0
	sbc .ex
	sta .a
	lda .ey
	sta .b
	jsr .eplot
	lda .eerr                   ; e2 = 2*err, copied with the shift
	asl
	sta .ee2
	lda .eerr+1
	rol
	sta .ee2+1
	lda .eerr+2
	rol
	sta .ee2+2
	lda .eerr+3
	rol
	sta .ee2+3
	sec                         ; e2 >= dx?  sign of e2 - dx decides
	lda .ee2
	sbc .edx
	lda .ee2+1
	sbc .edx+1
	lda .ee2+2
	sbc .edx+2
	lda .ee2+3
	sbc .edx+3
	bmi .noxstep
	inc .ex                     ; x++
	bne .exdx
	inc .ex+1
.exdx
	clc                         ; err += dx += 2ry^2
	lda .edx
	adc .e2b
	sta .edx
	lda .edx+1
	adc .e2b+1
	sta .edx+1
	lda .edx+2
	adc .e2b+2
	sta .edx+2
	lda .edx+3
	adc .e2b+3
	sta .edx+3
	clc
	lda .eerr
	adc .edx
	sta .eerr
	lda .eerr+1
	adc .edx+1
	sta .eerr+1
	lda .eerr+2
	adc .edx+2
	sta .eerr+2
	lda .eerr+3
	adc .edx+3
	sta .eerr+3
.noxstep
	sec                         ; e2 <= dy?  sign of dy - e2 decides
	lda .edy
	sbc .ee2
	lda .edy+1
	sbc .ee2+1
	lda .edy+2
	sbc .ee2+2
	lda .edy+3
	sbc .ee2+3
	bmi .noystep
	inc .ey                     ; y++
	clc                         ; err += dy += 2rx^2
	lda .edy
	adc .e2a
	sta .edy
	lda .edy+1
	adc .e2a+1
	sta .edy+1
	lda .edy+2
	adc .e2a+2
	sta .edy+2
	lda .edy+3
	adc .e2a+3
	sta .edy+3
	clc
	lda .eerr
	adc .edy
	sta .eerr
	lda .eerr+1
	adc .edy+1
	sta .eerr+1
	lda .eerr+2
	adc .edy+2
	sta .eerr+2
	lda .eerr+3
	adc .edy+3
	sta .eerr+3
.noystep
	lda .ex+1                   ; while x <= 0
	bmi .econt
	ora .ex
	bne .etip
.econt
	jmp .eloop
.etip
	lda .ey                     ; flat tip: the centre column on to ry
	cmp .eh
	bcs .edone
	inc .ey
	stz .a
	lda .ey
	sta .b
	jsr .eplot
	bra .etip
.edone
	rts

.eplot                          ; the 4-way points, or the two spans
	lda .efl
	beq .eout
	jmp .span2
.eout
	jmp .pair4

.sq16                           ; A * A -> .sq (16-bit), by repetition
	sta .sm
	stz .sq
	stz .sq+1
	tax
	beq .sqdone
.sqlp
	clc
	lda .sq
	adc .sm
	sta .sq
	bcc .sqnc
	inc .sq+1
.sqnc
	dex
	bne .sqlp
.sqdone
	rts

; ---------------------------------------------------------------------
; shape_flood
; ---------------------------------------------------------------------
; Pop a seed, widen it into a span of the target colour, fill the span,
; then scan the rows above and below for runs of target and push one
; seed per run. The stack holds seeds as x.w y.w; when it is full a
; seed is dropped and the overflow is remembered in the carry.
; ---------------------------------------------------------------------
FLOOD_MAX = 96                  ; seeds; 4 bytes each

shape_flood
	sta .col
	lda #0
	sta .ovf
	sta .sp
	jsr SHP_READ                ; the target = the seed's own colour
	                            ; (read at the CALLER's P block)
	sta .tgt
	cmp .col                    ; filling with itself never ends: done
	bne .fseed
	clc                         ; (no overflow could have happened yet)
	rts
.fseed
	lda X16_P0                  ; push the seed
	sta .qx
	lda X16_P1
	sta .qx+1
	lda X16_P2
	sta .qy
	lda X16_P3
	sta .qy+1
	jsr .push
.floop
	lda .sp                     ; stack empty: finished
	bne .fbody
	jmp .fexit
.fbody
	jsr .pop                    ; seed -> .qx/.qy
	jsr .rd_q                   ; still target? (may have been filled)
	cmp .tgt
	bne .floop

	lda .qx                     ; widen left: xl = leftmost target
	sta .xl
	lda .qx+1
	sta .xl+1
.wleft
	lda .xl
	ora .xl+1
	beq .wldone                 ; at column 0
	sec                         ; probe xl-1
	lda .xl
	sbc #1
	sta .qx
	lda .xl+1
	sbc #0
	sta .qx+1
	jsr .rd_q
	cmp .tgt
	bne .wldone
	lda .qx
	sta .xl
	lda .qx+1
	sta .xl+1
	bra .wleft
.wldone
	lda .xl                     ; widen right: xr = rightmost target
	sta .xr                     ; (qy already holds the row)
	lda .xl+1
	sta .xr+1
.wright
	clc                         ; probe xr+1, stop at SHP_W-1
	lda .xr
	adc #1
	sta .qx
	lda .xr+1
	adc #0
	sta .qx+1
	lda .qx                     ; qx == W? off the right edge
	cmp SHP_W
	bne .wrprobe
	lda .qx+1
	cmp SHP_W+1
	beq .wrdone
.wrprobe
	jsr .rd_q
	cmp .tgt
	bne .wrdone
	lda .qx
	sta .xr
	lda .qx+1
	sta .xr+1
	bra .wright
.wrdone
	lda .xl                     ; fill the span: hline(xl, y, xr-xl+1)
	sta X16_P0
	lda .xl+1
	sta X16_P1
	lda .qy
	sta X16_P2
	lda .qy+1
	sta X16_P3
	sec
	lda .xr
	sbc .xl
	sta X16_P4
	lda .xr+1
	sbc .xl+1
	sta X16_P5
	inc X16_P4
	bne +
	inc X16_P5
+	lda .col
	jsr SHP_HLINE

	lda .qy                     ; .scanrow clobbers .qy, so keep the filled
	sta .row                    ; row here for BOTH neighbour scans
	lda .qy+1
	sta .row+1

	lda .row                    ; the row above...
	sta .ry
	lda .row+1
	sta .ry+1
	lda .ry
	ora .ry+1
	beq .below                  ; row 0 has nothing above
	sec
	lda .ry
	sbc #1
	sta .ry
	lda .ry+1
	sbc #0
	sta .ry+1
	jsr .scanrow
.below
	clc                         ; ...and the row below
	lda .row
	adc #1
	sta .ry
	lda .row+1
	adc #0
	sta .ry+1
	lda .ry                     ; ry == H? off the bottom
	cmp SHP_H
	bne .bscan
	lda .ry+1
	cmp SHP_H+1
	beq .fnext
.bscan
	jsr .scanrow
.fnext
	jmp .floop
.fexit
	lsr .ovf                    ; overflow -> carry
	rts

; scan .xl...xr on row .ry for runs of target; push one seed per run
.scanrow
	lda #0
	sta .run
	lda .xl
	sta .tx
	lda .xl+1
	sta .tx+1
.srloop
	lda .tx                     ; read (tx, ry)
	sta .qx
	lda .tx+1
	sta .qx+1
	lda .ry
	sta .qy
	lda .ry+1
	sta .qy+1
	jsr .rd_q
	cmp .tgt
	bne .srmiss
	lda .run                    ; entering a run: one seed
	bne .srnext
	lda #1
	sta .run
	jsr .push
	bra .srnext
.srmiss
	lda #0
	sta .run
.srnext
	lda .tx                     ; tx == xr? done
	cmp .xr
	bne .srinc
	lda .tx+1
	cmp .xr+1
	beq .srdone
.srinc
	inc .tx
	bne .srloop
	inc .tx+1
	bra .srloop
.srdone
	rts

.rd_q                           ; read at (.qx, .qy), laid out as P0..P3
	ldx #3
.rq_l
	lda .qx,x
	sta X16_P0,x
	dex
	bpl .rq_l
	jmp SHP_READ

.push                           ; (.qx,.qy) onto the stack, or drop + ovf
	lda .sp
	cmp #FLOOD_MAX
	bcc +
	lda #1                      ; remembered; lsr at exit -> carry
	sta .ovf
	rts
+	asl                         ; sp * 4
	asl
	tax
	lda .qx
	sta .stk,x
	lda .qx+1
	sta .stk+1,x
	lda .qy
	sta .stk+2,x
	lda .qy+1
	sta .stk+3,x
	inc .sp
	rts

.pop                            ; the top seed -> (.qx,.qy)
	dec .sp
	lda .sp
	asl
	asl
	tax
	lda .stk,x
	sta .qx
	lda .stk+1,x
	sta .qx+1
	lda .stk+2,x
	sta .qy
	lda .stk+3,x
	sta .qy+1
	rts

; --- the state ---------------------------------------------------------
.col !byte 0
.cx  !word 0
.cy  !word 0
.x   !byte 0
.y   !byte 0
.a   !byte 0
.b   !byte 0
.sx  !byte 0
.sy  !byte 0
.err !word 0
.t   !word 0

.efl !byte 0
.ew  !byte 0
.eh  !byte 0
.ex  !word 0
.ey  !byte 0
.sm  !byte 0
.sq  !word 0
.edx !fill 4, 0
.edy !fill 4, 0
.eerr !fill 4, 0
.ee2 !fill 4, 0
.e2a !fill 4, 0
.e2b !fill 4, 0

.tgt !byte 0
.ovf !byte 0
.sp  !byte 0
.qx  !word 0
.qy  !word 0
.xl  !word 0
.xr  !word 0
.ry  !word 0
.row !word 0
.tx  !word 0
.run !byte 0
.stk !fill FLOOD_MAX * 4, 0

; ---------------------------------------------------------------------
; shape_polygon / shape_fpolygon -- regular convex polygons (X16_USE_SHAPES_POLY)
; ---------------------------------------------------------------------
; A regular N-gon: N vertices evenly spaced on a circle of radius r about
; (cx, cy), the first at byte-angle `rotation` (0 = east, 64 = south, the
; sin8/cos8 convention). shape_polygon draws the outline through SHP_PSET
; (so it clips like shape_circle); shape_fpolygon fills it with SHP_HLINE
; spans (so it does NOT clip -- keep it on screen, like shape_disc).
;
;   in: P0/P1 = cx, P2/P3 = cy, P4 = radius (0-255),
;       P5 = sides (3..POLY_MAX; fewer draws nothing, more is clamped),
;       P6 = rotation (byte angle), A = colour
;
; Vertices come from sin8/cos8 (hence the X16_USE_MATH dependency) scaled
; by r and rounded. The fill is a per-scanline convex span fill: for each
; row it finds the two edge crossings and draws between them, half-open at
; the bottom row so tiled polygons do not double-paint a shared edge. It
; is a one-shot primitive (cost ~ sides * height), not a per-frame filler.
;
; House style, as everywhere in this file: all labels are zone-locals with
; unique names (ACME's @cheap locals do not reset at a zone-local routine
; label, so two routines could not each own an @loop), and the work is cut
; into small routines so no branch reaches past its 127-byte range.
; ---------------------------------------------------------------------
!ifdef X16_USE_SHAPES_POLY {

POLY_MAX = 24                   ; vertices; the buffers below are 2 bytes each

shape_polygon
	sta poly_col
	stz poly_efl                ; outline
	jmp .poly_begin
shape_fpolygon
	sta poly_col
	lda #1                      ; filled
	sta poly_efl
	; fall through
.poly_begin
	lda X16_P5                  ; clamp the side count to 3..POLY_MAX
	cmp #3
	bcc .pg_bret                ; fewer than 3: not a polygon
	cmp #(POLY_MAX + 1)
	bcc .pg_bnok
	lda #POLY_MAX
.pg_bnok
	sta poly_n
	lda X16_P0
	sta poly_cx
	lda X16_P1
	sta poly_cx+1
	lda X16_P2
	sta poly_cy
	lda X16_P3
	sta poly_cy+1
	lda X16_P4
	sta poly_r
	stz poly_acc                ; angle accumulator = rotation << 8
	lda X16_P6
	sta poly_acc+1
	jsr .poly_verts
	lda poly_efl
	bne .pg_bfill
	jmp .poly_outline
.pg_bfill
	jmp .poly_fill
.pg_bret
	rts

; compute the N vertices into poly_vx[]/poly_vy[]
.poly_verts
	jsr .poly_step              ; poly_step = 65536 / n
	stz poly_i
.pg_vloop
	lda poly_i
	cmp poly_n
	beq .pg_vend
	lda poly_acc+1              ; this vertex's byte angle
	pha
	jsr cos8                    ; A = cos * 127 (signed)
	jsr .poly_scale             ; poly_off = round(r * A / 128), signed
	lda poly_i
	asl
	tax                         ; 2*i
	clc
	lda poly_cx
	adc poly_off
	sta poly_vx,x
	lda poly_cx+1
	adc poly_off+1
	sta poly_vx+1,x
	pla                         ; the angle again
	jsr sin8                    ; A = sin * 127 (signed)
	jsr .poly_scale
	lda poly_i
	asl
	tax
	clc
	lda poly_cy
	adc poly_off
	sta poly_vy,x
	lda poly_cy+1
	adc poly_off+1
	sta poly_vy+1,x
	clc                         ; acc += step
	lda poly_acc
	adc poly_step
	sta poly_acc
	lda poly_acc+1
	adc poly_step+1
	sta poly_acc+1
	inc poly_i
	bra .pg_vloop
.pg_vend
	rts

; poly_off = round(poly_r * |A| / 128) with A's sign, A a signed byte
.poly_scale
	stz poly_sgn
	pha
	and #$80
	beq .pg_spos
	inc poly_sgn
	pla
	eor #$FF
	clc
	adc #1
	bra .pg_smul
.pg_spos
	pla
.pg_smul
	jsr .poly_mul8              ; poly_p16 = poly_r * |A|
	clc
	lda poly_p16                ; + 0.5 LSB, so >>7 rounds
	adc #64
	sta poly_p16
	lda poly_p16+1
	adc #0
	sta poly_p16+1
	lda poly_p16                ; >>7 (product < 32768, so one byte out)
	asl
	lda poly_p16+1
	rol
	sta poly_off
	stz poly_off+1
	lda poly_sgn
	beq .pg_sdone
	sec                         ; negate
	lda #0
	sbc poly_off
	sta poly_off
	lda #0
	sbc poly_off+1
	sta poly_off+1
.pg_sdone
	rts

; poly_p16 = poly_r * A  (8x8 -> 16, unsigned)
.poly_mul8
	sta poly_t
	lda #0
	ldx #8
.pg_mloop
	lsr poly_t
	bcc .pg_mskip
	clc
	adc poly_r
.pg_mskip
	ror
	ror poly_p16
	dex
	bne .pg_mloop
	sta poly_p16+1
	rts

; poly_step = floor(65536 / poly_n), by restoring division of $010000
.poly_step
	stz poly_dvd
	stz poly_dvd+1
	lda #1
	sta poly_dvd+2
	stz poly_rem
	stz poly_step
	stz poly_step+1
	ldx #24
.pg_dloop
	asl poly_dvd
	rol poly_dvd+1
	rol poly_dvd+2
	rol poly_rem                ; carry = the remainder's 9th bit
	bcs .pg_dsub                ; overflowed 8 bits: certainly >= n
	lda poly_rem
	cmp poly_n
	bcc .pg_dnoq
.pg_dsub
	lda poly_rem                ; carry is set on both paths here
	sbc poly_n
	sta poly_rem
	sec                         ; quotient bit = 1
	bra .pg_dbit
.pg_dnoq
	clc                         ; quotient bit = 0
.pg_dbit
	rol poly_step
	rol poly_step+1
	dex
	bne .pg_dloop
	rts

; --- outline ---------------------------------------------------------
.poly_outline
	stz poly_i
.pg_oloop
	lda poly_i                  ; endpoint 0 = vertex i
	asl
	tax
	lda poly_vx,x
	sta poly_lx0
	lda poly_vx+1,x
	sta poly_lx0+1
	lda poly_vy,x
	sta poly_ly0
	lda poly_vy+1,x
	sta poly_ly0+1
	lda poly_i                  ; endpoint 1 = vertex (i+1) mod n
	clc
	adc #1
	cmp poly_n
	bne .pg_ojok
	lda #0
.pg_ojok
	asl
	tax
	lda poly_vx,x
	sta poly_lx1
	lda poly_vx+1,x
	sta poly_lx1+1
	lda poly_vy,x
	sta poly_ly1
	lda poly_vy+1,x
	sta poly_ly1+1
	jsr .poly_line
	inc poly_i
	lda poly_i
	cmp poly_n
	bne .pg_oloop
	rts

; 16-bit Bresenham from (lx0,ly0) to (lx1,ly1), plotting through SHP_PSET
; (the gfx2_line algorithm, engine-agnostic and clipping via the binding)
.poly_line
	sec                         ; dx = |x1 - x0|, sx = direction
	lda poly_lx1
	sbc poly_lx0
	sta poly_ldx
	lda poly_lx1+1
	sbc poly_lx0+1
	sta poly_ldx+1
	bpl .pg_ldxp
	sec
	lda #0
	sbc poly_ldx
	sta poly_ldx
	lda #0
	sbc poly_ldx+1
	sta poly_ldx+1
	lda #$FF
	sta poly_lsx
	sta poly_lsx+1
	bra .pg_ldxd
.pg_ldxp
	lda #1
	sta poly_lsx
	stz poly_lsx+1
.pg_ldxd
	sec                         ; dy = -|y1 - y0|, sy = direction
	lda poly_ly1
	sbc poly_ly0
	sta poly_lt
	lda poly_ly1+1
	sbc poly_ly0+1
	sta poly_lt+1
	bpl .pg_ldyp
	sec
	lda #0
	sbc poly_lt
	sta poly_lt
	lda #0
	sbc poly_lt+1
	sta poly_lt+1
	lda #$FF
	sta poly_lsy
	sta poly_lsy+1
	bra .pg_ldyd
.pg_ldyp
	lda #1
	sta poly_lsy
	stz poly_lsy+1
.pg_ldyd
	sec                         ; ldy = -|dy|
	lda #0
	sbc poly_lt
	sta poly_ldy
	lda #0
	sbc poly_lt+1
	sta poly_ldy+1
	clc                         ; err = dx + dy
	lda poly_ldx
	adc poly_ldy
	sta poly_lerr
	lda poly_ldx+1
	adc poly_ldy+1
	sta poly_lerr+1
.pg_lloop
	lda poly_lx0
	sta X16_P0
	lda poly_lx0+1
	sta X16_P1
	lda poly_ly0
	sta X16_P2
	lda poly_ly0+1
	sta X16_P3
	lda poly_col
	jsr SHP_PSET
	lda poly_lx0                ; reached the endpoint?
	cmp poly_lx1
	bne .pg_lstep
	lda poly_lx0+1
	cmp poly_lx1+1
	bne .pg_lstep
	lda poly_ly0
	cmp poly_ly1
	bne .pg_lstep
	lda poly_ly0+1
	cmp poly_ly1+1
	bne .pg_lstep
	rts
.pg_lstep
	lda poly_lerr               ; e2 = 2 * err
	asl
	sta poly_le2
	lda poly_lerr+1
	rol
	sta poly_le2+1
	sec                         ; e2 >= dy ?  err += dy, x0 += sx
	lda poly_le2
	sbc poly_ldy
	lda poly_le2+1
	sbc poly_ldy+1
	bvc .pg_lnv1
	eor #$80
.pg_lnv1
	bmi .pg_lskx
	clc
	lda poly_lerr
	adc poly_ldy
	sta poly_lerr
	lda poly_lerr+1
	adc poly_ldy+1
	sta poly_lerr+1
	clc
	lda poly_lx0
	adc poly_lsx
	sta poly_lx0
	lda poly_lx0+1
	adc poly_lsx+1
	sta poly_lx0+1
.pg_lskx
	sec                         ; e2 <= dx ?  err += dx, y0 += sy
	lda poly_ldx
	sbc poly_le2
	lda poly_ldx+1
	sbc poly_le2+1
	bvc .pg_lnv2
	eor #$80
.pg_lnv2
	bmi .pg_lsky
	clc
	lda poly_lerr
	adc poly_ldx
	sta poly_lerr
	lda poly_lerr+1
	adc poly_ldx+1
	sta poly_lerr+1
	clc
	lda poly_ly0
	adc poly_lsy
	sta poly_ly0
	lda poly_ly0+1
	adc poly_lsy+1
	sta poly_ly0+1
.pg_lsky
	jmp .pg_lloop

; --- fill ------------------------------------------------------------
; one scanline at a time; .poly_scanline gathers the row's span and draws
; it, .poly_edge does the per-edge crossing. Kept apart so every branch
; stays in range and each routine owns its own zone-local labels.
.poly_fill
	jsr .poly_ybounds           ; poly_ymin / poly_ymax over all vertices
	lda poly_ymin
	sta poly_y
	lda poly_ymin+1
	sta poly_y+1
.pg_floop
	lda poly_ymax               ; y > ymax ? done
	cmp poly_y
	lda poly_ymax+1
	sbc poly_y+1
	bvc .pg_fl1
	eor #$80
.pg_fl1
	bmi .pg_fret                ; ymax < y
	jsr .poly_scanline
	inc poly_y
	bne .pg_floop
	inc poly_y+1
	bra .pg_floop
.pg_fret
	rts

; fill row poly_y: find the span (xl..xr) across the edges, draw it
.poly_scanline
	stz poly_found
	lda #$FF                    ; xl = +32767, xr = -32768
	sta poly_xl
	lda #$7F
	sta poly_xl+1
	stz poly_xr
	lda #$80
	sta poly_xr+1
	stz poly_i
.pg_slloop
	lda poly_i
	cmp poly_n
	beq .pg_sldraw
	jsr .poly_edge
	inc poly_i
	bra .pg_slloop
.pg_sldraw
	lda poly_found
	beq .pg_slret
	lda poly_xl                 ; span (xl .. xr) on row y
	sta X16_P0
	lda poly_xl+1
	sta X16_P1
	lda poly_y
	sta X16_P2
	lda poly_y+1
	sta X16_P3
	sec                         ; len = xr - xl + 1
	lda poly_xr
	sbc poly_xl
	sta X16_P4
	lda poly_xr+1
	sbc poly_xl+1
	sta X16_P5
	inc X16_P4
	bne .pg_sllen
	inc X16_P5
.pg_sllen
	lda poly_col
	jmp SHP_HLINE
.pg_slret
	rts

; edge poly_i crossing row poly_y: if it spans the row, fold its x into
; poly_xl (min) / poly_xr (max) and set poly_found
.poly_edge
	lda poly_i                  ; vertex a = i
	asl
	tax
	lda poly_i                  ; vertex b = (i+1) mod n
	clc
	adc #1
	cmp poly_n
	bne .pg_ejok
	lda #0
.pg_ejok
	asl
	tay
	lda poly_vx,x
	sta poly_xa
	lda poly_vx+1,x
	sta poly_xa+1
	lda poly_vy,x
	sta poly_ya
	lda poly_vy+1,x
	sta poly_ya+1
	lda poly_vx,y
	sta poly_xb
	lda poly_vx+1,y
	sta poly_xb+1
	lda poly_vy,y
	sta poly_yb
	lda poly_vy+1,y
	sta poly_yb+1
	lda poly_ya                 ; top = the smaller-y endpoint
	cmp poly_yb
	lda poly_ya+1
	sbc poly_yb+1
	bvc .pg_escab
	eor #$80
.pg_escab
	bmi .pg_eatop               ; ya < yb
	lda poly_xb                 ; b on top
	sta poly_xtop
	lda poly_xb+1
	sta poly_xtop+1
	lda poly_yb
	sta poly_ytop
	lda poly_yb+1
	sta poly_ytop+1
	lda poly_xa
	sta poly_xbot
	lda poly_xa+1
	sta poly_xbot+1
	lda poly_ya
	sta poly_ybot
	lda poly_ya+1
	sta poly_ybot+1
	bra .pg_eedge
.pg_eatop
	lda poly_xa                 ; a on top
	sta poly_xtop
	lda poly_xa+1
	sta poly_xtop+1
	lda poly_ya
	sta poly_ytop
	lda poly_ya+1
	sta poly_ytop+1
	lda poly_xb
	sta poly_xbot
	lda poly_xb+1
	sta poly_xbot+1
	lda poly_yb
	sta poly_ybot
	lda poly_yb+1
	sta poly_ybot+1
.pg_eedge
	lda poly_y                  ; y < ytop ? out (also skips horizontals)
	cmp poly_ytop
	lda poly_y+1
	sbc poly_ytop+1
	bvc .pg_esct
	eor #$80
.pg_esct
	bmi .pg_eout
	lda poly_y                  ; y >= ybot ? out (half-open bottom)
	cmp poly_ybot
	lda poly_y+1
	sbc poly_ybot+1
	bvc .pg_escb
	eor #$80
.pg_escb
	bpl .pg_eout
	bra .pg_ein
.pg_eout
	rts
.pg_ein
	sec                         ; md3 = dy = ybot - ytop  (> 0)
	lda poly_ybot
	sbc poly_ytop
	sta poly_md3
	lda poly_ybot+1
	sbc poly_ytop+1
	sta poly_md3+1
	sec                         ; md2 = t = y - ytop
	lda poly_y
	sbc poly_ytop
	sta poly_md2
	lda poly_y+1
	sbc poly_ytop+1
	sta poly_md2+1
	sec                         ; md1 = dx = xbot - xtop (signed)
	lda poly_xbot
	sbc poly_xtop
	sta poly_md1
	lda poly_xbot+1
	sbc poly_xtop+1
	sta poly_md1+1
	stz poly_dxs
	lda poly_md1+1
	bpl .pg_edxpos
	inc poly_dxs                ; dx < 0: take |dx|, remember the sign
	sec
	lda #0
	sbc poly_md1
	sta poly_md1
	lda #0
	sbc poly_md1+1
	sta poly_md1+1
.pg_edxpos
	jsr .poly_umuldiv           ; poly_mdq = |dx| * t / dy
	lda poly_dxs
	bne .pg_exneg
	clc                         ; x = xtop + mdq
	lda poly_xtop
	adc poly_mdq
	sta poly_x
	lda poly_xtop+1
	adc poly_mdq+1
	sta poly_x+1
	bra .pg_egotx
.pg_exneg
	sec                         ; x = xtop - mdq
	lda poly_xtop
	sbc poly_mdq
	sta poly_x
	lda poly_xtop+1
	sbc poly_mdq+1
	sta poly_x+1
.pg_egotx
	lda #1
	sta poly_found
	lda poly_x                  ; xl = min(xl, x)
	cmp poly_xl
	lda poly_x+1
	sbc poly_xl+1
	bvc .pg_escl
	eor #$80
.pg_escl
	bpl .pg_enoxl               ; x >= xl
	lda poly_x
	sta poly_xl
	lda poly_x+1
	sta poly_xl+1
.pg_enoxl
	lda poly_xr                 ; xr = max(xr, x)
	cmp poly_x
	lda poly_xr+1
	sbc poly_x+1
	bvc .pg_escr
	eor #$80
.pg_escr
	bpl .pg_enoxr               ; xr >= x
	lda poly_x
	sta poly_xr
	lda poly_x+1
	sta poly_xr+1
.pg_enoxr
	rts

; poly_ymin / poly_ymax = the y extent of the vertices
.poly_ybounds
	lda poly_vy
	sta poly_ymin
	sta poly_ymax
	lda poly_vy+1
	sta poly_ymin+1
	sta poly_ymax+1
	lda #1
	sta poly_i
.pg_ybloop
	lda poly_i
	cmp poly_n
	beq .pg_ybend
	asl
	tax
	lda poly_vy,x               ; vy[i] < ymin ?
	cmp poly_ymin
	lda poly_vy+1,x
	sbc poly_ymin+1
	bvc .pg_ybc1
	eor #$80
.pg_ybc1
	bpl .pg_ybnmin
	lda poly_vy,x
	sta poly_ymin
	lda poly_vy+1,x
	sta poly_ymin+1
.pg_ybnmin
	lda poly_ymax               ; vy[i] > ymax ?
	cmp poly_vy,x
	lda poly_ymax+1
	sbc poly_vy+1,x
	bvc .pg_ybc2
	eor #$80
.pg_ybc2
	bpl .pg_ybnmax
	lda poly_vy,x
	sta poly_ymax
	lda poly_vy+1,x
	sta poly_ymax+1
.pg_ybnmax
	inc poly_i
	bra .pg_ybloop
.pg_ybend
	rts

; poly_mdq = poly_md1 * poly_md2 / poly_md3, all unsigned (16x16->32, /16)
.poly_umuldiv
	stz poly_prod+2
	stz poly_prod+3
	ldx #16
.pg_uml
	lsr poly_md2+1
	ror poly_md2
	bcc .pg_unoadd
	lda poly_prod+2
	clc
	adc poly_md1
	sta poly_prod+2
	lda poly_prod+3
	adc poly_md1+1
	bra .pg_urot
.pg_unoadd
	lda poly_prod+3
.pg_urot
	ror
	sta poly_prod+3
	ror poly_prod+2
	ror poly_prod+1
	ror poly_prod
	dex
	bne .pg_uml
	stz poly_rem
	stz poly_rem+1
	ldx #32
.pg_udv
	asl poly_prod
	rol poly_prod+1
	rol poly_prod+2
	rol poly_prod+3
	rol poly_rem
	rol poly_rem+1
	sec
	lda poly_rem
	sbc poly_md3
	tay
	lda poly_rem+1
	sbc poly_md3+1
	bcc .pg_udvno
	sta poly_rem+1
	sty poly_rem
	inc poly_prod
.pg_udvno
	dex
	bne .pg_udv
	lda poly_prod
	sta poly_mdq
	lda poly_prod+1
	sta poly_mdq+1
	rts

; --- polygon state ---------------------------------------------------
poly_col   !byte 0
poly_efl   !byte 0
poly_cx    !word 0
poly_cy    !word 0
poly_r     !byte 0
poly_n     !byte 0
poly_i     !byte 0
poly_acc   !word 0
poly_step  !word 0
poly_off   !word 0
poly_sgn   !byte 0
poly_p16   !word 0
poly_t     !byte 0
poly_dvd   !fill 3, 0
poly_rem   !word 0
poly_vx    !fill POLY_MAX * 2, 0
poly_vy    !fill POLY_MAX * 2, 0

poly_lx0   !word 0
poly_ly0   !word 0
poly_lx1   !word 0
poly_ly1   !word 0
poly_ldx   !word 0
poly_ldy   !word 0
poly_lerr  !word 0
poly_le2   !word 0
poly_lsx   !word 0
poly_lsy   !word 0
poly_lt    !word 0

poly_ymin  !word 0
poly_ymax  !word 0
poly_y     !word 0
poly_found !byte 0
poly_xa    !word 0
poly_ya    !word 0
poly_xb    !word 0
poly_yb    !word 0
poly_xtop  !word 0
poly_ytop  !word 0
poly_xbot  !word 0
poly_ybot  !word 0
poly_x     !word 0
poly_xl    !word 0
poly_xr    !word 0
poly_dxs   !byte 0
poly_md1   !word 0
poly_md2   !word 0
poly_md3   !word 0
poly_mdq   !word 0
poly_prod  !fill 4, 0

} ; X16_USE_SHAPES_POLY

; --- the default binding: the 2bpp module ------------------------------
; (evaluated here, at the END, so an overrider defines its symbols
; before sourcing the file and these !ifdefs stay quiet)
; The default-bound words are emitted UNCONDITIONALLY -- data inside an
; !ifndef would appear in pass 1 and vanish in pass 2 (the symbol exists
; by then), shifting every later address into a phase error.
shp_wdef !word 640
shp_hdef !word 480

!ifndef SHP_PSET  { SHP_PSET  = gfx2_pset }
!ifndef SHP_READ  { SHP_READ  = gfx2_read }
!ifndef SHP_HLINE { SHP_HLINE = gfx2_hline }
!ifndef SHP_W     { SHP_W     = shp_wdef }
!ifndef SHP_H     { SHP_H     = shp_hdef }

} ; !zone
