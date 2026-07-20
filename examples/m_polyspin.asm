;ACME
; =====================================================================
; x16lib example :: m_polyspin.asm  (a macro-friendly take on polyspin.asm)
; =====================================================================
; polyspin.asm SPINS a polygon: every frame it redraws at rotation += 2,
; a RUN-TIME value. The friendly macros load immediates, so that live
; rotation cannot go through +xm_shape_polygon -- an animated redraw is
; the one shape call that stays hand-written (see draw_poly in
; polyspin.asm, and the per-frame code in m_bounce.asm).
;
; So the macro edition shows the `rotation` argument the way macros CAN:
; a pinwheel -- the same hexagon drawn once per CONSTANT rotation, each a
; one-line +xm_shape_polygon, fanned through a sixth of a turn. Every call
; here is a macro.
;
;   .\build_acme.ps1 -Source examples\m_polyspin.asm -Run
;
; Press any key to return to text mode (windowed).
; =====================================================================

!cpu 65c02
!source "x16.asm"

X16_USE_BITMAP2     = 1         ; for the gfx2_* macros
X16_USE_SHAPES_POLY = 1         ; the polygon (pulls SHAPES, MATH)
X16_USE_PALETTE     = 1
X16_USE_SCREEN      = 1
X16_USE_INPUT       = 1

!source "core/sugar.asm"        ; the +xm_* macros (gated by the above)

CX    = 320                     ; centre of the field
CY    = 240
CR    = 120                     ; radius
SIDES = 6                       ; a hexagon

BG   = 0
C1   = 1
C2   = 2
C3   = 3

* = $0801
    +basic_stub

; ---------------------------------------------------------------------
main
    +xm_gfx2_init
    +xm_gfx2_clear BG
    jsr set_palette

    ; The pinwheel: one hexagon outline per rotation, fanned across a
    ; sixth of a turn (0..40 of the 256-unit circle), colours cycling.
    +xm_shape_polygon CX, CY, CR, SIDES,  0, C1
    +xm_shape_polygon CX, CY, CR, SIDES,  4, C2
    +xm_shape_polygon CX, CY, CR, SIDES,  8, C3
    +xm_shape_polygon CX, CY, CR, SIDES, 12, C1
    +xm_shape_polygon CX, CY, CR, SIDES, 16, C2
    +xm_shape_polygon CX, CY, CR, SIDES, 20, C3
    +xm_shape_polygon CX, CY, CR, SIDES, 24, C1
    +xm_shape_polygon CX, CY, CR, SIDES, 28, C2
    +xm_shape_polygon CX, CY, CR, SIDES, 32, C3
    +xm_shape_polygon CX, CY, CR, SIDES, 36, C1
    +xm_shape_polygon CX, CY, CR, SIDES, 40, C2

    +vera_addrsel 0             ; hand VERA back to the KERNAL cleanly
    +xm_key_wait                ; hold the picture
    +xm_screen_set_mode $00     ; back to 80x60 text
    rts

; --- palette ---------------------------------------------------------
set_palette
    +xm_pal_set BG, $0000       ; black paper
    +xm_pal_set C1, $0FFF       ; white
    +xm_pal_set C2, $000C       ; blue
    +xm_pal_set C3, $0F00       ; red
    rts

; ---------------------------------------------------------------------
!source "x16_code.asm"
