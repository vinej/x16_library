;ACME
; =====================================================================
; x16lib example :: m_polygons.asm  (the macro edition of polygons.asm)
; =====================================================================
; The same 3x3 gallery of regular polygons as polygons.asm, but instead
; of a data table and a loop it spells each shape out with a one-line
; +xm_shape_* macro -- which reads as the picture it draws. The whole
; body is now literal: nine filled polygons, each outlined on top.
;
;   .\build_acme.ps1 -Source examples\m_polygons.asm -Run
;
; Press any key to return to text mode (windowed).
; =====================================================================

!cpu 65c02
!source "x16.asm"

X16_USE_BITMAP2     = 1         ; the 2bpp engine (for the gfx2_* macros)
X16_USE_SHAPES_POLY = 1         ; the polygons (pulls SHAPES, MATH)
X16_USE_PALETTE     = 1
X16_USE_SCREEN      = 1
X16_USE_INPUT       = 1

!source "core/sugar.asm"        ; the +xm_* macros (gated by the above)

R   = 58                        ; every polygon's radius
ROT = 192                       ; first vertex points north (up)

BG   = 0
INK  = 1                        ; outline
FILL = 2                        ; body

* = $0801
    +basic_stub

; ---------------------------------------------------------------------
main
    +xm_gfx2_init
    +xm_gfx2_clear BG
    jsr set_palette

    ; Row 1: triangle, square, pentagon
    +xm_shape_fpolygon 110, 100, R, 3,  ROT, FILL
    +xm_shape_polygon  110, 100, R, 3,  ROT, INK
    +xm_shape_fpolygon 320, 100, R, 4,  ROT, FILL
    +xm_shape_polygon  320, 100, R, 4,  ROT, INK
    +xm_shape_fpolygon 530, 100, R, 5,  ROT, FILL
    +xm_shape_polygon  530, 100, R, 5,  ROT, INK
    ; Row 2: hexagon, heptagon, octagon
    +xm_shape_fpolygon 110, 240, R, 6,  ROT, FILL
    +xm_shape_polygon  110, 240, R, 6,  ROT, INK
    +xm_shape_fpolygon 320, 240, R, 7,  ROT, FILL
    +xm_shape_polygon  320, 240, R, 7,  ROT, INK
    +xm_shape_fpolygon 530, 240, R, 8,  ROT, FILL
    +xm_shape_polygon  530, 240, R, 8,  ROT, INK
    ; Row 3: nonagon, decagon, dodecagon
    +xm_shape_fpolygon 110, 380, R, 9,  ROT, FILL
    +xm_shape_polygon  110, 380, R, 9,  ROT, INK
    +xm_shape_fpolygon 320, 380, R, 10, ROT, FILL
    +xm_shape_polygon  320, 380, R, 10, ROT, INK
    +xm_shape_fpolygon 530, 380, R, 12, ROT, FILL
    +xm_shape_polygon  530, 380, R, 12, ROT, INK

    +vera_addrsel 0             ; hand VERA back to the KERNAL cleanly
    +xm_key_wait                ; hold the picture
    +xm_screen_set_mode $00     ; back to 80x60 text
    rts

; --- palette ---------------------------------------------------------
set_palette
    +xm_pal_set BG,   $0FFF     ; white paper
    +xm_pal_set INK,  $000F     ; blue outline
    +xm_pal_set FILL, $00F0     ; green body
    +xm_pal_set 3,    $0F00     ; red spare
    rts

; ---------------------------------------------------------------------
!source "x16_code.asm"
