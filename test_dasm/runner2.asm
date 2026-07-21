;ACME
; =====================================================================
; x16lib :: test/runner2.asm -- on-target regression tests, part 2
; =====================================================================
;   build.ps1 -Test            (runs every runner in sequence)
;
; The suite outgrew one PRG: runner.asm ends a few hundred bytes short
; of the $9EFF ceiling, so newer modules test here. Same rules: drive
; the library one way, verify through the independent data port.
; =====================================================================

    processor 65c02
    include "x16.asm"

X16_USE_BITMAP2 = 1
X16_USE_SHAPES  = 1             ; pulls in VERA and VERAFX
X16_USE_SHAPES_POLY = 1         ; + regular polygons (pulls in MATH)
X16_USE_SHAPES_RRECT = 1        ; + rounded rectangles
X16_USE_SHAPES_ARC = 1          ; + arcs (pulls MATH + SHP_LINE)
X16_USE_SHAPES_PIE = 1          ; + filled pies (pulls SHAPES_ARC)
X16_USE_SHAPES_BEZIER = 1       ; + cubic Bezier curves (pulls SHP_LINE)
X16_USE_COLLIDE = 1             ; for the xm_collide16 macro test
X16_USE_BCD = 1                 ; packed-BCD decimal add/subtract
X16_USE_STACK = 1               ; 8 KB LIFO stack in a HIRAM bank
X16_USE_RINGBUFFER = 1          ; 8 KB FIFO ring in a HIRAM bank
X16_USE_STRING = 1              ; string fundamentals
X16_USE_STRING_CTYPE = 1        ; character classification
X16_USE_STRING_CASE = 1         ; case folding
X16_USE_STRING_FIND = 1         ; searching
X16_USE_STRING_SLICE = 1        ; substrings

    include "core/sugar.asm"        ; optional friendly xm_* macros (gated; tested below)

; The harness's zero-page pointer (see runner.asm).
T_ZP = $70

; framebuffer byte addresses the tests probe (row y starts at y*160)
G2R10   = 10*160
G2R12   = 12*160
G2R20   = 20*160
G2R21   = 21*160
G2R30B1 = 30*160+1
G2R40   = 40*160
G2R41B1 = 41*160+1
G2R42B1 = 42*160+1
G2R50   = 50*160
G2R51   = 51*160
G2R52   = 52*160
G2R60   = 60*160
G2R63   = 63*160
G2R64B1 = 64*160+1
G2R67B1 = 67*160+1
G2R70   = 70*160
G2R74   = 74*160
G2R80B2 = 80*160+2
G2R80   = 80*160
G2R81B2 = 81*160+2
G2R90B3 = 90*160+3

    org $0801
    basic_stub

; ---------------------------------------------------------------------
    SUBROUTINE
main
    jsr t_init

    jsr test_g2_pset
    jsr test_g2_read
    jsr test_g2_hline
    jsr test_g2_hline_short
    jsr test_g2_vline
    jsr test_g2_rect
    jsr test_g2_frame
    jsr test_g2_line
    jsr test_g2_pattern
    jsr test_g2_pattern_phase
    jsr test_g2_blit
    jsr test_g2_blitm
    jsr test_shape_circle
    jsr test_shape_disc
    jsr test_shape_ellipse
    jsr test_shape_fellipse
    jsr test_shape_flood
    jsr test_shape_polygon
    jsr test_shape_rrect
    jsr test_shape_stadium
    jsr test_shape_arc
    jsr test_shape_pie
    jsr test_shape_bezier
    jsr test_sugar
    jsr test_sugar_collide
    jsr test_bcd16
    jsr test_bcd8
    jsr test_bcd_add32
    jsr test_bcd_ptr
    jsr test_stack
    jsr test_stack_word
    jsr test_ring
    jsr test_ring_word
    jsr test_ring_wrap
    jsr test_str_core
    jsr test_str_cmp
    jsr test_str_edit
    jsr test_str_ctype
    jsr test_str_case
    jsr test_str_lower
    jsr test_str_find
    jsr test_str_pat
    jsr test_str_slice
    jsr test_str_trim
    jsr test_str_sugar
    jsr test_g2_clear
    jsr test_g2_init

    jsr t_summary
    rts

; =====================================================================
; gfx2 (640x480@2bpp): 4 pixels per byte, MSB-first, rows of 160.
; Every test paints a known background first and verifies through
; port 1, including an untouched neighbour byte. The framebuffer
; region starts at VRAM $00000; row y begins at y*160.
; =====================================================================
    SUBROUTINE
test_g2_pset
    vera_addr 0, G2R10, VERA_INC_1
    lda #$00
    ldx #8
    ldy #0
    jsr vera_fill               ; row 10, bytes 0-7 = background

    stz X16_P1                  ; (0,10) colour 3 -> byte 0 pixel 0
    stz X16_P0
    lda #10
    sta X16_P2
    stz X16_P3
    lda #3
    jsr gfx2_pset
    lda #5                      ; (5,10) colour 2 -> byte 1 pixel 1
    sta X16_P0
    lda #2
    jsr gfx2_pset
    lda #10                     ; (10,10) colour 1 -> byte 2 pixel 2
    sta X16_P0
    lda #1
    jsr gfx2_pset
    lda #15                     ; (15,10) colour 3 -> byte 3 pixel 3
    sta X16_P0
    lda #3
    jsr gfx2_pset

    vera_addr 1, G2R10, VERA_INC_1
    lda VERA_DATA1
    cmp #$C0
    bne .fail_far
    lda VERA_DATA1
    cmp #$20
    bne .fail_far
    lda VERA_DATA1
    cmp #$04
    bne .fail_far
    lda VERA_DATA1
    cmp #$03
    bne .fail_far
    lda VERA_DATA1              ; byte 4: untouched background
    bne .fail_far

    ; the last pixel of the screen: (639,479) is byte 76,799
    vera_addr 0, 76799, VERA_INC_1
    lda #$00
    sta VERA_DATA0
    lda #<639
    sta X16_P0
    lda #>639
    sta X16_P1
    lda #<479
    sta X16_P2
    lda #>479
    sta X16_P3
    lda #3
    jsr gfx2_pset
    vera_addr 1, 76799, VERA_INC_1
    lda VERA_DATA1
    cmp #$03
    bne .fail_far
    bra .clip

.fail_far                       ; .fail is out of branch range above
    jmp .fail

.clip
    ; clipping: (640,0) would land at byte 160, (0,480) at 76,800
    vera_addr 0, 160, VERA_INC_1
    lda #$11
    sta VERA_DATA0
    lda #<640
    sta X16_P0
    lda #>640
    sta X16_P1
    stz X16_P2
    stz X16_P3
    lda #3
    jsr gfx2_pset
    vera_addr 1, 160, VERA_INC_1
    lda VERA_DATA1
    cmp #$11
    bne .fail
    vera_addr 0, 76800, VERA_INC_1
    lda #$22
    sta VERA_DATA0
    stz X16_P0
    stz X16_P1
    lda #<480
    sta X16_P2
    lda #>480
    sta X16_P3
    lda #3
    jsr gfx2_pset
    vera_addr 1, 76800, VERA_INC_1
    lda VERA_DATA1
    cmp #$22
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "G2_PSET", $00

; ---------------------------------------------------------------------
    SUBROUTINE
test_g2_read
    vera_addr 0, G2R12, VERA_INC_1
    lda #$1B                    ; pixels 0,1,2,3 left to right
    sta VERA_DATA0

    stz X16_P0                  ; walk the four pixels back out
    stz X16_P1
    lda #12
    sta X16_P2
    stz X16_P3
    jsr gfx2_read
    bcs .fail
    cmp #0
    bne .fail
    lda #1
    sta X16_P0
    jsr gfx2_read
    bcs .fail
    cmp #1
    bne .fail
    lda #2
    sta X16_P0
    jsr gfx2_read
    bcs .fail
    cmp #2
    bne .fail
    lda #3
    sta X16_P0
    jsr gfx2_read
    bcs .fail
    cmp #3
    bne .fail

    lda #<640                   ; off screen reads carry set
    sta X16_P0
    lda #>640
    sta X16_P1
    jsr gfx2_read
    bcc .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "G2_READ", $00

; ---------------------------------------------------------------------
; x=5 len=13 colour 3: pixels 5..17. Head = byte 1 pixels 1-3 ($3F),
; middle = bytes 2,3 ($FF), tail = byte 4 pixels 0-1 ($F0). The bytes
; either side must survive.
; ---------------------------------------------------------------------
    SUBROUTINE
test_g2_hline
    vera_addr 0, G2R20, VERA_INC_1
    lda #$00
    ldx #8
    ldy #0
    jsr vera_fill

    lda #5
    sta X16_P0
    stz X16_P1
    lda #20
    sta X16_P2
    stz X16_P3
    lda #13
    sta X16_P4
    stz X16_P5
    lda #3
    jsr gfx2_hline

    vera_addr 1, G2R20, VERA_INC_1
    lda VERA_DATA1              ; byte 0: untouched
    bne .fail
    lda VERA_DATA1
    cmp #$3F                    ; head
    bne .fail
    lda VERA_DATA1
    cmp #$FF                    ; middle
    bne .fail
    lda VERA_DATA1
    cmp #$FF
    bne .fail
    lda VERA_DATA1
    cmp #$F0                    ; tail
    bne .fail
    lda VERA_DATA1              ; byte 5: untouched
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "G2_HLINE", $00

; ---------------------------------------------------------------------
; a span that begins and ends inside one byte: x=1 len=2, colour 2
; ---------------------------------------------------------------------
    SUBROUTINE
test_g2_hline_short
    vera_addr 0, G2R21, VERA_INC_1
    lda #$00
    ldx #4
    ldy #0
    jsr vera_fill

    lda #1
    sta X16_P0
    stz X16_P1
    lda #21
    sta X16_P2
    stz X16_P3
    lda #2
    sta X16_P4
    stz X16_P5
    lda #2
    jsr gfx2_hline

    vera_addr 1, G2R21, VERA_INC_1
    lda VERA_DATA1
    cmp #$28                    ; colour 2 in pixels 1,2 only
    bne .fail
    lda VERA_DATA1              ; the next byte: untouched
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "G2_HLINE_SHORT", $00

; ---------------------------------------------------------------------
; colour 0 ink onto a $FF background: proves vline really is RMW
; ---------------------------------------------------------------------
    SUBROUTINE
test_g2_vline
    vera_addr 0, G2R30B1, VERA_INC_160
    lda #$FF
    ldx #5
    ldy #0
    jsr vera_fill               ; byte 1 of rows 30-34

    lda #6                      ; x=6: byte 1, pixel 2
    sta X16_P0
    stz X16_P1
    lda #30
    sta X16_P2
    stz X16_P3
    lda #4
    sta X16_P4
    stz X16_P5
    lda #0
    jsr gfx2_vline

    vera_addr 1, G2R30B1, VERA_INC_160
    ldx #4
.check
    lda VERA_DATA1
    cmp #$F3                    ; pixel 2 cleared, the rest kept
    bne .fail
    dex
    bne .check
    lda VERA_DATA1              ; row 34: untouched
    cmp #$FF
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "G2_VLINE", $00

; ---------------------------------------------------------------------
    SUBROUTINE
test_g2_rect
    vera_addr 0, G2R40, VERA_INC_1
    lda #$00
    ldx #<480
    ldy #>480
    jsr vera_fill               ; rows 40-42 entirely

    lda #4                      ; x=4 y=40 w=8 h=2, colour 1
    sta X16_P0
    stz X16_P1
    lda #40
    sta X16_P2
    stz X16_P3
    lda #8
    sta X16_P4
    stz X16_P5
    lda #2
    sta X16_P6
    stz X16_P7
    lda #1
    jsr gfx2_rect

    vera_addr 1, G2R40, VERA_INC_1
    lda VERA_DATA1
    bne .fail                   ; byte 0 untouched
    lda VERA_DATA1
    cmp #$55
    bne .fail
    lda VERA_DATA1
    cmp #$55
    bne .fail
    lda VERA_DATA1
    bne .fail                   ; byte 3 untouched
    vera_addr 1, G2R41B1, VERA_INC_1
    lda VERA_DATA1
    cmp #$55                    ; second row filled too
    bne .fail
    vera_addr 1, G2R42B1, VERA_INC_1
    lda VERA_DATA1
    bne .fail                   ; row past the rect: untouched
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "G2_RECT", $00

; ---------------------------------------------------------------------
    SUBROUTINE
test_g2_frame
    vera_addr 0, G2R50, VERA_INC_1
    lda #$00
    ldx #<480
    ldy #>480
    jsr vera_fill               ; rows 50-52

    stz X16_P0                  ; x=0 y=50 w=16 h=3, colour 3
    stz X16_P1
    lda #50
    sta X16_P2
    stz X16_P3
    lda #16
    sta X16_P4
    stz X16_P5
    lda #3
    sta X16_P6
    stz X16_P7
    lda #3
    jsr gfx2_frame

    vera_addr 1, G2R50, VERA_INC_1
    ldx #4
.top
    lda VERA_DATA1              ; the top edge: 16 solid pixels
    cmp #$FF
    bne .fail
    dex
    bne .top
    vera_addr 1, G2R51, VERA_INC_1
    lda VERA_DATA1
    cmp #$C0                    ; left edge only
    bne .fail
    lda VERA_DATA1
    bne .fail
    lda VERA_DATA1
    bne .fail
    lda VERA_DATA1
    cmp #$03                    ; right edge only
    bne .fail
    vera_addr 1, G2R52, VERA_INC_1
    lda VERA_DATA1              ; the bottom edge
    cmp #$FF
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "G2_FRAME", $00

; ---------------------------------------------------------------------
; the 45-degree diagonal (0,60)-(7,67): pixel (i, 60+i) for every i
; ---------------------------------------------------------------------
    SUBROUTINE
test_g2_line
    vera_addr 0, G2R60, VERA_INC_1
    lda #$00
    ldx #<1280
    ldy #>1280
    jsr vera_fill               ; rows 60-67

    stz X16_P0
    stz X16_P1
    lda #60
    sta X16_P2
    stz X16_P3
    lda #7
    sta X16_P4
    stz X16_P5
    lda #67
    sta X16_P6
    stz X16_P7
    lda #3
    jsr gfx2_line

    vera_addr 1, G2R60, VERA_INC_1
    lda VERA_DATA1
    cmp #$C0                    ; (0,60)
    bne .fail
    vera_addr 1, G2R63, VERA_INC_1
    lda VERA_DATA1
    cmp #$03                    ; (3,63)
    bne .fail
    vera_addr 1, G2R67B1, VERA_INC_1
    lda VERA_DATA1
    cmp #$03                    ; (7,67)
    bne .fail
    vera_addr 1, G2R64B1, VERA_INC_1
    lda VERA_DATA1
    cmp #$C0                    ; (4,64): byte 1, pixel 0, alone
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "G2_LINE", $00

; ---------------------------------------------------------------------
; pattern $F0 (left half ink): even bytes $FF, odd bytes $00
; ---------------------------------------------------------------------
    SUBROUTINE
test_g2_pattern
    lda #<.pat
    ldx #>.pat
    ldy #3                      ; background 0, foreground 3
    jsr gfx2_pattern_set

    vera_addr 0, G2R70, VERA_INC_1
    lda #$55
    ldx #8
    ldy #0
    jsr vera_fill               ; a non-zero background

    stz X16_P0                  ; x=0 y=70 w=16 h=1
    stz X16_P1
    lda #70
    sta X16_P2
    stz X16_P3
    lda #16
    sta X16_P4
    stz X16_P5
    lda #1
    sta X16_P6
    stz X16_P7
    jsr gfx2_pattern_rect

    vera_addr 1, G2R70, VERA_INC_1
    lda VERA_DATA1
    cmp #$FF                    ; even byte: the ink half
    bne .fail
    lda VERA_DATA1
    bne .fail                   ; odd byte: the background half
    lda VERA_DATA1
    cmp #$FF
    bne .fail
    lda VERA_DATA1
    bne .fail
    lda VERA_DATA1              ; byte 4: untouched background
    cmp #$55
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "G2_PATTERN", $00
.pat dc.b $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0

; ---------------------------------------------------------------------
; the same pattern at x=2: a phase-2 head, an odd middle byte, a tail.
; Patterns anchor to the screen, not the span, so the head byte gets
; the EVEN pattern byte's pixels 2-3 and the tail the even byte again.
; ---------------------------------------------------------------------
    SUBROUTINE
test_g2_pattern_phase
    lda #<.pat2
    ldx #>.pat2
    ldy #3
    jsr gfx2_pattern_set

    vera_addr 0, G2R74, VERA_INC_1
    lda #$00
    ldx #4
    ldy #0
    jsr vera_fill

    lda #2                      ; x=2 y=74 w=8 h=1
    sta X16_P0
    stz X16_P1
    lda #74
    sta X16_P2
    stz X16_P3
    lda #8
    sta X16_P4
    stz X16_P5
    lda #1
    sta X16_P6
    stz X16_P7
    jsr gfx2_pattern_rect

    vera_addr 1, G2R74, VERA_INC_1
    lda VERA_DATA1
    cmp #$0F                    ; head: even byte through pixels 2-3
    bne .fail
    lda VERA_DATA1
    bne .fail                   ; middle: the odd (background) byte
    lda VERA_DATA1
    cmp #$F0                    ; tail: even byte through pixels 0-1
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "G2_PATTERN_PH", $00
.pat2 dc.b $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0

; ---------------------------------------------------------------------
; blit op 0 lays the image down; blitting it again with XOR must
; return the background to zero.
; ---------------------------------------------------------------------
    SUBROUTINE
test_g2_blit
    vera_addr 0, G2R80, VERA_INC_1
    lda #$00
    ldx #<400
    ldy #>400
    jsr vera_fill               ; rows 80-82 (two rows + slack)

    lda #8                      ; x=8 (byte 2), y=80, 2x2 bytes
    sta X16_P0
    stz X16_P1
    lda #80
    sta X16_P2
    stz X16_P3
    lda #2
    sta X16_P4
    lda #2
    sta X16_P5
    lda #<.img
    sta X16_P6
    lda #>.img
    sta X16_P7
    lda #0                      ; copy
    jsr gfx2_blit

    vera_addr 1, G2R80B2, VERA_INC_1
    lda VERA_DATA1
    cmp #$DE
    bne .fail_far
    lda VERA_DATA1
    cmp #$AD
    bne .fail_far
    vera_addr 1, G2R81B2, VERA_INC_1
    lda VERA_DATA1
    cmp #$BE
    bne .fail_far
    lda VERA_DATA1
    cmp #$EF
    bne .fail_far
    bra .xor_pass

.fail_far                       ; .fail is out of branch range above
    jmp .fail

.xor_pass
    lda #8                      ; the same blit, XORed on top
    sta X16_P0
    stz X16_P1
    lda #80
    sta X16_P2
    stz X16_P3
    lda #2
    sta X16_P4
    lda #2
    sta X16_P5
    lda #<.img
    sta X16_P6
    lda #>.img
    sta X16_P7
    lda #3                      ; xor
    jsr gfx2_blit

    vera_addr 1, G2R80B2, VERA_INC_1
    lda VERA_DATA1
    bne .fail
    lda VERA_DATA1
    bne .fail
    vera_addr 1, G2R81B2, VERA_INC_1
    lda VERA_DATA1
    bne .fail
    lda VERA_DATA1
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "G2_BLIT", $00
.img dc.b $DE, $AD, $BE, $EF

; ---------------------------------------------------------------------
; masked column blit onto a solid $FF background: keep pixels 2-3
; (mask $0F), ink pixels 0-1 with colour 1 (data $50) -> $5F
; ---------------------------------------------------------------------
    SUBROUTINE
test_g2_blitm
    vera_addr 0, G2R90B3, VERA_INC_160
    lda #$FF
    ldx #5
    ldy #0
    jsr vera_fill               ; byte 3 of rows 90-94

    lda #12                     ; x=12: byte 3, phase 0
    sta X16_P0
    stz X16_P1
    lda #90
    sta X16_P2
    stz X16_P3
    lda #4                      ; 4 rows
    sta X16_P4
    lda #1                      ; 1 column
    sta X16_P5
    lda #<.mcol
    sta X16_P6
    lda #>.mcol
    sta X16_P7
    jsr gfx2_blitm

    vera_addr 1, G2R90B3, VERA_INC_160
    ldx #4
.check
    lda VERA_DATA1
    cmp #$5F
    bne .fail
    dex
    bne .check
    lda VERA_DATA1              ; row 94: untouched
    cmp #$FF
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "G2_BLITM", $00
.mcol dc.b $0F, $50, $0F, $50, $0F, $50, $0F, $50   ; (mask,data) x4

; ---------------------------------------------------------------------
; gfx2_clear floods exactly the 76,800 framebuffer bytes and nothing
; past them
; ---------------------------------------------------------------------
    SUBROUTINE
test_g2_clear
    vera_addr 0, 76800, VERA_INC_1
    lda #$77                    ; sentinel one byte past the end
    sta VERA_DATA0

    lda #2
    jsr gfx2_clear

    vera_addr 1, 0, VERA_INC_1
    lda VERA_DATA1
    cmp #$AA
    bne .fail
    vera_addr 1, 38400, VERA_INC_1
    lda VERA_DATA1              ; the second fx_fill half
    cmp #$AA
    bne .fail
    vera_addr 1, 76799, VERA_INC_1
    lda VERA_DATA1              ; the very last byte
    cmp #$AA
    bne .fail
    lda VERA_DATA1              ; ...and the sentinel after it
    cmp #$77
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "G2_CLEAR", $00

; ---------------------------------------------------------------------
; the mode registers land as programmed (runs last: it changes the
; display configuration and the first four palette entries)
; ---------------------------------------------------------------------
    SUBROUTINE
test_g2_init
    jsr gfx2_init

    lda VERA_L0_CONFIG
    cmp #(VERA_LAYER_BITMAP | VERA_LAYER_BPP_2)
    bne .fail
    lda VERA_L0_TILEBASE
    cmp #$01
    bne .fail
    vera_dcsel 0
    lda VERA_DC_HSCALE
    cmp #$80
    bne .fail
    lda VERA_DC_VSCALE
    cmp #$80
    bne .fail
    lda VERA_DC_VIDEO
    and #VERA_VIDEO_LAYER0_EN
    beq .fail
    lda VERA_DC_VIDEO
    and #VERA_VIDEO_LAYER1_EN
    bne .fail

    vera_addr 1, VRAM_PALETTE, VERA_INC_1
    ldx #0
.pal
    lda VERA_DATA1
    cmp .want,x
    bne .fail
    inx
    cpx #8
    bne .pal
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "G2_INIT", $00
.want dc.b $FF, $0F, $AA, $0A, $55, $05, $00, $00

; ---------------------------------------------------------------------
    include "test_dasm/testlib.asm"

; SHAPE_CIRC: a midpoint circle's cardinal points land at exactly r
    SUBROUTINE
test_shape_circle
    lda #100
    jsr shp_clear40             ; a clean 40x40 patch at (100,100)
    lda #120
    sta X16_P0
    stz X16_P1
    lda #120
    sta X16_P2
    stz X16_P3
    lda #15
    sta X16_P4
    lda #3
    jsr shape_circle
    ldy #1
    lda #135                    ; east
    ldx #120
    jsr shp_rd
    cmp #3
    bne .report
    lda #105                    ; west
    ldx #120
    jsr shp_rd
    cmp #3
    bne .report
    lda #120                    ; south
    ldx #135
    jsr shp_rd
    cmp #3
    bne .report
    lda #120                    ; centre stays clear: an outline
    ldx #120
    jsr shp_rd
    bne .report
    ldy #0
.report
    tya
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SHAPE_CIRC", 0

; SHAPE_DISC: filled to the rim, clear past it
    SUBROUTINE
test_shape_disc
    lda #180
    jsr shp_clear40             ; a clean patch at (180,100)
    lda #200
    sta X16_P0
    stz X16_P1
    lda #120
    sta X16_P2
    stz X16_P3
    lda #10
    sta X16_P4
    lda #2
    jsr shape_disc
    ldy #1
    lda #200                    ; centre
    ldx #120
    jsr shp_rd
    cmp #2
    bne .report
    lda #210                    ; the rim
    ldx #120
    jsr shp_rd
    cmp #2
    bne .report
    lda #200                    ; two past the rim, straight down
    ldx #132
    jsr shp_rd
    bne .report
    ldy #0
.report
    tya
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SHAPE_DISC", 0

; SHAPE_ELLIP: the outline's cardinal points land at exactly rx / ry
    SUBROUTINE
test_shape_ellipse
    lda #100
    jsr shp_clear40             ; a clean 40x40 patch at (100,100)
    lda #120
    sta X16_P0
    stz X16_P1
    lda #120
    sta X16_P2
    stz X16_P3
    lda #15                     ; rx = 15, ry = 8
    sta X16_P4
    lda #8
    sta X16_P5
    lda #3
    jsr shape_ellipse
    ldy #1
    lda #135                    ; east
    ldx #120
    jsr shp_rd
    cmp #3
    bne .report
    lda #105                    ; west
    ldx #120
    jsr shp_rd
    cmp #3
    bne .report
    lda #120                    ; south
    ldx #128
    jsr shp_rd
    cmp #3
    bne .report
    lda #120                    ; one past the south pole: clear
    ldx #129
    jsr shp_rd
    bne .report
    lda #120                    ; centre stays clear: an outline
    ldx #120
    jsr shp_rd
    bne .report
    ldy #0
.report
    tya
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SHAPE_ELLIP", 0

; SHAPE_FELLIP: filled to both rims, clear past them
    SUBROUTINE
test_shape_fellipse
    lda #180
    jsr shp_clear40             ; a clean patch at (180,100)
    lda #200
    sta X16_P0
    stz X16_P1
    lda #120
    sta X16_P2
    stz X16_P3
    lda #12                     ; rx = 12, ry = 9
    sta X16_P4
    lda #9
    sta X16_P5
    lda #2
    jsr shape_fellipse
    ldy #1
    lda #200                    ; centre
    ldx #120
    jsr shp_rd
    cmp #2
    bne .report
    lda #212                    ; the east rim
    ldx #120
    jsr shp_rd
    cmp #2
    bne .report
    lda #213                    ; one past it
    ldx #120
    jsr shp_rd
    bne .report
    lda #200                    ; the north rim
    ldx #111
    jsr shp_rd
    cmp #2
    bne .report
    lda #200                    ; one past it
    ldx #110
    jsr shp_rd
    bne .report
    ldy #0
.report
    tya
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SHAPE_FELLIP", 0

; SHAPE_FLOOD: fills a framed box, stops at the frame
    SUBROUTINE
test_shape_flood
    lda #55
    ldx #150
    jsr shp_clear40y            ; a clean patch at (55,150)
    lda #70                     ; the fence: a 20x20 frame, colour 3
    sta X16_P0
    stz X16_P1
    lda #160
    sta X16_P2
    stz X16_P3
    lda #20
    sta X16_P4
    stz X16_P5
    lda #20
    sta X16_P6
    stz X16_P7
    lda #3
    jsr gfx2_frame
    lda #80                     ; flood from inside, colour 1
    sta X16_P0
    stz X16_P1
    lda #170
    sta X16_P2
    stz X16_P3
    lda #1
    jsr shape_flood
    ldy #1
    bcs .report                 ; the stack must not overflow here
    lda #80                     ; inside: filled
    ldx #170
    jsr shp_rd
    cmp #1
    bne .report
    lda #71                     ; the top-left inside corner: filled
    ldx #161
    jsr shp_rd
    cmp #1
    bne .report
    lda #88                     ; the bottom-right corner: filled (the fill
    ldx #178                    ; must reach DOWN from the seed, not just up)
    jsr shp_rd
    cmp #1
    bne .report
    lda #70                     ; the fence itself: intact
    ldx #160
    jsr shp_rd
    cmp #3
    bne .report
    lda #60                     ; outside: untouched
    ldx #155
    jsr shp_rd
    bne .report
    ldy #0
.report
    tya
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SHAPE_FLOOD", 0

; SHAPE_POLYGON: a diamond (4-gon, rotation 0) -- outline, then filled
    SUBROUTINE
test_shape_polygon
    lda #100
    jsr shp_clear40             ; a clean patch at (100,100)
    lda #120                    ; outline at (120,120), r=10, colour 3
    sta X16_P0
    stz X16_P1
    lda #120
    sta X16_P2
    stz X16_P3
    lda #10
    sta X16_P4                  ; radius
    lda #4
    sta X16_P5                  ; sides
    lda #0
    sta X16_P6                  ; rotation: vertices at E, S, W, N
    lda #3
    jsr shape_polygon
    ldy #1
    lda #130                    ; the east vertex
    ldx #120
    jsr shp_rd
    cmp #3
    bne .report
    lda #120                    ; the north vertex
    ldx #110
    jsr shp_rd
    cmp #3
    bne .report
    lda #120                    ; centre: an outline leaves it clear
    ldx #120
    jsr shp_rd
    bne .report

    lda #160
    jsr shp_clear40             ; a clean patch at (160,100)
    lda #180                    ; filled at (180,120), r=10, colour 2
    sta X16_P0
    stz X16_P1
    lda #120
    sta X16_P2
    stz X16_P3
    lda #10
    sta X16_P4
    lda #4
    sta X16_P5
    lda #0
    sta X16_P6
    lda #2
    jsr shape_fpolygon
    lda #180                    ; centre: filled
    ldx #120
    jsr shp_rd
    cmp #2
    bne .report
    lda #180                    ; interior, four rows up
    ldx #116
    jsr shp_rd
    cmp #2
    bne .report
    lda #180                    ; above the north vertex: clear
    ldx #103
    jsr shp_rd
    bne .report
    ldy #0
.report
    tya
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SHAPE_POLYGON", 0

    SUBROUTINE
test_shape_rrect
    lda #200                    ; clean patch at (200,100)
    ldx #100
    jsr shp_clear40y
    lda #200                    ; outline rrect (200,100) 40x30 r=8 colour 3
    sta rr_x
    stz rr_x+1
    lda #100
    sta rr_y
    stz rr_y+1
    lda #40
    sta rr_w
    stz rr_w+1
    lda #30
    sta rr_h
    stz rr_h+1
    lda #8
    sta rr_r
    lda #3
    jsr shape_rrect
    lda #220                    ; top edge, mid: set
    ldx #100
    jsr shp_rd
    cmp #3
    bne .report
    lda #200                    ; sharp corner: cut away, clear
    ldx #100
    jsr shp_rd
    bne .report
    lda #200                    ; left edge, mid height: set
    ldx #115
    jsr shp_rd
    cmp #3
    bne .report
    lda #220                    ; centre: outline leaves it clear
    ldx #115
    jsr shp_rd
    bne .report

    lda #40                     ; clean patch at (40,160)
    ldx #160
    jsr shp_clear40y
    lda #40                     ; filled rrect (40,160) 40x30 r=8 colour 2
    sta rr_x
    stz rr_x+1
    lda #160
    sta rr_y
    stz rr_y+1
    lda #40
    sta rr_w
    stz rr_w+1
    lda #30
    sta rr_h
    stz rr_h+1
    lda #8
    sta rr_r
    lda #2
    jsr shape_frrect
    lda #60                     ; centre: filled
    ldx #175
    jsr shp_rd
    cmp #2
    bne .report
    lda #40                     ; sharp corner: cut away, clear
    ldx #160
    jsr shp_rd
    bne .report
    lda #60                     ; top flat edge: filled
    ldx #160
    jsr shp_rd
    cmp #2
    bne .report
    lda #40                     ; left edge at mid height: filled to x0
    ldx #175
    jsr shp_rd
    cmp #2
    bne .report
    ldy #0
.report
    tya
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SHAPE_RRECT", 0

; A stadium: r = h/2, so the straight vertical sides vanish. Guards the
; regression where the empty side-run wrapped 16-bit and painted the whole
; x0/x1 columns top to bottom.
    SUBROUTINE
test_shape_stadium
    lda #40                     ; clear the column both above and over the shape
    ldx #120
    jsr shp_clear40y
    lda #40
    ldx #160
    jsr shp_clear40y
    lda #40                     ; outline stadium (40,160) 60x40, r=20 = h/2
    sta rr_x
    stz rr_x+1
    lda #160
    sta rr_y
    stz rr_y+1
    lda #60
    sta rr_w
    stz rr_w+1
    lda #40
    sta rr_h
    stz rr_h+1
    lda #20
    sta rr_r
    lda #3
    jsr shape_rrect
    lda #40                     ; column x0, 20 rows above the shape: MUST be clear
    ldx #140
    jsr shp_rd
    beq .cont
.rep
    jmp .report
.cont
    lda #40                     ; leftmost point of the left semicircle: set
    ldx #180
    jsr shp_rd
    cmp #3
    bne .rep
    lda #70                     ; top straight edge between the ends: set
    ldx #160
    jsr shp_rd
    cmp #3
    bne .rep

    lda #40                     ; clean patch for a filled stadium
    ldx #220
    jsr shp_clear40y
    lda #40                     ; filled stadium (40,220) 60x40, r=20
    sta rr_x
    stz rr_x+1
    lda #220
    sta rr_y
    stz rr_y+1
    lda #60
    sta rr_w
    stz rr_w+1
    lda #40
    sta rr_h
    stz rr_h+1
    lda #20
    sta rr_r
    lda #2
    jsr shape_frrect
    lda #70                     ; interior: filled
    ldx #240
    jsr shp_rd
    cmp #2
    bne .rep
    lda #40                     ; sharp corner: cut away by the round end, clear
    ldx #220
    jsr shp_rd
    bne .rep
    ldy #0
.report
    tya
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SHAPE_STADIUM", 0

    SUBROUTINE
test_shape_arc
    lda #80                     ; clean patch at (80,80)
    ldx #80
    jsr shp_clear40y
    lda #100                    ; arc centre (100,100) r=15, 0..64 (E->S)
    sta X16_P0
    stz X16_P1
    lda #100
    sta X16_P2
    stz X16_P3
    lda #15
    sta X16_P4                  ; radius
    lda #0
    sta X16_P5                  ; start angle: east
    lda #64
    sta X16_P6                  ; end angle: south
    lda #3
    jsr shape_arc
    lda #115                    ; east endpoint (cx+r, cy): set
    ldx #100
    jsr shp_rd
    cmp #3
    bne .report
    lda #100                    ; south endpoint (cx, cy+r): set
    ldx #115
    jsr shp_rd
    cmp #3
    bne .report
    lda #85                     ; west (not in 0..64): clear
    ldx #100
    jsr shp_rd
    bne .report
    lda #100                    ; north (not in 0..64): clear
    ldx #85
    jsr shp_rd
    bne .report
    lda #100                    ; centre: an outline leaves it clear
    ldx #100
    jsr shp_rd
    bne .report
    ldy #0
.report
    tya
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SHAPE_ARC", 0

    SUBROUTINE
test_shape_pie
    lda #80                     ; clean patch at (80,80)
    ldx #80
    jsr shp_clear40y
    lda #100                    ; pie centre (100,100) r=15, 0..64 (SE quarter)
    sta X16_P0
    stz X16_P1
    lda #100
    sta X16_P2
    stz X16_P3
    lda #15
    sta X16_P4
    lda #0
    sta X16_P5
    lda #64
    sta X16_P6
    lda #3
    jsr shape_pie
    lda #100                    ; centre (the fan apex): filled
    ldx #100
    jsr shp_rd
    cmp #3
    bne .report
    lda #105                    ; SE interior (45 deg, r~7): filled
    ldx #105
    jsr shp_rd
    cmp #3
    bne .report
    lda #110                    ; on the east radius (angle 0): filled
    ldx #100
    jsr shp_rd
    cmp #3
    bne .report
    lda #95                     ; NW (opposite the wedge): clear
    ldx #95
    jsr shp_rd
    bne .report
    lda #105                    ; NE (outside 0..64): clear
    ldx #95
    jsr shp_rd
    bne .report
    ldy #0
.report
    tya
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SHAPE_PIE", 0

    SUBROUTINE
test_shape_bezier
    lda #95                     ; clean patch at (95,95)
    ldx #95
    jsr shp_clear40y
    lda #100                    ; a straight (collinear) cubic on row 100
    sta bez_x0                  ; P0 = (100,100)
    stz bez_x0+1
    lda #100
    sta bez_y0
    stz bez_y0+1
    lda #110                    ; P1 = (110,100)
    sta bez_x1
    stz bez_x1+1
    lda #100
    sta bez_y1
    stz bez_y1+1
    lda #120                    ; P2 = (120,100)
    sta bez_x2
    stz bez_x2+1
    lda #100
    sta bez_y2
    stz bez_y2+1
    lda #130                    ; P3 = (130,100)
    sta bez_x3
    stz bez_x3+1
    lda #100
    sta bez_y3
    stz bez_y3+1
    lda #3
    jsr shape_bezier
    lda #100                    ; P0 anchor: set
    ldx #100
    jsr shp_rd
    cmp #3
    bne .rep
    lda #130                    ; P3 anchor: set
    ldx #100
    jsr shp_rd
    cmp #3
    bne .rep
    lda #115                    ; midpoint sample (t=0.5): set
    ldx #100
    jsr shp_rd
    cmp #3
    bne .rep
    lda #115                    ; ten rows below: a 1px line leaves it clear
    ldx #110
    jsr shp_rd
    beq .cont
.rep
    jmp .report
.cont
    lda #98                     ; clean patch at (98,158)
    ldx #158
    jsr shp_clear40y
    lda #100                    ; an arched cubic: handles pull upward
    sta bez_x0                  ; P0 = (100,190)
    stz bez_x0+1
    lda #190
    sta bez_y0
    stz bez_y0+1
    lda #110                    ; P1 = (110,160)
    sta bez_x1
    stz bez_x1+1
    lda #160
    sta bez_y1
    stz bez_y1+1
    lda #125                    ; P2 = (125,160)
    sta bez_x2
    stz bez_x2+1
    lda #160
    sta bez_y2
    stz bez_y2+1
    lda #135                    ; P3 = (135,190)
    sta bez_x3
    stz bez_x3+1
    lda #190
    sta bez_y3
    stz bez_y3+1
    lda #2
    jsr shape_bezier
    lda #100                    ; P0 anchor: set
    ldx #190
    jsr shp_rd
    cmp #2
    bne .report
    lda #135                    ; P3 anchor: set
    ldx #190
    jsr shp_rd
    cmp #2
    bne .report
    lda #117                    ; the straight midpoint: curve arched away, clear
    ldx #190
    jsr shp_rd
    bne .report
    ldy #0
.report
    tya
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SHAPE_BEZIER", 0

; The optional sugar macros expand to exactly the hand-written argument
; setup + jsr, so this both proves they work and (via the 7-way PRG hash)
; that they convert byte-identically across every assembler.
    SUBROUTINE
test_sugar
    lda #180                    ; clean patch at (180,80)
    ldx #80
    jsr shp_clear40y
    xm_shape_disc 200, 100, 12, 3   ; filled disc via macro
    lda #200                    ; centre: filled
    ldx #100
    jsr shp_rd
    cmp #3
    bne .report
    lda #180                    ; clean patch at (180,140)
    ldx #140
    jsr shp_clear40y
    xm_shape_circle 200, 160, 12, 2  ; outline circle via macro
    lda #212                    ; east rim (cx+r): set
    ldx #160
    jsr shp_rd
    cmp #2
    bne .report
    lda #200                    ; centre: an outline leaves it clear
    ldx #160
    jsr shp_rd
    bne .report
    ldy #0
.report
    tya
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SUGAR_MACROS", 0

; xm_collide16 writes the cl_* operands and calls collide16 (16-bit boxes).
    SUBROUTINE
test_sugar_collide
    xm_collide16 10, 10, 20, 20, 15, 15, 20, 20   ; overlapping -> carry set
    bcc .fail
    xm_collide16 10, 10, 5, 5, 300, 300, 5, 5     ; disjoint -> carry clear
    bcs .fail
    lda #0
    bra .done
.fail
    lda #1
.done
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SUGAR_COLLIDE", 0

; Packed-BCD decimal add/subtract. Hex bytes ARE the decimal digits, low
; byte first: $0987 is nine-hundred-eighty-seven. Split across a few short
; tests so every branch to .fail stays in range.
    SUBROUTINE
test_bcd16                      ; 16-bit add then subtract
    lda #$87                    ; 987 + 1111 = 2098
    sta bcd_a
    lda #$09
    sta bcd_a+1
    lda #$11
    sta bcd_b
    lda #$11
    sta bcd_b+1
    jsr bcd_add16
    lda bcd_a
    cmp #$98
    bne .fail
    lda bcd_a+1
    cmp #$20
    bne .fail
    lda #$98                    ; 2098 - 1111 = 987
    sta bcd_a
    lda #$20
    sta bcd_a+1
    lda #$11
    sta bcd_b
    lda #$11
    sta bcd_b+1
    jsr bcd_sub16
    lda bcd_a
    cmp #$87
    bne .fail
    lda bcd_a+1
    cmp #$09
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "BCD16", 0

    SUBROUTINE
test_bcd8                       ; 8-bit carry out and borrow
    lda #$99                    ; 99 + 01 = 00, carry set
    sta bcd_a
    lda #$01
    sta bcd_b
    jsr bcd_add8
    bcc .fail
    lda bcd_a
    bne .fail
    lda #$00                    ; 00 - 01 = 99, carry clear (borrow)
    sta bcd_a
    lda #$01
    sta bcd_b
    jsr bcd_sub8
    bcs .fail
    lda bcd_a
    cmp #$99
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "BCD8", 0

    SUBROUTINE
test_bcd_add32                  ; 32-bit add across bytes, and overflow
    i32_const bcd_a, $00009999 ; 9999 + 1 = 10000
    i32_const bcd_b, $00000001
    jsr bcd_add32
    lda bcd_a
    bne .fail
    lda bcd_a+1
    bne .fail
    lda bcd_a+2
    cmp #$01
    bne .fail
    lda bcd_a+3
    bne .fail
    i32_const bcd_a, $99999999 ; 99999999 + 1 = 0, carry set
    i32_const bcd_b, $00000001
    jsr bcd_add32
    bcc .fail
    lda bcd_a
    ora bcd_a+1
    ora bcd_a+2
    ora bcd_a+3
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "BCD_ADD32", 0

    SUBROUTINE
test_bcd_ptr                    ; 32-bit subtract, then the in-place pair
    i32_const bcd_a, $00010000 ; 10000 - 1 = 9999
    i32_const bcd_b, $00000001
    jsr bcd_sub32
    lda bcd_a
    cmp #$99
    bne .fail
    lda bcd_a+1
    cmp #$99
    bne .fail
    lda bcd_a+2
    ora bcd_a+3
    bne .fail
    i32_const bcdval32, $00000042  ; in place: 42 + 58 = 100
    i32_const bcd_b, $00000058
    lda #<bcdval32
    ldx #>bcdval32
    jsr bcd_addto
    lda bcdval32
    bne .fail
    lda bcdval32+1
    cmp #$01
    bne .fail
    i32_const bcd_b, $00000001     ; in place: 100 - 1 = 99
    lda #<bcdval32
    ldx #>bcdval32
    jsr bcd_subfrom
    lda bcdval32
    cmp #$99
    bne .fail
    lda bcdval32+1
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name  dc.b "BCD_PTR", 0
    SUBROUTINE
bcdval32 dc.b 0, 0, 0, 0

; 8 KB banked LIFO stack. Uses bank 5 (the bank tests already prove banks
; round-trip); we check push/pop order and the empty flag through it.
    SUBROUTINE
test_stack
    lda #5
    jsr stack_init
    jsr stack_isempty
    bcc .fail                   ; empty right after init
    lda #42
    jsr stack_push
    lda #7
    jsr stack_push
    lda #99
    jsr stack_push
    jsr stack_size
    cmp #3
    bne .fail
    cpx #0
    bne .fail
    jsr stack_isempty
    bcs .fail                   ; not empty with three bytes on it
    jsr stack_pop
    cmp #99                     ; LIFO: last in, first out
    bne .fail
    jsr stack_pop
    cmp #7
    bne .fail
    jsr stack_pop
    cmp #42
    bne .fail
    jsr stack_isempty
    bcc .fail                   ; empty again
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "STACK", 0

    SUBROUTINE
test_stack_word
    lda #5
    jsr stack_init
    lda #<1000
    ldx #>1000
    jsr stack_pushw
    lda #<50
    ldx #>50
    jsr stack_pushw
    jsr stack_popw              ; LIFO: 50 comes back first
    cmp #<50
    bne .fail
    cpx #>50
    bne .fail
    jsr stack_popw
    cmp #<1000
    bne .fail
    cpx #>1000
    bne .fail
    jsr stack_isempty
    bcc .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "STACK_WORD", 0

; 8 KB banked FIFO ring. Bank 6.
    SUBROUTINE
test_ring
    lda #6
    jsr ring_init
    jsr ring_isempty
    bcc .fail
    lda #10
    jsr ring_put
    lda #20
    jsr ring_put
    lda #30
    jsr ring_put
    jsr ring_size
    cmp #3
    bne .fail
    cpx #0
    bne .fail
    jsr ring_get               ; FIFO: 10 comes out first
    cmp #10
    bne .fail
    jsr ring_get
    cmp #20
    bne .fail
    jsr ring_get
    cmp #30
    bne .fail
    jsr ring_isempty
    bcc .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "RING", 0

    SUBROUTINE
test_ring_word
    lda #6
    jsr ring_init
    lda #<777
    ldx #>777
    jsr ring_putw
    lda #<258
    ldx #>258
    jsr ring_putw
    jsr ring_getw              ; FIFO: 777 first
    cmp #<777
    bne .fail
    cpx #>777
    bne .fail
    jsr ring_getw
    cmp #<258
    bne .fail
    cpx #>258
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "RING_WORD", 0

; Drive the head/tail past the top of the bank to prove the wrap. Preset a
; consistent empty state near offset 8191, then queue across the boundary.
    SUBROUTINE
test_ring_wrap
    lda #6
    jsr ring_init
    lda #<8190
    sta ring_head
    lda #>8190
    sta ring_head+1
    lda #<8189
    sta ring_tail
    lda #>8189
    sta ring_tail+1
    stz ring_fill
    stz ring_fill+1
    lda #11                     ; @8190
    jsr ring_put
    lda #22                     ; @8191
    jsr ring_put
    lda #33                     ; head wrapped -> @0
    jsr ring_put
    lda #44                     ; @1
    jsr ring_put
    jsr ring_get
    cmp #11
    bne .fail
    jsr ring_get
    cmp #22
    bne .fail
    jsr ring_get               ; tail wrapped -> reads @0
    cmp #33
    bne .fail
    jsr ring_get
    cmp #44
    bne .fail
    jsr ring_isempty
    bcc .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "RING_WRAP", 0

; ---------------------------------------------------------------------
; String library. Small focused tests keep every branch to .fail in range.
    SUBROUTINE
test_str_core
    lda #<sd_hello
    ldx #>sd_hello
    jsr str_length
    cpy #5
    bne .fail
    lda #<sd_buf
    sta X16_P0
    lda #>sd_buf
    sta X16_P1
    lda #<sd_hello
    ldx #>sd_hello
    jsr str_copy
    cpy #5
    bne .fail
    lda sd_buf
    cmp #'h
    bne .fail
    lda sd_buf+4
    cmp #'o
    bne .fail
    lda sd_buf+5
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "STR_CORE", 0

    SUBROUTINE
test_str_cmp
    lda #<sd_abc2
    sta X16_P0
    lda #>sd_abc2
    sta X16_P1
    lda #<sd_abc                ; "abc" vs "abc" = 0
    ldx #>sd_abc
    jsr str_compare
    bne .fail
    lda #<sd_abd
    sta X16_P0
    lda #>sd_abd
    sta X16_P1
    lda #<sd_abc                ; "abc" vs "abd" = -1
    ldx #>sd_abc
    jsr str_compare
    cmp #$FF
    bne .fail
    lda #<sd_abc
    sta X16_P0
    lda #>sd_abc
    sta X16_P1
    lda #<sd_abd                ; "abd" vs "abc" = 1
    ldx #>sd_abd
    jsr str_compare
    cmp #1
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "STR_CMP", 0

    SUBROUTINE
test_str_edit
    lda #<sd_buf
    sta X16_P0
    lda #>sd_buf
    sta X16_P1
    lda #<sd_hello              ; buf = copy of "hello"
    ldx #>sd_hello
    jsr str_copy
    lda #<sd_bang
    sta X16_P0
    lda #>sd_bang
    sta X16_P1
    lda #<sd_buf                ; append "!!" -> "hello!!", A=7
    ldx #>sd_buf
    jsr str_append
    cmp #7
    bne .fail
    lda sd_buf+6
    cmp #'!
    bne .fail
    lda sd_buf+7
    bne .fail
    lda #<sd_hi                 ; hash("hi") = $74
    ldx #>sd_hi
    jsr str_hash
    cmp #$74
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "STR_EDIT", 0

    SUBROUTINE
test_str_ctype
    lda #'5
    jsr str_isdigit
    bcc .fail
    lda #'a
    jsr str_isdigit
    bcs .fail
    lda #'F
    jsr str_isxdigit
    bcc .fail
    lda #'g
    jsr str_isxdigit
    bcs .fail
    lda #'a                    ; PETSCII isupper: 97-122
    jsr str_isupper
    bcc .fail
    lda #'A                    ; 65 is not upper in PETSCII
    jsr str_isupper
    bcs .fail
    lda #'A                    ; but it is in ISO
    jsr str_isupper_iso
    bcc .fail
    lda #32
    jsr str_isspace
    bcc .fail
    lda #150                    ; 128-159 not printable
    jsr str_isprint
    bcs .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "STR_CTYPE", 0

    SUBROUTINE
test_str_case
    lda #'a                    ; PETSCII lowerchar('a=97) -> 65
    jsr str_lowerchar
    cmp #65
    bne .fail
    lda #'A                    ; PETSCII upperchar('A=65) -> 97
    jsr str_upperchar
    cmp #97
    bne .fail
    lda #'A                    ; ISO lowerchar('A=65) -> 97
    jsr str_lowerchar_iso
    cmp #97
    bne .fail
    lda #'a                    ; ISO upperchar('a=97) -> 65
    jsr str_upperchar_iso
    cmp #65
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "STR_CASE", 0

    SUBROUTINE
test_str_lower
    lda #<sd_buf
    sta X16_P0
    lda #>sd_buf
    sta X16_P1
    lda #<sd_HELLO             ; buf = "HELLO", then lower_iso -> "hello"
    ldx #>sd_HELLO
    jsr str_copy
    lda #<sd_buf
    ldx #>sd_buf
    jsr str_lower_iso
    lda sd_buf
    cmp #'h
    bne .fail
    lda #<sd_buf               ; upper_iso -> "HELLO"
    ldx #>sd_buf
    jsr str_upper_iso
    lda sd_buf
    cmp #'H
    bne .fail
    lda #<sd_hello
    sta X16_P0
    lda #>sd_hello
    sta X16_P1
    lda #<sd_Hello             ; compare_nocase("Hello","hello") = 0
    ldx #>sd_Hello
    jsr str_compare_nocase
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "STR_LOWER", 0

    SUBROUTINE
test_str_find
    lda #<sd_hello             ; find 'l -> index 2
    ldx #>sd_hello
    ldy #'l
    jsr str_find
    bcc .fail
    cmp #2
    bne .fail
    lda #<sd_hello             ; rfind 'l -> index 3
    ldx #>sd_hello
    ldy #'l
    jsr str_rfind
    bcc .fail
    cmp #3
    bne .fail
    lda #<sd_hello             ; find 'z -> not found
    ldx #>sd_hello
    ldy #'z
    jsr str_find
    bcs .fail
    lda #<sd_line              ; find_eol -> index 2 (the CR)
    ldx #>sd_line
    jsr str_find_eol
    bcc .fail
    cmp #2
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "STR_FIND", 0

    SUBROUTINE
test_str_pat
    lda #<sd_pat
    sta X16_P0
    lda #>sd_pat
    sta X16_P1
    lda #<sd_hello             ; "hello" matches "he*o"
    ldx #>sd_hello
    jsr str_pattern_match
    bcc .fail
    lda #<sd_patq
    sta X16_P0
    lda #>sd_patq
    sta X16_P1
    lda #<sd_hello             ; "hello" matches "h?llo"
    ldx #>sd_hello
    jsr str_pattern_match
    bcc .fail
    lda #<sd_patx
    sta X16_P0
    lda #>sd_patx
    sta X16_P1
    lda #<sd_hello             ; "hello" does NOT match "he*x"
    ldx #>sd_hello
    jsr str_pattern_match
    bcs .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "STR_PAT", 0

    SUBROUTINE
test_str_slice
    lda #<sd_buf
    sta X16_P0
    lda #>sd_buf
    sta X16_P1
    lda #<sd_hello             ; left 3 -> "hel"
    ldx #>sd_hello
    ldy #3
    jsr str_left
    lda sd_buf
    cmp #'h
    bne .fail
    lda sd_buf+2
    cmp #'l
    bne .fail
    lda sd_buf+3
    bne .fail
    lda #<sd_buf
    sta X16_P0
    lda #>sd_buf
    sta X16_P1
    lda #<sd_hello             ; right 2 -> "lo"
    ldx #>sd_hello
    ldy #2
    jsr str_right
    lda sd_buf
    cmp #'l
    bne .fail
    lda sd_buf+1
    cmp #'o
    bne .fail
    lda #<sd_buf
    sta X16_P0
    lda #>sd_buf
    sta X16_P1
    lda #1                     ; slice start 1 len 3 -> "ell"
    sta X16_P2
    lda #<sd_hello
    ldx #>sd_hello
    ldy #3
    jsr str_slice
    lda sd_buf
    cmp #'e
    bne .fail
    lda sd_buf+2
    cmp #'l
    bne .fail
    lda sd_buf+3
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "STR_SLICE", 0

    SUBROUTINE
test_str_trim
    lda #<sd_buf
    sta X16_P0
    lda #>sd_buf
    sta X16_P1
    lda #<sd_pad               ; buf = "  hi  "
    ldx #>sd_pad
    jsr str_copy
    lda #<sd_buf               ; trim both ends -> "hi"
    ldx #>sd_buf
    jsr str_trim
    lda sd_buf
    cmp #'h
    bne .fail
    lda sd_buf+1
    cmp #'i
    bne .fail
    lda sd_buf+2
    bne .fail
    lda #<sd_buf
    sta X16_P0
    lda #>sd_buf
    sta X16_P1
    lda #<sd_pad2              ; buf = "ab  "
    ldx #>sd_pad2
    jsr str_copy
    lda #<sd_buf               ; rtrim only -> "ab"
    ldx #>sd_buf
    jsr str_rtrim
    lda sd_buf+2
    bne .fail
    lda sd_buf+1
    cmp #'b
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "STR_TRIM", 0

; The xm_str_* macros expand to the same setup + jsr, so this proves they
; work and (via the 7-way hash) that they convert byte-identically.
    SUBROUTINE
test_str_sugar
    xm_str_copy sd_hello, sd_buf     ; buf = "hello"
    xm_str_upper_iso sd_buf          ; buf = "HELLO"
    lda sd_buf
    cmp #'H
    bne .fail
    xm_str_find sd_hello, 'l        ; find 'l -> index 2, carry set
    bcc .fail
    cmp #2
    bne .fail
    xm_str_pattern_match sd_hello, sd_pat   ; "hello" matches "he*o"
    bcc .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "STR_SUGAR", 0

    SUBROUTINE
sd_hello dc.b "hello", 0
    SUBROUTINE
sd_hi    dc.b "hi", 0
    SUBROUTINE
sd_bang  dc.b "!!", 0
    SUBROUTINE
sd_abc   dc.b "abc", 0
    SUBROUTINE
sd_abc2  dc.b "abc", 0
    SUBROUTINE
sd_abd   dc.b "abd", 0
    SUBROUTINE
sd_HELLO dc.b "HELLO", 0
    SUBROUTINE
sd_Hello dc.b "Hello", 0
    SUBROUTINE
sd_line  dc.b "ab", 13, "cd", 0
    SUBROUTINE
sd_pat   dc.b "he*o", 0
    SUBROUTINE
sd_patq  dc.b "h?llo", 0
    SUBROUTINE
sd_patx  dc.b "he*x", 0
    SUBROUTINE
sd_pad   dc.b "  hi  ", 0
    SUBROUTINE
sd_pad2  dc.b "ab  ", 0
    SUBROUTINE
sd_buf   ds 24, 0

    SUBROUTINE
shp_rd                          ; read (A, X), both bytes
    sta X16_P0
    stz X16_P1
    stx X16_P2
    stz X16_P3
    phy
    jsr gfx2_read
    ply
    ora #0                      ; ply set the flags from Y; re-set from A
    rts

    SUBROUTINE
shp_clear40                     ; colour 0 over (A,100)+40x40
    ldx #100
    SUBROUTINE
shp_clear40y                    ; ...or over (A,X)+40x40
    sta X16_P0
    stz X16_P1
    stx X16_P2
    stz X16_P3
    lda #40
    sta X16_P4
    stz X16_P5
    lda #40
    sta X16_P6
    stz X16_P7
    lda #0
    jmp gfx2_rect

    include "x16_code.asm"
