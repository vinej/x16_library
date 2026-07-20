;ACME
; =====================================================================
; x16lib example :: curves.asm
; =====================================================================
; A gallery of the curve shapes, in three bands:
;   - rounded rectangles (shape_frrect filled, shape_rrect outline, and
;     a stadium where the radius reaches half the height),
;   - arcs and a pie (concentric shape_arc "rainbow", plus a shape_pie
;     Pac-Man with its rim outlined by shape_arc),
;   - cubic Beziers (shape_bezier).
;
; It also shows the OPTIONAL friendly macro layer, core/sugar.asm: every
; call here is a one-line +xm_* macro instead of a block of lda/sta. Set
; your gates, source core/sugar.asm, and +xm_shape_frrect etc. expand to
; exactly the hand-written argument setup + jsr.
;
;   .\build_acme.ps1 -Source examples\curves.asm -Run
;
; Press any key to return to text mode. Runs windowed (waits on the
; keyboard), so it would hang under the headless -testbench.
; =====================================================================

!cpu 65c02
!source "x16.asm"

X16_USE_BITMAP2       = 1       ; the 2bpp engine the shapes bind to
X16_USE_SHAPES_RRECT  = 1       ; rounded rectangles (self-contained)
X16_USE_SHAPES_ARC    = 1       ; arcs (pulls MATH + SHP_LINE)
X16_USE_SHAPES_PIE    = 1       ; filled pies (pulls SHAPES_ARC)
X16_USE_SHAPES_BEZIER = 1       ; cubic Beziers (pulls SHP_LINE)
X16_USE_PALETTE       = 1       ; recolour the four-entry palette
X16_USE_SCREEN        = 1       ; restore text mode on the way out
X16_USE_INPUT         = 1       ; wait for a key

!source "core/sugar.asm"        ; the +xm_* macros (gated by the above)

BG   = 0                        ; palette slots (see set_palette)
INK  = 1                        ; outlines
FILL = 2                        ; bodies
ACC  = 3                        ; accents

* = $0801
    +basic_stub

; ---------------------------------------------------------------------
main
    +xm_gfx2_init               ; 640x480 @ 2bpp on layer 0
    +xm_gfx2_clear BG
    jsr set_palette

    jsr draw_rrects
    jsr draw_arcs
    jsr draw_beziers

    +vera_addrsel 0             ; hand VERA back to the KERNAL cleanly
    +xm_key_wait                ; hold the picture
    +xm_screen_set_mode $00     ; back to 80x60 text
    rts

; --- rounded rectangles ----------------------------------------------
draw_rrects
    +xm_shape_frrect  40, 40, 200, 110, 28, FILL   ; a filled rrect
    +xm_shape_rrect   40, 40, 200, 110, 28, INK    ; ...outlined on top
    +xm_shape_rrect  290, 40, 230, 110, 55, ACC    ; a stadium (r = h/2)
    rts

; --- arcs and a pie --------------------------------------------------
draw_arcs
    +xm_shape_arc 150, 310, 70, 128, 0, INK        ; three concentric
    +xm_shape_arc 150, 310, 55, 128, 0, ACC        ; top-half arcs
    +xm_shape_arc 150, 310, 40, 128, 0, FILL       ; (west round to east)
    +xm_shape_pie 470, 300, 75, 32, 224, FILL      ; a Pac-Man wedge...
    +xm_shape_arc 470, 300, 75, 32, 224, INK       ; ...with its rim outlined
    rts

; --- cubic Beziers ---------------------------------------------------
draw_beziers
    +xm_shape_bezier  40,460, 160,380, 300,470, 430,390, INK   ; an S-curve
    +xm_shape_bezier  40,410, 220,470, 400,410, 590,455, ACC   ; a shallow wave
    +xm_shape_bezier 470,465, 615,385, 430,385, 560,465, FILL  ; a tight twist
    rts

; --- palette ---------------------------------------------------------
; A 12-bit $0RGB colour for each of the four 2bpp slots.
set_palette
    +xm_pal_set BG,   $0FFF     ; white paper
    +xm_pal_set INK,  $000F     ; blue outline
    +xm_pal_set FILL, $00F0     ; green body
    +xm_pal_set ACC,  $0F00     ; red accent
    rts

; ---------------------------------------------------------------------
!source "x16_code.asm"
