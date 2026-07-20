;ACME
; =====================================================================
; x16lib example :: polygons.asm
; =====================================================================
; A gallery of the regular polygons, three rows of three: triangle,
; square, pentagon / hexagon, heptagon, octagon / nonagon, decagon,
; dodecagon. Each is drawn filled (shape_fpolygon) and then outlined on
; top (shape_polygon), so both routines and the shared vertex placement
; are on show at once.
;
; The shapes bind to the 2bpp bitmap engine by default (gfx2, 640x480,
; four colours), so this also shows gfx2_init / gfx2_clear and a custom
; four-entry palette.
;
;   .\build_acme.ps1 -Source examples\polygons.asm -Run
;
; Press any key to return to text mode.
;
; Runs windowed: it waits on the keyboard, which needs the KERNAL's
; interrupt, so it would hang under the headless -testbench.
; =====================================================================

!cpu 65c02
!source "x16.asm"

X16_USE_SHAPES_POLY = 1         ; the polygons (pulls SHAPES, BITMAP2, MATH)
X16_USE_PALETTE     = 1         ; recolour the four-entry palette
X16_USE_SCREEN      = 1         ; restore text mode on the way out
X16_USE_INPUT       = 1         ; wait for a key

POLY_R   = 58                   ; every polygon's radius
POLY_ROT = 192                  ; rotation: the first vertex points north (up)

BG    = 0                       ; palette slots after set_palette below
INK   = 1                       ; outline
FILL  = 2                       ; body

* = $0801
    +basic_stub

; ---------------------------------------------------------------------
main
    jsr gfx2_init               ; 640x480 @ 2bpp on layer 0
    lda #BG
    jsr gfx2_clear              ; a clean background
    jsr set_palette

    stz index
@loop
    jsr load_entry              ; P0/P1 = cx, P2/P3 = cy, P5 = sides
    jsr set_shape
    lda #FILL
    jsr shape_fpolygon          ; the body (consumes the P block)

    jsr load_entry              ; reload -- the fill clobbered P0..P5
    jsr set_shape
    lda #INK
    jsr shape_polygon           ; a crisp outline on top

    inc index
    lda index
    cmp #NPOLY
    bne @loop

    +vera_addrsel 0             ; hand VERA back to the KERNAL cleanly
    jsr key_wait                ; hold the picture

    lda #$00                    ; back to 80x60 text
    jmp screen_set_mode

; --- helpers ---------------------------------------------------------

; P4 = radius, P6 = rotation (the two constant fields)
set_shape
    lda #POLY_R
    sta X16_P4
    lda #POLY_ROT
    sta X16_P6
    rts

; load ptab[index] -> P0/P1 = cx, P2/P3 = cy, P5 = sides
load_entry
    lda index                   ; entry stride is 5 bytes (cx.w cy.w sides.b)
    asl
    asl                         ; index * 4
    clc
    adc index                   ; ...+ index = index * 5
    tax
    lda ptab,x
    sta X16_P0
    lda ptab+1,x
    sta X16_P1
    lda ptab+2,x
    sta X16_P2
    lda ptab+3,x
    sta X16_P3
    lda ptab+4,x
    sta X16_P5
    rts

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
    ldx #3
    lda #$00
    ldy #$0F
    jsr pal_set                 ; 3 = red    $0F00 (spare)
    rts

; ---------------------------------------------------------------------
; cx.w, cy.w, sides.b -- a 3x3 grid of centres. Every shape fits its
; radius inside the 640x480 field (the fill does not clip).
NPOLY = 9
ptab
    !word 110, 100 : !byte 3    ; triangle
    !word 320, 100 : !byte 4    ; square
    !word 530, 100 : !byte 5    ; pentagon
    !word 110, 240 : !byte 6    ; hexagon
    !word 320, 240 : !byte 7    ; heptagon
    !word 530, 240 : !byte 8    ; octagon
    !word 110, 380 : !byte 9    ; nonagon
    !word 320, 380 : !byte 10   ; decagon
    !word 530, 380 : !byte 12   ; dodecagon

index !byte 0

; ---------------------------------------------------------------------
!source "x16_code.asm"
