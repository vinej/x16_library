;ACME
; =====================================================================
; x16lib example :: curves.asm
; =====================================================================
; A gallery of the curve shapes, in three bands:
;   - rounded rectangles (shape_frrect filled, shape_rrect outline, and
;     a stadium where the radius reaches half the height),
;   - arcs and a pie (shape_arc concentric "rainbow", plus a shape_pie
;     Pac-Man with its rim outlined by shape_arc),
;   - cubic Beziers (shape_bezier, data-driven from a small table).
;
; The shapes bind to the 2bpp bitmap engine by default (gfx2, 640x480,
; four colours), so this also shows gfx2_init / gfx2_clear and a custom
; four-entry palette.
;
;   .\build_acme.ps1 -Source examples\curves.asm -Run
;
; Press any key to return to text mode.
;
; Runs windowed: it waits on the keyboard, which needs the KERNAL's
; interrupt, so it would hang under the headless -testbench.
; =====================================================================

!cpu 65c02
!source "x16.asm"

X16_USE_SHAPES_RRECT  = 1       ; rounded rectangles (self-contained)
X16_USE_SHAPES_ARC    = 1       ; arcs (pulls MATH + SHP_LINE)
X16_USE_SHAPES_PIE    = 1       ; filled pies (pulls SHAPES_ARC)
X16_USE_SHAPES_BEZIER = 1       ; cubic Beziers (pulls SHP_LINE)
X16_USE_PALETTE       = 1       ; recolour the four-entry palette
X16_USE_SCREEN        = 1       ; restore text mode on the way out
X16_USE_INPUT         = 1       ; wait for a key

BG   = 0                        ; palette slots (see set_palette)
INK  = 1                        ; outlines
FILL = 2                        ; bodies
ACC  = 3                        ; accents

* = $0801
    +basic_stub

; ---------------------------------------------------------------------
main
    jsr gfx2_init               ; 640x480 @ 2bpp on layer 0
    lda #BG
    jsr gfx2_clear
    jsr set_palette

    jsr draw_rrects
    jsr draw_arcs
    jsr draw_beziers

    +vera_addrsel 0             ; hand VERA back to the KERNAL cleanly
    jsr key_wait                ; hold the picture

    lda #$00                    ; back to 80x60 text
    jmp screen_set_mode

; --- rounded rectangles ----------------------------------------------
draw_rrects
    lda #40                     ; a filled rrect: (40,40) 200x110, r=28
    sta rr_x
    stz rr_x+1
    lda #40
    sta rr_y
    stz rr_y+1
    lda #200
    sta rr_w
    stz rr_w+1
    lda #110
    sta rr_h
    stz rr_h+1
    lda #28
    sta rr_r
    lda #FILL
    jsr shape_frrect
    lda #INK                    ; the same rect, outlined on top
    jsr shape_rrect

    lda #<290                   ; a stadium: r = h/2 rounds the ends fully
    sta rr_x
    lda #>290
    sta rr_x+1
    lda #40
    sta rr_y
    stz rr_y+1
    lda #<230
    sta rr_w
    lda #>230
    sta rr_w+1
    lda #110
    sta rr_h
    stz rr_h+1
    lda #55
    sta rr_r
    lda #ACC
    jsr shape_rrect
    rts

; --- arcs and a pie --------------------------------------------------
draw_arcs
    lda #70                     ; three concentric top-half arcs, a rainbow
    ldy #INK
    jsr arc_rain
    lda #55
    ldy #ACC
    jsr arc_rain
    lda #40
    ldy #FILL
    jsr arc_rain

    lda #<470                   ; a Pac-Man pie at (470,300), r=75,
    sta X16_P0                  ; filled from angle 32 round to 224, so the
    lda #>470                   ; 90-degree mouth opens east
    sta X16_P1
    lda #<300
    sta X16_P2
    lda #>300
    sta X16_P3
    lda #75
    sta X16_P4
    lda #32
    sta X16_P5
    lda #224
    sta X16_P6
    lda #FILL
    jsr shape_pie
    lda #<470                   ; outline the pie's rim (arc clobbers P)
    sta X16_P0
    lda #>470
    sta X16_P1
    lda #<300
    sta X16_P2
    lda #>300
    sta X16_P3
    lda #75
    sta X16_P4
    lda #32
    sta X16_P5
    lda #224
    sta X16_P6
    lda #INK
    jsr shape_arc
    rts

; A = radius, Y = colour: a top-half arc (west round to east) at (150,310)
arc_rain
    sta X16_P4
    sty tcol
    lda #150
    sta X16_P0
    stz X16_P1
    lda #<310
    sta X16_P2
    lda #>310
    sta X16_P3
    lda #128                    ; start: west
    sta X16_P5
    lda #0                      ; end: east (increasing -> over the top)
    sta X16_P6
    lda tcol
    jmp shape_arc

; --- cubic Beziers ---------------------------------------------------
; Each btab row is the four control points (x0,y0 .. x3,y3, eight words)
; and a colour byte. The eight words land in bez_x0.. as one contiguous
; block, which is exactly how shape_bezier reads them.
draw_beziers
    stz boff
    stz bcnt
@row
    ldx boff
    ldy #0
@copy
    lda btab,x
    sta bez_x0,y
    inx
    iny
    cpy #16
    bne @copy
    lda btab,x                  ; the colour byte follows the 16 coord bytes
    pha
    inx
    stx boff
    pla
    jsr shape_bezier
    inc bcnt
    lda bcnt
    cmp #NBEZ
    bne @row
    rts

NBEZ = 3
btab
    !word 40,460, 160,380, 300,470, 430,390
    !byte INK                   ; an S-curve
    !word 40,410, 220,470, 400,410, 590,455
    !byte ACC                   ; a shallow wave
    !word 470,465, 615,385, 430,385, 560,465
    !byte FILL                  ; a tight twist

; --- palette ---------------------------------------------------------
; A 0RGB colour for each of the four 2bpp slots.
;   pal_set: X = slot, A = green<<4 | blue, Y = red
set_palette
    ldx #BG
    lda #$FF
    ldy #$0F
    jsr pal_set                 ; 0 = white  $0FFF (paper)
    ldx #INK
    lda #$0F
    ldy #$00
    jsr pal_set                 ; 1 = blue   $000F (outline)
    ldx #FILL
    lda #$F0
    ldy #$00
    jsr pal_set                 ; 2 = green  $00F0 (body)
    ldx #ACC
    lda #$00
    ldy #$0F
    jsr pal_set                 ; 3 = red    $0F00 (accent)
    rts

; --- state -----------------------------------------------------------
tcol !byte 0
boff !byte 0
bcnt !byte 0

; ---------------------------------------------------------------------
!source "x16_code.asm"
