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
;   shape_flood   in: P0/P1 = x, P2/P3 = y, A = colour. Scanline seed
;                 fill of the region containing (x,y). Bounds-checked
;                 against SHP_W/SHP_H, so it never reads off canvas.
;                 Carry set if the seed stack overflowed -- a very
;                 tortured region may come back incomplete.
; =====================================================================

!zone x16_shapes {

; ---------------------------------------------------------------------
; shape_circle
; ---------------------------------------------------------------------
shape_circle
	sta .col
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
	jsr .pair4
	lda .y                      ; ...and the (y,x) pair
	sta .a
	lda .x
	sta .b
	jsr .pair4
	jsr .step                   ; the midpoint error walk
	bra .cloop
.cdone
	rts

; ---------------------------------------------------------------------
; shape_disc
; ---------------------------------------------------------------------
shape_disc
	sta .col
	jsr .take_cxy
.dloop
	lda .y
	cmp .x
	beq .dspan
	bcs .ddone
.dspan
	lda .x                      ; spans at cy +/- y, half-width x...
	sta .a
	lda .y
	sta .b
	jsr .span2
	lda .y                      ; ...and at cy +/- x, half-width y
	sta .a
	lda .x
	sta .b
	jsr .span2
	jsr .step
	bra .dloop
.ddone
	rts

; --- shared circle/disc machinery -------------------------------------
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
	sec                         ; x = cx - a
	lda .cx
	sbc .a
	sta X16_P0
	lda .cx+1
	sbc #0
	sta X16_P1
.e1y
	lda .sy
	bne .e1ym
	clc
	lda .cy
	adc .b
	sta X16_P2
	lda .cy+1
	adc #0
	sta X16_P3
	bra .e1go
.e1ym
	sec
	lda .cy
	sbc .b
	sta X16_P2
	lda .cy+1
	sbc #0
	sta X16_P3
.e1go
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
	sec                         ; x = cx - a
	lda .cx
	sbc .a
	sta X16_P0
	lda .cx+1
	sbc #0
	sta X16_P1
	lda .sy
	bne .esym
	clc
	lda .cy
	adc .b
	sta X16_P2
	lda .cy+1
	adc #0
	sta X16_P3
	bra .esgo
.esym
	sec
	lda .cy
	sbc .b
	sta X16_P2
	lda .cy+1
	sbc #0
	sta X16_P3
.esgo
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
	jsr .rd_p                   ; the target = the seed's own colour
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
	lda .qy                     ; widen right: xr = rightmost target
	sta .qy                     ; (qy already holds the row)
	lda .xl
	sta .xr
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

.rd_p                           ; read at the CALLER's P block (entry)
	jmp SHP_READ
.rd_q                           ; read at (.qx, .qy)
	lda .qx
	sta X16_P0
	lda .qx+1
	sta X16_P1
	lda .qy
	sta X16_P2
	lda .qy+1
	sta X16_P3
	jmp SHP_READ

.push                           ; (.qx,.qy) onto the stack, or drop + ovf
	lda .sp
	cmp #FLOOD_MAX
	bcc +
	lda #2                      ; remembered; lsr at exit -> carry
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
