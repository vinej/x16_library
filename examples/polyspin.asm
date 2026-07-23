;ACME
; =====================================================================
; x16lib example :: polyspin.asm
; =====================================================================
; A filled polygon spinning in place, to show the `rotation` argument in
; motion. Each frame clears the polygon's box, redraws it a little more
; turned (rotation += 2), and waits for VSYNC. Press any key to stop.
;
;   .\build_acme.ps1 -Source examples\polyspin.asm -Run
;
; Needs real VSYNC, so run it windowed -- under the headless -testbench
; there is no video, no VSYNC interrupt, and vsync_wait never returns.
;
; Single-buffered (two 640x480 2bpp buffers do not fit in VRAM), so the
; redraw can shear a little as the raster catches it -- fine for a demo.
; =====================================================================

!cpu 65c02
!source "x16.asm"

X16_USE_SHAPES_POLY = 1         ; the polygon (pulls SHAPES, BITMAP2, MATH)
X16_USE_PALETTE     = 1
X16_USE_SCREEN      = 1         ; restore text mode on exit
X16_USE_INPUT       = 1         ; poll for a key
X16_USE_IRQ         = 1         ; vsync_wait

CX    = 320                     ; centre of the field
CY    = 240
CR    = 80                      ; radius
SIDES = 6                       ; a hexagon
STEP  = 2                       ; rotation added per frame

; the box wiped each frame: a little larger than the polygon
BOX_X = CX - CR - 3
BOX_Y = CY - CR - 3
BOX_S = CR + CR + 6

BG   = 0
INK  = 1
FILL = 2

* = $0801
    +basic_stub

; ---------------------------------------------------------------------
main
    jsr gfx2h_init
    lda #BG
    jsr gfx2h_clear
    jsr set_palette
    jsr irq_install             ; start the VSYNC counter vsync_wait reads
    stz angle

@loop
    jsr vsync_wait              ; align the redraw to the frame start
    jsr clear_box               ; wipe last frame's polygon

    jsr set_common              ; centre, radius, sides, rotation
    lda #FILL
    jsr shape_fpolygon          ; the body (consumes the P block)
    jsr set_common
    lda #INK
    jsr shape_polygon           ; outline on top

    lda angle                   ; turn a little for next frame
    clc
    adc #STEP
    sta angle

    +vera_addrsel 0             ; leave VERA as the KERNAL expects
    jsr key_get                 ; non-blocking: 0 = nothing pressed
    beq @loop

    jsr irq_remove
    lda #$00
    jmp screen_set_mode         ; back to 80x60 text

; --- helpers ---------------------------------------------------------

; P0/P1 = cx, P2/P3 = cy, P4 = r, P5 = sides, P6 = current rotation
set_common
    lda #<CX
    sta X16_P0
    lda #>CX
    sta X16_P1
    lda #<CY
    sta X16_P2
    lda #>CY
    sta X16_P3
    lda #CR
    sta X16_P4
    lda #SIDES
    sta X16_P5
    lda angle
    sta X16_P6
    rts

; erase the polygon's box to the background colour
clear_box
    lda #<BOX_X
    sta X16_P0
    lda #>BOX_X
    sta X16_P1
    lda #<BOX_Y
    sta X16_P2
    lda #>BOX_Y
    sta X16_P3
    lda #<BOX_S
    sta X16_P4
    lda #>BOX_S
    sta X16_P5
    lda #<BOX_S
    sta X16_P6
    lda #>BOX_S
    sta X16_P7
    lda #BG
    jmp gfx2h_rect

; a 0RGB colour for each slot (pal_set: X = slot, A = G<<4|B, Y = R)
set_palette
    ldx #BG
    lda #$00
    ldy #$00
    jsr pal_set                 ; 0 = black $0000 (paper)
    ldx #INK
    lda #$FF
    ldy #$0F
    jsr pal_set                 ; 1 = white $0FFF (outline)
    ldx #FILL
    lda #$0C
    ldy #$00
    jsr pal_set                 ; 2 = blue  $00_0C (body)
    ldx #3
    lda #$00
    ldy #$0F
    jsr pal_set                 ; 3 = red   $0F00 (spare)
    rts

angle !byte 0

; ---------------------------------------------------------------------
!source "x16_code.asm"
