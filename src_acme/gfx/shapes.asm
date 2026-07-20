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

; ---------------------------------------------------------------------
; shp_line -- shared 16-bit Bresenham (X16_USE_SHP_LINE)
; ---------------------------------------------------------------------
; The curve shapes (arc, bezier) sample a handful of points and join
; them; this is the join. It is the same engine-agnostic gfx2_line walk
; the polygon carries privately (.poly_line), lifted out so arc and
; bezier share ONE copy behind their own gate. A program that wants only
; the polygon still pays nothing for this; one that wants an arc pays for
; it once, not once per curve.
;
;   in: shl_x0/shl_y0 -> shl_x1/shl_y1 (signed words), shl_col = colour
;       draws through SHP_PSET, so it clips wherever pset clips.
; ---------------------------------------------------------------------
!ifdef X16_USE_SHP_LINE {

shp_line
	sec                         ; dx = |x1 - x0|, sx = direction
	lda shl_x1
	sbc shl_x0
	sta shl_dx
	lda shl_x1+1
	sbc shl_x0+1
	sta shl_dx+1
	bpl .sl_dxp
	sec
	lda #0
	sbc shl_dx
	sta shl_dx
	lda #0
	sbc shl_dx+1
	sta shl_dx+1
	lda #$FF
	sta shl_sx
	sta shl_sx+1
	bra .sl_dxd
.sl_dxp
	lda #1
	sta shl_sx
	stz shl_sx+1
.sl_dxd
	sec                         ; dy = -|y1 - y0|, sy = direction
	lda shl_y1
	sbc shl_y0
	sta shl_t
	lda shl_y1+1
	sbc shl_y0+1
	sta shl_t+1
	bpl .sl_dyp
	sec
	lda #0
	sbc shl_t
	sta shl_t
	lda #0
	sbc shl_t+1
	sta shl_t+1
	lda #$FF
	sta shl_sy
	sta shl_sy+1
	bra .sl_dyd
.sl_dyp
	lda #1
	sta shl_sy
	stz shl_sy+1
.sl_dyd
	sec                         ; dy stored negative
	lda #0
	sbc shl_t
	sta shl_dy
	lda #0
	sbc shl_t+1
	sta shl_dy+1
	clc                         ; err = dx + dy
	lda shl_dx
	adc shl_dy
	sta shl_err
	lda shl_dx+1
	adc shl_dy+1
	sta shl_err+1
.sl_loop
	lda shl_x0
	sta X16_P0
	lda shl_x0+1
	sta X16_P1
	lda shl_y0
	sta X16_P2
	lda shl_y0+1
	sta X16_P3
	lda shl_col
	jsr SHP_PSET
	lda shl_x0                  ; reached the endpoint?
	cmp shl_x1
	bne .sl_step
	lda shl_x0+1
	cmp shl_x1+1
	bne .sl_step
	lda shl_y0
	cmp shl_y1
	bne .sl_step
	lda shl_y0+1
	cmp shl_y1+1
	bne .sl_step
	rts
.sl_step
	lda shl_err                 ; e2 = 2 * err
	asl
	sta shl_e2
	lda shl_err+1
	rol
	sta shl_e2+1
	sec                         ; e2 >= dy ?  err += dy, x0 += sx
	lda shl_e2
	sbc shl_dy
	lda shl_e2+1
	sbc shl_dy+1
	bvc .sl_nv1
	eor #$80
.sl_nv1
	bmi .sl_skx
	clc
	lda shl_err
	adc shl_dy
	sta shl_err
	lda shl_err+1
	adc shl_dy+1
	sta shl_err+1
	clc
	lda shl_x0
	adc shl_sx
	sta shl_x0
	lda shl_x0+1
	adc shl_sx+1
	sta shl_x0+1
.sl_skx
	sec                         ; e2 <= dx ?  err += dx, y0 += sy
	lda shl_dx
	sbc shl_e2
	lda shl_dx+1
	sbc shl_e2+1
	bvc .sl_nv2
	eor #$80
.sl_nv2
	bmi .sl_sky
	clc
	lda shl_err
	adc shl_dx
	sta shl_err
	lda shl_err+1
	adc shl_dx+1
	sta shl_err+1
	clc
	lda shl_y0
	adc shl_sy
	sta shl_y0
	lda shl_y0+1
	adc shl_sy+1
	sta shl_y0+1
.sl_sky
	jmp .sl_loop

shl_x0  !word 0
shl_y0  !word 0
shl_x1  !word 0
shl_y1  !word 0
shl_col !byte 0
shl_dx  !word 0
shl_dy  !word 0
shl_sx  !word 0
shl_sy  !word 0
shl_err !word 0
shl_e2  !word 0
shl_t   !word 0

} ; X16_USE_SHP_LINE

; ---------------------------------------------------------------------
; shape_rrect / shape_frrect -- rounded rectangle (X16_USE_SHAPES_RRECT)
; ---------------------------------------------------------------------
; A rectangle with quarter-circle corners. Self-contained: the corners
; come from a midpoint circle walk (no trig, no MATH dependency), the
; straight runs from SHP_HLINE / SHP_PSET.
;
;   in: rr_x/rr_y = top-left corner (signed words),
;       rr_w/rr_h = width / height (words, >= 1),
;       rr_r      = corner radius (0-255, clamped to min(w,h)/2),
;       A         = colour
;
; shape_rrect draws the outline through SHP_PSET (so it clips like
; shape_circle); shape_frrect fills it with SHP_HLINE spans (so it does
; NOT clip -- keep it on screen, like shape_disc). r = 0 degenerates to
; a plain rectangle.
;
; The fill precomputes rr_ext[d] = the corner's horizontal half-extent at
; vertical offset d (0..r) once, then draws one span per row: full width
; in the straight middle band, inset by rr_ext[d] through the rounded
; top and bottom bands.
; ---------------------------------------------------------------------
!ifdef X16_USE_SHAPES_RRECT {

shape_rrect
	sta rr_col
	stz rr_fl
	jmp .rr_begin
shape_frrect
	sta rr_col
	lda #1
	sta rr_fl
.rr_begin
	lda rr_x                    ; corner reference points:
	sta rr_x0                   ;   x0 = x, x1 = x + w - 1
	lda rr_x+1
	sta rr_x0+1
	clc
	lda rr_x
	adc rr_w
	sta rr_x1
	lda rr_x+1
	adc rr_w+1
	sta rr_x1+1
	lda rr_x1                   ; x1 -= 1
	bne +
	dec rr_x1+1
+	dec rr_x1
	lda rr_y                    ;   y0 = y, y1 = y + h - 1
	sta rr_y0
	lda rr_y+1
	sta rr_y0+1
	clc
	lda rr_y
	adc rr_h
	sta rr_y1
	lda rr_y+1
	adc rr_h+1
	sta rr_y1+1
	lda rr_y1                   ; y1 -= 1
	bne +
	dec rr_y1+1
+	dec rr_y1

	jsr .rr_clampr              ; rr_r = min(rr_r, min(w,h)/2)
	lda rr_x0                   ; corner centres:
	clc                         ;   cxl = x0 + r, cxr = x1 - r
	adc rr_r
	sta rr_cxl
	lda rr_x0+1
	adc #0
	sta rr_cxl+1
	sec
	lda rr_x1
	sbc rr_r
	sta rr_cxr
	lda rr_x1+1
	sbc #0
	sta rr_cxr+1
	lda rr_y0                   ;   cyt = y0 + r, cyb = y1 - r
	clc
	adc rr_r
	sta rr_cyt
	lda rr_y0+1
	adc #0
	sta rr_cyt+1
	sec
	lda rr_y1
	sbc rr_r
	sta rr_cyb
	lda rr_y1+1
	sbc #0
	sta rr_cyb+1

	lda rr_fl
	beq .rr_out
	jmp .rr_fill
.rr_out
	jmp .rr_outline

; rr_r = min(rr_r, min(rr_w, rr_h) / 2)
.rr_clampr
	lda rr_w                    ; m = min(w, h)  (16-bit unsigned)
	sta rr_m
	lda rr_w+1
	sta rr_m+1
	lda rr_h+1
	cmp rr_m+1
	bcc .rr_cmh
	bne .rr_cmok
	lda rr_h
	cmp rr_m
	bcs .rr_cmok
.rr_cmh
	lda rr_h
	sta rr_m
	lda rr_h+1
	sta rr_m+1
.rr_cmok
	lsr rr_m+1                  ; m /= 2
	ror rr_m
	lda rr_m+1                  ; m >= 256 ? radius already fits any byte
	bne .rr_crok
	lda rr_r                    ; r > m ? clamp to m
	cmp rr_m
	bcc .rr_crok
	lda rr_m
	sta rr_r
.rr_crok
	rts

; --- outline ---------------------------------------------------------
.rr_outline
	jsr .rr_corners             ; the four quarter-circle corners
	; top edge: (cxl, y0) .. (cxr, y0)
	lda rr_cxl
	sta X16_P0
	lda rr_cxl+1
	sta X16_P1
	lda rr_y0
	sta X16_P2
	lda rr_y0+1
	sta X16_P3
	jsr .rr_hspan               ; pset run from P0 to cxr on row P2/P3
	; bottom edge: (cxl, y1) .. (cxr, y1)
	lda rr_cxl
	sta X16_P0
	lda rr_cxl+1
	sta X16_P1
	lda rr_y1
	sta X16_P2
	lda rr_y1+1
	sta X16_P3
	jsr .rr_hspan
	; left edge: column x0, rows cyt..cyb
	lda rr_x0
	sta X16_P0
	lda rr_x0+1
	sta X16_P1
	jsr .rr_vspan
	; right edge: column x1, rows cyt..cyb
	lda rr_x1
	sta X16_P0
	lda rr_x1+1
	sta X16_P1
	jsr .rr_vspan
	rts

; pset a horizontal run from (P0/P1) to x=rr_cxr on the row in P2/P3
.rr_hspan
	sec                         ; empty run when cxr < cxl (r reaches w/2):
	lda rr_cxr                  ; the rounded ends meet, no straight top/bottom
	sbc rr_cxl
	lda rr_cxr+1
	sbc rr_cxl+1
	bvc +
	eor #$80
+	bmi .rr_hsd
	lda X16_P2                  ; hold the row (pset reloads P0..P3)
	sta rr_ry
	lda X16_P3
	sta rr_ry+1
.rr_hsl
	lda rr_ry
	sta X16_P2
	lda rr_ry+1
	sta X16_P3
	lda rr_col
	jsr SHP_PSET
	lda X16_P0                  ; at cxr ?
	cmp rr_cxr
	bne .rr_hsn
	lda X16_P1
	cmp rr_cxr+1
	beq .rr_hsd
.rr_hsn
	inc X16_P0
	bne .rr_hsl
	inc X16_P1
	bra .rr_hsl
.rr_hsd
	rts

; pset a vertical run on column (P0/P1) from y=rr_cyt to y=rr_cyb
.rr_vspan
	sec                         ; empty run when cyb < cyt (r reaches h/2):
	lda rr_cyb                  ; the rounded ends meet, no straight sides
	sbc rr_cyt
	lda rr_cyb+1
	sbc rr_cyt+1
	bvc +
	eor #$80
+	bmi .rr_vsd
	lda X16_P0
	sta rr_rx
	lda X16_P1
	sta rr_rx+1
	lda rr_cyt
	sta X16_P2
	lda rr_cyt+1
	sta X16_P3
.rr_vsl
	lda rr_rx
	sta X16_P0
	lda rr_rx+1
	sta X16_P1
	lda rr_col
	jsr SHP_PSET
	lda X16_P2                  ; at cyb ?
	cmp rr_cyb
	bne .rr_vsn
	lda X16_P3
	cmp rr_cyb+1
	beq .rr_vsd
.rr_vsn
	inc X16_P2
	bne .rr_vsl
	inc X16_P3
	bra .rr_vsl
.rr_vsd
	rts

; walk the quarter circle once; each octant point plots at all 4 corners
.rr_corners
	lda rr_r                    ; x = r, y = 0, err = 1 - r
	sta rr_wx
	stz rr_wy
	sec
	lda #1
	sbc rr_r
	sta rr_werr
	lda #0
	sbc #0
	sta rr_werr+1
.rr_cwl
	lda rr_wy                   ; while y <= x
	cmp rr_wx
	beq .rr_cwp
	bcs .rr_cwd
.rr_cwp
	lda rr_wx                   ; plot (a,b) = (x,y) and (y,x) at 4 corners
	sta rr_ca
	lda rr_wy
	sta rr_cb
	jsr .rr_c4
	lda rr_wy
	sta rr_ca
	lda rr_wx
	sta rr_cb
	jsr .rr_c4
	jsr .rr_wstep
	bra .rr_cwl
.rr_cwd
	rts

; plot (a,b) offsets at the four corner centres
.rr_c4
	sec                         ; TL: (cxl - a, cyt - b)
	lda rr_cxl
	sbc rr_ca
	sta X16_P0
	lda rr_cxl+1
	sbc #0
	sta X16_P1
	sec
	lda rr_cyt
	sbc rr_cb
	sta X16_P2
	lda rr_cyt+1
	sbc #0
	sta X16_P3
	lda rr_col
	jsr SHP_PSET
	clc                         ; TR: (cxr + a, cyt - b)
	lda rr_cxr
	adc rr_ca
	sta X16_P0
	lda rr_cxr+1
	adc #0
	sta X16_P1
	sec
	lda rr_cyt
	sbc rr_cb
	sta X16_P2
	lda rr_cyt+1
	sbc #0
	sta X16_P3
	lda rr_col
	jsr SHP_PSET
	sec                         ; BL: (cxl - a, cyb + b)
	lda rr_cxl
	sbc rr_ca
	sta X16_P0
	lda rr_cxl+1
	sbc #0
	sta X16_P1
	clc
	lda rr_cyb
	adc rr_cb
	sta X16_P2
	lda rr_cyb+1
	adc #0
	sta X16_P3
	lda rr_col
	jsr SHP_PSET
	clc                         ; BR: (cxr + a, cyb + b)
	lda rr_cxr
	adc rr_ca
	sta X16_P0
	lda rr_cxr+1
	adc #0
	sta X16_P1
	clc
	lda rr_cyb
	adc rr_cb
	sta X16_P2
	lda rr_cyb+1
	adc #0
	sta X16_P3
	lda rr_col
	jmp SHP_PSET

; midpoint error walk shared by .rr_corners and the fill's table build
.rr_wstep
	inc rr_wy
	bit rr_werr+1
	bmi .rr_wgrow
	dec rr_wx
	sec                         ; t = y - x
	lda rr_wy
	sbc rr_wx
	sta rr_wt
	lda #0
	sbc #0
	sta rr_wt+1
	bra .rr_wap
.rr_wgrow
	lda rr_wy                   ; t = y
	sta rr_wt
	lda #0
	sta rr_wt+1
.rr_wap
	asl rr_wt                   ; err += 2t + 1
	rol rr_wt+1
	inc rr_wt
	bne +
	inc rr_wt+1
+	clc
	lda rr_werr
	adc rr_wt
	sta rr_werr
	lda rr_werr+1
	adc rr_wt+1
	sta rr_werr+1
	rts

; --- fill ------------------------------------------------------------
.rr_fill
	jsr .rr_build               ; rr_ext[0..r] = corner half-extents
	lda rr_y0                   ; row = y0
	sta rr_ry
	lda rr_y0+1
	sta rr_ry+1
.rr_fl
	lda rr_y1                   ; row > y1 ? done
	cmp rr_ry
	lda rr_y1+1
	sbc rr_ry+1
	bvc +
	eor #$80
+	bmi .rr_fld
	jsr .rr_row
	inc rr_ry
	bne .rr_fl
	inc rr_ry+1
	bra .rr_fl
.rr_fld
	rts

; draw the one span for row rr_ry: full width in the middle band, inset
; by rr_ext[d] in the rounded top/bottom bands
.rr_row
	lda rr_ry                   ; row < cyt ?  top rounded band, d = cyt-row
	cmp rr_cyt
	lda rr_ry+1
	sbc rr_cyt+1
	bvc +
	eor #$80
+	bmi .rr_rtop
	lda rr_cyb                  ; row > cyb ?  bottom band, d = row-cyb
	cmp rr_ry
	lda rr_cyb+1
	sbc rr_ry+1
	bvc +
	eor #$80
+	bmi .rr_rbot
	ldx #0                      ; middle band: d = 0, ext[0] = r -> full width
	beq .rr_inset               ; (always: ldx #0 set Z)
.rr_rtop
	sec                         ; d = cyt - row (1..r)
	lda rr_cyt
	sbc rr_ry
	tax
	bra .rr_inset
.rr_rbot
	sec                         ; d = row - cyb (1..r)
	lda rr_ry
	sbc rr_cyb
	tax
.rr_inset
	lda rr_ext,x                ; ins = rr_ext[d]
	sta rr_ins
	stz rr_ins+1
	sec                         ; P0 = left = cxl - ins
	lda rr_cxl
	sbc rr_ins
	sta X16_P0
	lda rr_cxl+1
	sbc #0
	sta X16_P1
	lda rr_ry                   ; row
	sta X16_P2
	lda rr_ry+1
	sta X16_P3
	clc                         ; right = cxr + ins  -> T0
	lda rr_cxr
	adc rr_ins
	sta X16_T0
	lda rr_cxr+1
	adc rr_ins+1
	sta X16_T0+1
	sec                         ; len = right - left + 1
	lda X16_T0
	sbc X16_P0
	sta X16_P4
	lda X16_T0+1
	sbc X16_P1
	sta X16_P5
	inc X16_P4
	bne +
	inc X16_P5
+	lda rr_col
	jmp SHP_HLINE

; rr_ext[d] = corner half-extent at vertical offset d, for d = 0..r
.rr_build
	ldx #0                      ; zero rr_ext[0..255]
	lda #0
.rr_bz
	sta rr_ext,x
	inx
	bne .rr_bz
	lda rr_r                    ; ext[0] = r
	sta rr_ext
	lda rr_r                    ; walk the quarter circle
	sta rr_wx
	stz rr_wy
	sec
	lda #1
	sbc rr_r
	sta rr_werr
	lda #0
	sbc #0
	sta rr_werr+1
.rr_bwl
	lda rr_wy                   ; while y <= x
	cmp rr_wx
	beq .rr_bwp
	bcs .rr_bwd
.rr_bwp
	ldx rr_wy                   ; ext[y] = max(ext[y], x)
	lda rr_wx
	cmp rr_ext,x
	bcc +
	sta rr_ext,x
+	ldx rr_wx                   ; ext[x] = max(ext[x], y)
	lda rr_wy
	cmp rr_ext,x
	bcc +
	sta rr_ext,x
+	jsr .rr_wstep
	bra .rr_bwl
.rr_bwd
	rts

; --- rounded-rect state ----------------------------------------------
rr_x    !word 0
rr_y    !word 0
rr_w    !word 0
rr_h    !word 0
rr_r    !byte 0
rr_col  !byte 0
rr_fl   !byte 0
rr_x0   !word 0
rr_y0   !word 0
rr_x1   !word 0
rr_y1   !word 0
rr_cxl  !word 0
rr_cxr  !word 0
rr_cyt  !word 0
rr_cyb  !word 0
rr_m    !word 0
rr_ry   !word 0
rr_rx   !word 0
rr_ins  !word 0
rr_ca   !byte 0
rr_cb   !byte 0
rr_wx   !byte 0
rr_wy   !byte 0
rr_werr !word 0
rr_wt   !word 0
rr_ext  !fill 256, 0

} ; X16_USE_SHAPES_RRECT

; ---------------------------------------------------------------------
; shape_arc -- a portion of a circle outline (X16_USE_SHAPES_ARC)
; ---------------------------------------------------------------------
; The arc runs from byte-angle `start` to `end`, increasing (0 = east,
; 64 = south, 128 = west, 192 = north -- the sin8/cos8, screen-y-down
; convention shared with the polygon). It is sampled every ~4 byte-angle
; units and the samples are joined with shp_line, so the chord error is
; under a third of a pixel even at r = 255 and the arc clips wherever
; SHP_PSET clips. When start == end the whole circle is drawn.
;
;   in: P0/P1 = cx, P2/P3 = cy, P4 = r (0-255),
;       P5 = start angle, P6 = end angle, A = colour
;
; .arc_point / .arc_scale place a sample the same way the polygon places
; a vertex (r * cos8/sin8 / 128, rounded); shape_pie reuses them, which
; is why they live in this gate and PIE depends on ARC.
; ---------------------------------------------------------------------
!ifdef X16_USE_SHAPES_ARC {

ARC_STEP = 4                    ; byte-angle units between samples

shape_arc
	sta shl_col                 ; shp_line draws in this colour
	lda X16_P0
	sta arc_cx
	lda X16_P1
	sta arc_cx+1
	lda X16_P2
	sta arc_cy
	lda X16_P3
	sta arc_cy+1
	lda X16_P4
	sta arc_r
	lda X16_P5
	sta arc_a0
	sec                         ; span = (end - start) & 255; 0 -> 256
	lda X16_P6
	sbc arc_a0
	sta arc_span
	stz arc_span+1
	lda arc_span
	bne .ar_have
	inc arc_span+1
.ar_have
	lda arc_a0                  ; first sample -> shl_x0/y0 (prev point)
	jsr .arc_point
	lda arc_px
	sta shl_x0
	lda arc_px+1
	sta shl_x0+1
	lda arc_py
	sta shl_y0
	lda arc_py+1
	sta shl_y0+1
	lda arc_a0
	sta arc_ang
.ar_loop
	lda arc_span+1              ; step = min(ARC_STEP, span)
	bne .ar_full
	lda arc_span
	cmp #ARC_STEP
	bcc .ar_last
.ar_full
	lda #ARC_STEP
	sta arc_step
	bra .ar_adv
.ar_last
	lda arc_span
	sta arc_step
.ar_adv
	clc                         ; ang = (ang + step) mod 256
	lda arc_ang
	adc arc_step
	sta arc_ang
	sec                         ; span -= step
	lda arc_span
	sbc arc_step
	sta arc_span
	lda arc_span+1
	sbc #0
	sta arc_span+1
	lda arc_ang                 ; this sample -> shl_x1/y1
	jsr .arc_point
	lda arc_px
	sta shl_x1
	lda arc_px+1
	sta shl_x1+1
	lda arc_py
	sta shl_y1
	lda arc_py+1
	sta shl_y1+1
	jsr shp_line
	lda shl_x1                  ; cur -> prev for the next segment
	sta shl_x0
	lda shl_x1+1
	sta shl_x0+1
	lda shl_y1
	sta shl_y0
	lda shl_y1+1
	sta shl_y0+1
	lda arc_span                ; span exhausted ? done
	ora arc_span+1
	bne .ar_loop
	rts

; sample at byte-angle A -> (arc_px, arc_py)
.arc_point
	pha
	jsr cos8                    ; A = cos * 127 (signed)
	jsr .arc_scale              ; arc_off = round(r * A / 128)
	clc
	lda arc_cx
	adc arc_off
	sta arc_px
	lda arc_cx+1
	adc arc_off+1
	sta arc_px+1
	pla
	jsr sin8                    ; A = sin * 127 (signed)
	jsr .arc_scale
	clc
	lda arc_cy
	adc arc_off
	sta arc_py
	lda arc_cy+1
	adc arc_off+1
	sta arc_py+1
	rts

; arc_off = round(arc_r * |A| / 128) with A's sign (A a signed byte)
.arc_scale
	stz arc_sgn
	pha
	and #$80
	beq .as_pos
	inc arc_sgn
	pla
	eor #$FF
	clc
	adc #1
	bra .as_mul
.as_pos
	pla
.as_mul
	jsr .arc_mul8               ; arc_p16 = arc_r * |A|
	clc
	lda arc_p16                 ; + 0.5 LSB so >>7 rounds
	adc #64
	sta arc_p16
	lda arc_p16+1
	adc #0
	sta arc_p16+1
	lda arc_p16                 ; >>7 (product < 32768, one byte out)
	asl
	lda arc_p16+1
	rol
	sta arc_off
	stz arc_off+1
	lda arc_sgn
	beq .as_done
	sec                         ; negate
	lda #0
	sbc arc_off
	sta arc_off
	lda #0
	sbc arc_off+1
	sta arc_off+1
.as_done
	rts

; arc_p16 = arc_r * A  (8x8 -> 16, unsigned)
.arc_mul8
	sta arc_t
	lda #0
	ldx #8
.am_loop
	lsr arc_t
	bcc .am_skip
	clc
	adc arc_r
.am_skip
	ror
	ror arc_p16
	dex
	bne .am_loop
	sta arc_p16+1
	rts

; --- arc state (shared with shape_pie) -------------------------------
arc_cx   !word 0
arc_cy   !word 0
arc_r    !byte 0
arc_a0   !byte 0
arc_ang  !byte 0
arc_step !byte 0
arc_span !word 0
arc_px   !word 0
arc_py   !word 0
arc_off  !word 0
arc_sgn  !byte 0
arc_p16  !word 0
arc_t    !byte 0

} ; X16_USE_SHAPES_ARC

; ---------------------------------------------------------------------
; shape_pie -- a filled wedge from the centre to the arc (X16_USE_SHAPES_PIE)
; ---------------------------------------------------------------------
; Same arguments and angle convention as shape_arc; the region swept
; between the two radii and the arc is filled. It is built as a fan of
; thin triangles (centre, sample_i, sample_i+1) so ANY span works,
; including the reflex (> 180-degree) case a single convex scan cannot
; do; start == end fills the whole disc. The triangles share their radial
; edges, so like shape_disc it draws with SHP_HLINE (no clipping) and its
; overdraw on the shared edges is harmless. It reuses ARC's .arc_point.
;
;   in: P0/P1 = cx, P2/P3 = cy, P4 = r (0-255),
;       P5 = start angle, P6 = end angle, A = colour
; ---------------------------------------------------------------------
!ifdef X16_USE_SHAPES_PIE {

shape_pie
	sta pie_col
	lda X16_P0
	sta arc_cx
	lda X16_P1
	sta arc_cx+1
	lda X16_P2
	sta arc_cy
	lda X16_P3
	sta arc_cy+1
	lda X16_P4
	sta arc_r
	lda X16_P5
	sta arc_a0
	sec                         ; span = (end - start) & 255; 0 -> 256
	lda X16_P6
	sbc arc_a0
	sta arc_span
	stz arc_span+1
	lda arc_span
	bne .pie_have
	inc arc_span+1
.pie_have
	lda arc_a0                  ; prev = sample(start)
	jsr .arc_point
	lda arc_px
	sta pie_prevx
	lda arc_px+1
	sta pie_prevx+1
	lda arc_py
	sta pie_prevy
	lda arc_py+1
	sta pie_prevy+1
	lda arc_a0
	sta arc_ang
.pie_loop
	lda arc_span+1              ; step = min(ARC_STEP, span)
	bne .pie_full
	lda arc_span
	cmp #ARC_STEP
	bcc .pie_last
.pie_full
	lda #ARC_STEP
	sta arc_step
	bra .pie_adv
.pie_last
	lda arc_span
	sta arc_step
.pie_adv
	clc
	lda arc_ang
	adc arc_step
	sta arc_ang
	sec
	lda arc_span
	sbc arc_step
	sta arc_span
	lda arc_span+1
	sbc #0
	sta arc_span+1
	lda arc_ang                 ; cur = sample(ang)
	jsr .arc_point
	lda arc_cx                  ; triangle A = centre
	sta tf_ax
	lda arc_cx+1
	sta tf_ax+1
	lda arc_cy
	sta tf_ay
	lda arc_cy+1
	sta tf_ay+1
	lda pie_prevx               ; B = prev sample
	sta tf_bx
	lda pie_prevx+1
	sta tf_bx+1
	lda pie_prevy
	sta tf_by
	lda pie_prevy+1
	sta tf_by+1
	lda arc_px                  ; C = cur sample
	sta tf_cx
	lda arc_px+1
	sta tf_cx+1
	lda arc_py
	sta tf_cy
	lda arc_py+1
	sta tf_cy+1
	jsr .tf_fill
	lda arc_px                  ; prev = cur
	sta pie_prevx
	lda arc_px+1
	sta pie_prevx+1
	lda arc_py
	sta pie_prevy
	lda arc_py+1
	sta pie_prevy+1
	lda arc_span                ; span exhausted ? done
	ora arc_span+1
	beq .pie_done
	jmp .pie_loop
.pie_done
	rts

; --- triangle scanline fill (fan primitive) --------------------------
; Fills triangle (tf_ax/ay, tf_bx/by, tf_cx/cy) in pie_col with SHP_HLINE
; spans. Sorts the vertices by y, then walks the long edge and the two
; short edges by scanline with a division-free DDA (err += |dx|; while
; err >= dy: x += sign, err -= dy). A zero-height triangle has no area
; and is skipped. Edge state is two-wide: index 0 = long, 2 = short.
.tf_fill
	jsr .tf_sort                ; ay <= by <= cy
	lda tf_ay                   ; ay == cy ? zero height, nothing to fill
	cmp tf_cy
	bne .tf_go
	lda tf_ay+1
	cmp tf_cy+1
	bne .tf_go
	rts
.tf_go
	lda tf_ax                   ; long edge a -> c  (index 0)
	sta tf_isx
	lda tf_ax+1
	sta tf_isx+1
	lda tf_ay
	sta tf_isy
	lda tf_ay+1
	sta tf_isy+1
	lda tf_cx
	sta tf_iex
	lda tf_cx+1
	sta tf_iex+1
	lda tf_cy
	sta tf_iey
	lda tf_cy+1
	sta tf_iey+1
	ldx #0
	jsr .tf_init
	lda tf_ay                   ; y = ay
	sta tf_y
	lda tf_ay+1
	sta tf_y+1
	sec                         ; phase 1 only if ay < by
	lda tf_ay
	sbc tf_by
	lda tf_ay+1
	sbc tf_by+1
	bvc +
	eor #$80
+	bpl .tf_p2init              ; ay >= by (flat top): skip to phase 2
	lda tf_ax                   ; short edge a -> b  (index 2)
	sta tf_isx
	lda tf_ax+1
	sta tf_isx+1
	lda tf_ay
	sta tf_isy
	lda tf_ay+1
	sta tf_isy+1
	lda tf_bx
	sta tf_iex
	lda tf_bx+1
	sta tf_iex+1
	lda tf_by
	sta tf_iey
	lda tf_by+1
	sta tf_iey+1
	ldx #2
	jsr .tf_init
.tf_p1loop
	sec                         ; y >= by ? phase 1 done
	lda tf_y
	sbc tf_by
	lda tf_y+1
	sbc tf_by+1
	bvc +
	eor #$80
+	bmi .tf_p1do
	jmp .tf_p2init
.tf_p1do
	jsr .tf_emitrow
	ldx #0
	jsr .tf_adv
	ldx #2
	jsr .tf_adv
	inc tf_y
	bne +
	inc tf_y+1
+	jmp .tf_p1loop
.tf_p2init
	lda tf_bx                   ; short edge b -> c  (index 2)
	sta tf_isx
	lda tf_bx+1
	sta tf_isx+1
	lda tf_by
	sta tf_isy
	lda tf_by+1
	sta tf_isy+1
	lda tf_cx
	sta tf_iex
	lda tf_cx+1
	sta tf_iex+1
	lda tf_cy
	sta tf_iey
	lda tf_cy+1
	sta tf_iey+1
	ldx #2
	jsr .tf_init
.tf_p2loop
	jsr .tf_emitrow
	lda tf_y                    ; y == cy ? done (last row)
	cmp tf_cy
	bne .tf_p2do
	lda tf_y+1
	cmp tf_cy+1
	bne .tf_p2do
	rts
.tf_p2do
	ldx #0
	jsr .tf_adv
	ldx #2
	jsr .tf_adv
	inc tf_y
	bne +
	inc tf_y+1
+	jmp .tf_p2loop

; sort tf_a/tf_b/tf_c by y ascending (each slot is x.w then y.w)
.tf_sort
	jsr .tf_cmp_ab
	bpl +
	jsr .tf_swap_ab
+	jsr .tf_cmp_bc
	bpl +
	jsr .tf_swap_bc
+	jsr .tf_cmp_ab
	bpl +
	jsr .tf_swap_ab
+	rts
.tf_cmp_ab                      ; N reflects sign(by - ay); bmi -> ay > by
	sec
	lda tf_by
	sbc tf_ay
	lda tf_by+1
	sbc tf_ay+1
	bvc +
	eor #$80
+	rts
.tf_cmp_bc
	sec
	lda tf_cy
	sbc tf_by
	lda tf_cy+1
	sbc tf_by+1
	bvc +
	eor #$80
+	rts
.tf_swap_ab
	ldx #3
.tsab
	lda tf_ax,x
	ldy tf_bx,x
	sta tf_bx,x
	tya
	sta tf_ax,x
	dex
	bpl .tsab
	rts
.tf_swap_bc
	ldx #3
.tsbc
	lda tf_bx,x
	ldy tf_cx,x
	sta tf_cx,x
	tya
	sta tf_bx,x
	dex
	bpl .tsbc
	rts

; init edge X (0 long / 2 short) from (tf_isx,tf_isy) to (tf_iex,tf_iey)
.tf_init
	lda tf_isx
	sta e_curx,x
	lda tf_isx+1
	sta e_curx+1,x
	sec                         ; dy = iey - isy  (>= 0)
	lda tf_iey
	sbc tf_isy
	sta e_dy,x
	lda tf_iey+1
	sbc tf_isy+1
	sta e_dy+1,x
	sec                         ; dx = iex - isx  (signed)
	lda tf_iex
	sbc tf_isx
	sta tf_edx
	lda tf_iex+1
	sbc tf_isx+1
	sta tf_edx+1
	bpl .ti_pos
	sec                         ; adx = -dx, sx = -1
	lda #0
	sbc tf_edx
	sta e_adx,x
	lda #0
	sbc tf_edx+1
	sta e_adx+1,x
	lda #$FF
	sta e_sx,x
	sta e_sx+1,x
	bra .ti_err
.ti_pos
	lda tf_edx                  ; adx = dx, sx = +1
	sta e_adx,x
	lda tf_edx+1
	sta e_adx+1,x
	lda #1
	sta e_sx,x
	stz e_sx+1,x
.ti_err
	stz e_err,x
	stz e_err+1,x
	rts

; advance edge X by one scanline (dy for this edge must be > 0)
.tf_adv
	clc                         ; err += adx
	lda e_err,x
	adc e_adx,x
	sta e_err,x
	lda e_err+1,x
	adc e_adx+1,x
	sta e_err+1,x
.ta_w
	sec                         ; err >= dy ?
	lda e_err,x
	sbc e_dy,x
	tay
	lda e_err+1,x
	sbc e_dy+1,x
	bcc .ta_done                ; err < dy
	sta e_err+1,x               ; err -= dy
	tya
	sta e_err,x
	clc                         ; x += sx
	lda e_curx,x
	adc e_sx,x
	sta e_curx,x
	lda e_curx+1,x
	adc e_sx+1,x
	sta e_curx+1,x
	bra .ta_w
.ta_done
	rts

; HLINE on row tf_y between the long (index 0) and short (index 2) x's
.tf_emitrow
	sec                         ; diff = short_x - long_x
	lda e_curx+2
	sbc e_curx
	sta tf_tmp
	lda e_curx+3
	sbc e_curx+1
	sta tf_tmp+1
	bpl .te_pos                 ; short >= long: left = long, len = diff+1
	lda e_curx+2                ; short < long: left = short, len = -diff+1
	sta X16_P0
	lda e_curx+3
	sta X16_P1
	sec
	lda #0
	sbc tf_tmp
	sta X16_P4
	lda #0
	sbc tf_tmp+1
	sta X16_P5
	bra .te_len
.te_pos
	lda e_curx
	sta X16_P0
	lda e_curx+1
	sta X16_P1
	lda tf_tmp
	sta X16_P4
	lda tf_tmp+1
	sta X16_P5
.te_len
	inc X16_P4                  ; len = |diff| + 1
	bne +
	inc X16_P5
+	lda tf_y
	sta X16_P2
	lda tf_y+1
	sta X16_P3
	lda pie_col
	jsr SHP_HLINE
	rts

; --- pie / triangle-fill state ---------------------------------------
pie_col   !byte 0
pie_prevx !word 0
pie_prevy !word 0
tf_ax  !word 0
tf_ay  !word 0
tf_bx  !word 0
tf_by  !word 0
tf_cx  !word 0
tf_cy  !word 0
tf_y   !word 0
tf_isx !word 0
tf_isy !word 0
tf_iex !word 0
tf_iey !word 0
tf_edx !word 0
tf_tmp !word 0
e_curx !fill 4, 0
e_err  !fill 4, 0
e_adx  !fill 4, 0
e_dy   !fill 4, 0
e_sx   !fill 4, 0

} ; X16_USE_SHAPES_PIE

; ---------------------------------------------------------------------
; shape_bezier -- cubic Bezier curve (X16_USE_SHAPES_BEZIER)
; ---------------------------------------------------------------------
; The curve through four control points P0 (on the curve), P1, P2
; (handles), P3 (on the curve), by de Casteljau at a handful of t and
; shp_line between the samples. The sample count adapts to the control
; polygon's size (its Manhattan perimeter / 8, clamped to 4..64), so a
; small curve is cheap and a large one stays smooth. Clips wherever
; SHP_PSET clips.
;
;   in: bez_x0/bez_y0 .. bez_x3/bez_y3 = the four control points
;       (signed words, set by the caller), A = colour
;
; t is an 8-bit fraction (0..255); the endpoints P0 and P3 are emitted
; exactly rather than evaluated, so the curve meets its anchors.
; ---------------------------------------------------------------------
!ifdef X16_USE_SHAPES_BEZIER {

shape_bezier
	sta shl_col
	jsr .bz_nseg                ; bez_n = clamp(perimeter/8, 4, 64)
	lda bez_x0                  ; prev = P0 (emitted exactly)
	sta shl_x0
	lda bez_x0+1
	sta shl_x0+1
	lda bez_y0
	sta shl_y0
	lda bez_y0+1
	sta shl_y0+1
	lda #1
	sta bez_i
	stz bez_tb
	stz bez_rem
	stz bez_rem+1
.bz_loop
	lda bez_i                   ; i == n ? last segment goes to P3
	cmp bez_n
	beq .bz_last
	inc bez_rem+1               ; rem += 256; while rem >= n: tb++, rem -= n
.bz_tw
	lda bez_rem+1
	bne .bz_tsub
	lda bez_rem
	cmp bez_n
	bcc .bz_tdone
.bz_tsub
	sec
	lda bez_rem
	sbc bez_n
	sta bez_rem
	lda bez_rem+1
	sbc #0
	sta bez_rem+1
	inc bez_tb
	bra .bz_tw
.bz_tdone
	jsr .bz_eval                ; (bez_rx, bez_ry) = B(tb)
	lda bez_rx
	sta shl_x1
	lda bez_rx+1
	sta shl_x1+1
	lda bez_ry
	sta shl_y1
	lda bez_ry+1
	sta shl_y1+1
	jsr shp_line
	lda shl_x1                  ; cur -> prev
	sta shl_x0
	lda shl_x1+1
	sta shl_x0+1
	lda shl_y1
	sta shl_y0
	lda shl_y1+1
	sta shl_y0+1
	inc bez_i
	jmp .bz_loop
.bz_last
	lda bez_x3                  ; final sample = P3, exact
	sta shl_x1
	lda bez_x3+1
	sta shl_x1+1
	lda bez_y3
	sta shl_y1
	lda bez_y3+1
	sta shl_y1+1
	jmp shp_line

; bez_n = clamp(Manhattan perimeter of the control polygon / 8, 4, 64)
.bz_nseg
	stz bez_per
	stz bez_per+1
	ldx #0                      ; X = 4*k over the three control segments
.bn_loop
	sec                         ; dx = pts[k+1].x - pts[k].x
	lda bez_x0+4,x
	sbc bez_x0,x
	sta bez_tmp
	lda bez_x0+5,x
	sbc bez_x0+1,x
	sta bez_tmp+1
	jsr .bz_absacc
	sec                         ; dy = pts[k+1].y - pts[k].y
	lda bez_x0+6,x
	sbc bez_x0+2,x
	sta bez_tmp
	lda bez_x0+7,x
	sbc bez_x0+3,x
	sta bez_tmp+1
	jsr .bz_absacc
	inx
	inx
	inx
	inx
	cpx #12
	bne .bn_loop
	ldx #3                      ; per >>= 3
.bn_sh
	lsr bez_per+1
	ror bez_per
	dex
	bne .bn_sh
	lda bez_per+1               ; clamp high -> 64
	bne .bn_hi
	lda bez_per
	cmp #64
	bcs .bn_hi
	cmp #4
	bcs .bn_ok                  ; 4..63
	lda #4
.bn_ok
	sta bez_n
	rts
.bn_hi
	lda #64
	sta bez_n
	rts

; bez_per += |bez_tmp|  (signed word magnitude)
.bz_absacc
	lda bez_tmp+1
	bpl .ba_pos
	sec
	lda #0
	sbc bez_tmp
	sta bez_tmp
	lda #0
	sbc bez_tmp+1
	sta bez_tmp+1
.ba_pos
	clc
	lda bez_per
	adc bez_tmp
	sta bez_per
	lda bez_per+1
	adc bez_tmp+1
	sta bez_per+1
	rts

; (bez_rx, bez_ry) = cubic B(bez_tb) by de Casteljau
.bz_eval
	ldx #0                      ; copy control points into the work arrays
	ldy #0
.be_cp
	lda bez_x0,y
	sta bez_wx,x
	lda bez_x0+1,y
	sta bez_wx+1,x
	lda bez_x0+2,y
	sta bez_wy,x
	lda bez_x0+3,y
	sta bez_wy+1,x
	inx
	inx
	tya
	clc
	adc #4
	tay
	cpx #8
	bne .be_cp
	lda #3
	sta bez_cnt
.be_lvl
	lda bez_cnt                 ; inner loop j = 0 .. cnt-1  (index j*2)
	asl
	sta bez_lim
	stz bez_jx
.be_jx
	ldx bez_jx                  ; wx[j] = lerp(wx[j], wx[j+1], t)
	lda bez_wx,x
	sta bez_p
	lda bez_wx+1,x
	sta bez_p+1
	lda bez_wx+2,x
	sta bez_q
	lda bez_wx+3,x
	sta bez_q+1
	jsr .bz_lerp
	ldx bez_jx
	lda bez_r
	sta bez_wx,x
	lda bez_r+1
	sta bez_wx+1,x
	lda bez_wy,x                ; wy[j] = lerp(wy[j], wy[j+1], t)
	sta bez_p
	lda bez_wy+1,x
	sta bez_p+1
	lda bez_wy+2,x
	sta bez_q
	lda bez_wy+3,x
	sta bez_q+1
	jsr .bz_lerp
	ldx bez_jx
	lda bez_r
	sta bez_wy,x
	lda bez_r+1
	sta bez_wy+1,x
	lda bez_jx
	clc
	adc #2
	sta bez_jx
	cmp bez_lim
	bne .be_jx
	dec bez_cnt
	bne .be_lvl
	lda bez_wx                  ; result = work[0]
	sta bez_rx
	lda bez_wx+1
	sta bez_rx+1
	lda bez_wy
	sta bez_ry
	lda bez_wy+1
	sta bez_ry+1
	rts

; bez_r = bez_p + round((bez_q - bez_p) * bez_tb / 256)   (signed)
.bz_lerp
	sec                         ; d = q - p
	lda bez_q
	sbc bez_p
	sta bez_d
	lda bez_q+1
	sbc bez_p+1
	sta bez_d+1
	stz bez_dsgn
	lda bez_d+1                 ; take |d|, remember the sign
	bpl .bl_pos
	inc bez_dsgn
	sec
	lda #0
	sbc bez_d
	sta bez_d
	lda #0
	sbc bez_d+1
	sta bez_d+1
.bl_pos
	jsr .bz_mul                 ; bez_prod = |d| * t (24-bit)
	clc                         ; + 128 (round), then take bytes 1..2 (>>8)
	lda bez_prod
	adc #128
	lda bez_prod+1
	adc #0
	sta bez_m
	lda bez_prod+2
	adc #0
	sta bez_m+1
	lda bez_dsgn
	beq .bl_add
	sec                         ; re-apply the sign
	lda #0
	sbc bez_m
	sta bez_m
	lda #0
	sbc bez_m+1
	sta bez_m+1
.bl_add
	clc                         ; r = p + m
	lda bez_p
	adc bez_m
	sta bez_r
	lda bez_p+1
	adc bez_m+1
	sta bez_r+1
	rts

; bez_prod (24-bit) = bez_d (16-bit) * bez_tb (8-bit), unsigned
.bz_mul
	stz bez_prod
	stz bez_prod+1
	stz bez_prod+2
	lda bez_tb
	sta bez_mt
	ldx #8
.bm_loop
	asl bez_prod
	rol bez_prod+1
	rol bez_prod+2
	asl bez_mt
	bcc .bm_skip
	clc
	lda bez_prod
	adc bez_d
	sta bez_prod
	lda bez_prod+1
	adc bez_d+1
	sta bez_prod+1
	lda bez_prod+2
	adc #0
	sta bez_prod+2
.bm_skip
	dex
	bne .bm_loop
	rts

; --- bezier state ----------------------------------------------------
bez_x0 !word 0
bez_y0 !word 0
bez_x1 !word 0
bez_y1 !word 0
bez_x2 !word 0
bez_y2 !word 0
bez_x3 !word 0
bez_y3 !word 0
bez_n    !byte 0
bez_i    !byte 0
bez_tb   !byte 0
bez_rem  !word 0
bez_per  !word 0
bez_tmp  !word 0
bez_rx   !word 0
bez_ry   !word 0
bez_wx   !fill 8, 0
bez_wy   !fill 8, 0
bez_cnt  !byte 0
bez_lim  !byte 0
bez_jx   !byte 0
bez_p    !word 0
bez_q    !word 0
bez_d    !word 0
bez_dsgn !byte 0
bez_prod !fill 3, 0
bez_mt   !byte 0
bez_m    !word 0
bez_r    !word 0

} ; X16_USE_SHAPES_BEZIER

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
