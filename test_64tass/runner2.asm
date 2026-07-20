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

.include "x16.asm"

X16_USE_BITMAP2 = 1
X16_USE_SHAPES  = 1             ; pulls in VERA and VERAFX
X16_USE_SHAPES_POLY = 1         ; + regular polygons (pulls in MATH)

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

* = $0801
    #basic_stub

; ---------------------------------------------------------------------
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
test_g2_pset
    #vera_addr 0, G2R10, VERA_INC_1
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

    #vera_addr 1, G2R10, VERA_INC_1
    lda VERA_DATA1
    cmp #$C0
    bne _fail_far
    lda VERA_DATA1
    cmp #$20
    bne _fail_far
    lda VERA_DATA1
    cmp #$04
    bne _fail_far
    lda VERA_DATA1
    cmp #$03
    bne _fail_far
    lda VERA_DATA1              ; byte 4: untouched background
    bne _fail_far

    ; the last pixel of the screen: (639,479) is byte 76,799
    #vera_addr 0, 76799, VERA_INC_1
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
    #vera_addr 1, 76799, VERA_INC_1
    lda VERA_DATA1
    cmp #$03
    bne _fail_far
    bra _clip

_fail_far                       ; _fail is out of branch range above
    jmp _fail

_clip
    ; clipping: (640,0) would land at byte 160, (0,480) at 76,800
    #vera_addr 0, 160, VERA_INC_1
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
    #vera_addr 1, 160, VERA_INC_1
    lda VERA_DATA1
    cmp #$11
    bne _fail
    #vera_addr 0, 76800, VERA_INC_1
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
    #vera_addr 1, 76800, VERA_INC_1
    lda VERA_DATA1
    cmp #$22
    bne _fail

    lda #0
    bra _report
_fail
    lda #1
_report
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "G2_PSET", $00

; ---------------------------------------------------------------------
test_g2_read
    #vera_addr 0, G2R12, VERA_INC_1
    lda #$1B                    ; pixels 0,1,2,3 left to right
    sta VERA_DATA0

    stz X16_P0                  ; walk the four pixels back out
    stz X16_P1
    lda #12
    sta X16_P2
    stz X16_P3
    jsr gfx2_read
    bcs _fail
    cmp #0
    bne _fail
    lda #1
    sta X16_P0
    jsr gfx2_read
    bcs _fail
    cmp #1
    bne _fail
    lda #2
    sta X16_P0
    jsr gfx2_read
    bcs _fail
    cmp #2
    bne _fail
    lda #3
    sta X16_P0
    jsr gfx2_read
    bcs _fail
    cmp #3
    bne _fail

    lda #<640                   ; off screen reads carry set
    sta X16_P0
    lda #>640
    sta X16_P1
    jsr gfx2_read
    bcc _fail

    lda #0
    bra _report
_fail
    lda #1
_report
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "G2_READ", $00

; ---------------------------------------------------------------------
; x=5 len=13 colour 3: pixels 5..17. Head = byte 1 pixels 1-3 ($3F),
; middle = bytes 2,3 ($FF), tail = byte 4 pixels 0-1 ($F0). The bytes
; either side must survive.
; ---------------------------------------------------------------------
test_g2_hline
    #vera_addr 0, G2R20, VERA_INC_1
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

    #vera_addr 1, G2R20, VERA_INC_1
    lda VERA_DATA1              ; byte 0: untouched
    bne _fail
    lda VERA_DATA1
    cmp #$3F                    ; head
    bne _fail
    lda VERA_DATA1
    cmp #$FF                    ; middle
    bne _fail
    lda VERA_DATA1
    cmp #$FF
    bne _fail
    lda VERA_DATA1
    cmp #$F0                    ; tail
    bne _fail
    lda VERA_DATA1              ; byte 5: untouched
    bne _fail
    lda #0
    bra _report
_fail
    lda #1
_report
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "G2_HLINE", $00

; ---------------------------------------------------------------------
; a span that begins and ends inside one byte: x=1 len=2, colour 2
; ---------------------------------------------------------------------
test_g2_hline_short
    #vera_addr 0, G2R21, VERA_INC_1
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

    #vera_addr 1, G2R21, VERA_INC_1
    lda VERA_DATA1
    cmp #$28                    ; colour 2 in pixels 1,2 only
    bne _fail
    lda VERA_DATA1              ; the next byte: untouched
    bne _fail
    lda #0
    bra _report
_fail
    lda #1
_report
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "G2_HLINE_SHORT", $00

; ---------------------------------------------------------------------
; colour 0 ink onto a $FF background: proves vline really is RMW
; ---------------------------------------------------------------------
test_g2_vline
    #vera_addr 0, G2R30B1, VERA_INC_160
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

    #vera_addr 1, G2R30B1, VERA_INC_160
    ldx #4
_check
    lda VERA_DATA1
    cmp #$F3                    ; pixel 2 cleared, the rest kept
    bne _fail
    dex
    bne _check
    lda VERA_DATA1              ; row 34: untouched
    cmp #$FF
    bne _fail
    lda #0
    bra _report
_fail
    lda #1
_report
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "G2_VLINE", $00

; ---------------------------------------------------------------------
test_g2_rect
    #vera_addr 0, G2R40, VERA_INC_1
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

    #vera_addr 1, G2R40, VERA_INC_1
    lda VERA_DATA1
    bne _fail                   ; byte 0 untouched
    lda VERA_DATA1
    cmp #$55
    bne _fail
    lda VERA_DATA1
    cmp #$55
    bne _fail
    lda VERA_DATA1
    bne _fail                   ; byte 3 untouched
    #vera_addr 1, G2R41B1, VERA_INC_1
    lda VERA_DATA1
    cmp #$55                    ; second row filled too
    bne _fail
    #vera_addr 1, G2R42B1, VERA_INC_1
    lda VERA_DATA1
    bne _fail                   ; row past the rect: untouched
    lda #0
    bra _report
_fail
    lda #1
_report
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "G2_RECT", $00

; ---------------------------------------------------------------------
test_g2_frame
    #vera_addr 0, G2R50, VERA_INC_1
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

    #vera_addr 1, G2R50, VERA_INC_1
    ldx #4
_top
    lda VERA_DATA1              ; the top edge: 16 solid pixels
    cmp #$FF
    bne _fail
    dex
    bne _top
    #vera_addr 1, G2R51, VERA_INC_1
    lda VERA_DATA1
    cmp #$C0                    ; left edge only
    bne _fail
    lda VERA_DATA1
    bne _fail
    lda VERA_DATA1
    bne _fail
    lda VERA_DATA1
    cmp #$03                    ; right edge only
    bne _fail
    #vera_addr 1, G2R52, VERA_INC_1
    lda VERA_DATA1              ; the bottom edge
    cmp #$FF
    bne _fail
    lda #0
    bra _report
_fail
    lda #1
_report
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "G2_FRAME", $00

; ---------------------------------------------------------------------
; the 45-degree diagonal (0,60)-(7,67): pixel (i, 60+i) for every i
; ---------------------------------------------------------------------
test_g2_line
    #vera_addr 0, G2R60, VERA_INC_1
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

    #vera_addr 1, G2R60, VERA_INC_1
    lda VERA_DATA1
    cmp #$C0                    ; (0,60)
    bne _fail
    #vera_addr 1, G2R63, VERA_INC_1
    lda VERA_DATA1
    cmp #$03                    ; (3,63)
    bne _fail
    #vera_addr 1, G2R67B1, VERA_INC_1
    lda VERA_DATA1
    cmp #$03                    ; (7,67)
    bne _fail
    #vera_addr 1, G2R64B1, VERA_INC_1
    lda VERA_DATA1
    cmp #$C0                    ; (4,64): byte 1, pixel 0, alone
    bne _fail
    lda #0
    bra _report
_fail
    lda #1
_report
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "G2_LINE", $00

; ---------------------------------------------------------------------
; pattern $F0 (left half ink): even bytes $FF, odd bytes $00
; ---------------------------------------------------------------------
test_g2_pattern
    lda #<_pat
    ldx #>_pat
    ldy #3                      ; background 0, foreground 3
    jsr gfx2_pattern_set

    #vera_addr 0, G2R70, VERA_INC_1
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

    #vera_addr 1, G2R70, VERA_INC_1
    lda VERA_DATA1
    cmp #$FF                    ; even byte: the ink half
    bne _fail
    lda VERA_DATA1
    bne _fail                   ; odd byte: the background half
    lda VERA_DATA1
    cmp #$FF
    bne _fail
    lda VERA_DATA1
    bne _fail
    lda VERA_DATA1              ; byte 4: untouched background
    cmp #$55
    bne _fail
    lda #0
    bra _report
_fail
    lda #1
_report
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "G2_PATTERN", $00
_pat .byte $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0

; ---------------------------------------------------------------------
; the same pattern at x=2: a phase-2 head, an odd middle byte, a tail.
; Patterns anchor to the screen, not the span, so the head byte gets
; the EVEN pattern byte's pixels 2-3 and the tail the even byte again.
; ---------------------------------------------------------------------
test_g2_pattern_phase
    lda #<_pat2
    ldx #>_pat2
    ldy #3
    jsr gfx2_pattern_set

    #vera_addr 0, G2R74, VERA_INC_1
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

    #vera_addr 1, G2R74, VERA_INC_1
    lda VERA_DATA1
    cmp #$0F                    ; head: even byte through pixels 2-3
    bne _fail
    lda VERA_DATA1
    bne _fail                   ; middle: the odd (background) byte
    lda VERA_DATA1
    cmp #$F0                    ; tail: even byte through pixels 0-1
    bne _fail
    lda #0
    bra _report
_fail
    lda #1
_report
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "G2_PATTERN_PH", $00
_pat2 .byte $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0

; ---------------------------------------------------------------------
; blit op 0 lays the image down; blitting it again with XOR must
; return the background to zero.
; ---------------------------------------------------------------------
test_g2_blit
    #vera_addr 0, G2R80, VERA_INC_1
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
    lda #<_img
    sta X16_P6
    lda #>_img
    sta X16_P7
    lda #0                      ; copy
    jsr gfx2_blit

    #vera_addr 1, G2R80B2, VERA_INC_1
    lda VERA_DATA1
    cmp #$DE
    bne _fail_far
    lda VERA_DATA1
    cmp #$AD
    bne _fail_far
    #vera_addr 1, G2R81B2, VERA_INC_1
    lda VERA_DATA1
    cmp #$BE
    bne _fail_far
    lda VERA_DATA1
    cmp #$EF
    bne _fail_far
    bra _xor_pass

_fail_far                       ; _fail is out of branch range above
    jmp _fail

_xor_pass
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
    lda #<_img
    sta X16_P6
    lda #>_img
    sta X16_P7
    lda #3                      ; xor
    jsr gfx2_blit

    #vera_addr 1, G2R80B2, VERA_INC_1
    lda VERA_DATA1
    bne _fail
    lda VERA_DATA1
    bne _fail
    #vera_addr 1, G2R81B2, VERA_INC_1
    lda VERA_DATA1
    bne _fail
    lda VERA_DATA1
    bne _fail
    lda #0
    bra _report
_fail
    lda #1
_report
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "G2_BLIT", $00
_img .byte $DE, $AD, $BE, $EF

; ---------------------------------------------------------------------
; masked column blit onto a solid $FF background: keep pixels 2-3
; (mask $0F), ink pixels 0-1 with colour 1 (data $50) -> $5F
; ---------------------------------------------------------------------
test_g2_blitm
    #vera_addr 0, G2R90B3, VERA_INC_160
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
    lda #<_mcol
    sta X16_P6
    lda #>_mcol
    sta X16_P7
    jsr gfx2_blitm

    #vera_addr 1, G2R90B3, VERA_INC_160
    ldx #4
_check
    lda VERA_DATA1
    cmp #$5F
    bne _fail
    dex
    bne _check
    lda VERA_DATA1              ; row 94: untouched
    cmp #$FF
    bne _fail
    lda #0
    bra _report
_fail
    lda #1
_report
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "G2_BLITM", $00
_mcol .byte $0F, $50, $0F, $50, $0F, $50, $0F, $50   ; (mask,data) x4

; ---------------------------------------------------------------------
; gfx2_clear floods exactly the 76,800 framebuffer bytes and nothing
; past them
; ---------------------------------------------------------------------
test_g2_clear
    #vera_addr 0, 76800, VERA_INC_1
    lda #$77                    ; sentinel one byte past the end
    sta VERA_DATA0

    lda #2
    jsr gfx2_clear

    #vera_addr 1, 0, VERA_INC_1
    lda VERA_DATA1
    cmp #$AA
    bne _fail
    #vera_addr 1, 38400, VERA_INC_1
    lda VERA_DATA1              ; the second fx_fill half
    cmp #$AA
    bne _fail
    #vera_addr 1, 76799, VERA_INC_1
    lda VERA_DATA1              ; the very last byte
    cmp #$AA
    bne _fail
    lda VERA_DATA1              ; ...and the sentinel after it
    cmp #$77
    bne _fail
    lda #0
    bra _report
_fail
    lda #1
_report
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "G2_CLEAR", $00

; ---------------------------------------------------------------------
; the mode registers land as programmed (runs last: it changes the
; display configuration and the first four palette entries)
; ---------------------------------------------------------------------
test_g2_init
    jsr gfx2_init

    lda VERA_L0_CONFIG
    cmp #(VERA_LAYER_BITMAP | VERA_LAYER_BPP_2)
    bne _fail
    lda VERA_L0_TILEBASE
    cmp #$01
    bne _fail
    #vera_dcsel 0
    lda VERA_DC_HSCALE
    cmp #$80
    bne _fail
    lda VERA_DC_VSCALE
    cmp #$80
    bne _fail
    lda VERA_DC_VIDEO
    and #VERA_VIDEO_LAYER0_EN
    beq _fail
    lda VERA_DC_VIDEO
    and #VERA_VIDEO_LAYER1_EN
    bne _fail

    #vera_addr 1, VRAM_PALETTE, VERA_INC_1
    ldx #0
_pal
    lda VERA_DATA1
    cmp _want,x
    bne _fail
    inx
    cpx #8
    bne _pal
    lda #0
    bra _report
_fail
    lda #1
_report
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "G2_INIT", $00
_want .byte $FF, $0F, $AA, $0A, $55, $05, $00, $00

; ---------------------------------------------------------------------
.include "testlib.asm"

; SHAPE_CIRC: a midpoint circle's cardinal points land at exactly r
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
    bne _report
    lda #105                    ; west
    ldx #120
    jsr shp_rd
    cmp #3
    bne _report
    lda #120                    ; south
    ldx #135
    jsr shp_rd
    cmp #3
    bne _report
    lda #120                    ; centre stays clear: an outline
    ldx #120
    jsr shp_rd
    bne _report
    ldy #0
_report
    tya
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "SHAPE_CIRC", 0

; SHAPE_DISC: filled to the rim, clear past it
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
    bne _report
    lda #210                    ; the rim
    ldx #120
    jsr shp_rd
    cmp #2
    bne _report
    lda #200                    ; two past the rim, straight down
    ldx #132
    jsr shp_rd
    bne _report
    ldy #0
_report
    tya
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "SHAPE_DISC", 0

; SHAPE_ELLIP: the outline's cardinal points land at exactly rx / ry
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
    bne _report
    lda #105                    ; west
    ldx #120
    jsr shp_rd
    cmp #3
    bne _report
    lda #120                    ; south
    ldx #128
    jsr shp_rd
    cmp #3
    bne _report
    lda #120                    ; one past the south pole: clear
    ldx #129
    jsr shp_rd
    bne _report
    lda #120                    ; centre stays clear: an outline
    ldx #120
    jsr shp_rd
    bne _report
    ldy #0
_report
    tya
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "SHAPE_ELLIP", 0

; SHAPE_FELLIP: filled to both rims, clear past them
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
    bne _report
    lda #212                    ; the east rim
    ldx #120
    jsr shp_rd
    cmp #2
    bne _report
    lda #213                    ; one past it
    ldx #120
    jsr shp_rd
    bne _report
    lda #200                    ; the north rim
    ldx #111
    jsr shp_rd
    cmp #2
    bne _report
    lda #200                    ; one past it
    ldx #110
    jsr shp_rd
    bne _report
    ldy #0
_report
    tya
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "SHAPE_FELLIP", 0

; SHAPE_FLOOD: fills a framed box, stops at the frame
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
    bcs _report                 ; the stack must not overflow here
    lda #80                     ; inside: filled
    ldx #170
    jsr shp_rd
    cmp #1
    bne _report
    lda #71                     ; the top-left inside corner: filled
    ldx #161
    jsr shp_rd
    cmp #1
    bne _report
    lda #88                     ; the bottom-right corner: filled (the fill
    ldx #178                    ; must reach DOWN from the seed, not just up)
    jsr shp_rd
    cmp #1
    bne _report
    lda #70                     ; the fence itself: intact
    ldx #160
    jsr shp_rd
    cmp #3
    bne _report
    lda #60                     ; outside: untouched
    ldx #155
    jsr shp_rd
    bne _report
    ldy #0
_report
    tya
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "SHAPE_FLOOD", 0

; SHAPE_POLYGON: a diamond (4-gon, rotation 0) -- outline, then filled
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
    bne _report
    lda #120                    ; the north vertex
    ldx #110
    jsr shp_rd
    cmp #3
    bne _report
    lda #120                    ; centre: an outline leaves it clear
    ldx #120
    jsr shp_rd
    bne _report

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
    bne _report
    lda #180                    ; interior, four rows up
    ldx #116
    jsr shp_rd
    cmp #2
    bne _report
    lda #180                    ; above the north vertex: clear
    ldx #103
    jsr shp_rd
    bne _report
    ldy #0
_report
    tya
    ldx #<_name
    ldy #>_name
    jmp t_result
_name .text "SHAPE_POLYGON", 0

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

shp_clear40                     ; colour 0 over (A,100)+40x40
    ldx #100
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

.include "x16_code.asm"
