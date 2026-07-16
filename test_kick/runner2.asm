//ACME
// =====================================================================
// x16lib :: test/runner2.asm -- on-target regression tests, part 2
// =====================================================================
//   build.ps1 -Test            (runs every runner in sequence)
//
// The suite outgrew one PRG: runner.asm ends a few hundred bytes short
// of the $9EFF ceiling, so newer modules test here. Same rules: drive
// the library one way, verify through the independent data port.
// =====================================================================

#define T_ZP_SET
.label T_ZP = $70
#import "x16.asm"

#define X16_USE_BITMAP2  // pulls in VERA and VERAFX

// The harness's zero-page pointer (see runner.asm).

// framebuffer byte addresses the tests probe (row y starts at y*160)
.label G2R10 = 10*160
.label G2R12 = 12*160
.label G2R20 = 20*160
.label G2R21 = 21*160
.label G2R30B1 = 30*160+1
.label G2R40 = 40*160
.label G2R41B1 = 41*160+1
.label G2R42B1 = 42*160+1
.label G2R50 = 50*160
.label G2R51 = 51*160
.label G2R52 = 52*160
.label G2R60 = 60*160
.label G2R63 = 63*160
.label G2R64B1 = 64*160+1
.label G2R67B1 = 67*160+1
.label G2R70 = 70*160
.label G2R74 = 74*160
.label G2R80B2 = 80*160+2
.label G2R80 = 80*160
.label G2R81B2 = 81*160+2
.label G2R90B3 = 90*160+3

.pc = $0801 "code"
    basic_stub()

// ---------------------------------------------------------------------
main:
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
    jsr test_g2_clear
    jsr test_g2_init

    jsr t_summary
    rts

// =====================================================================
// gfx2 (640x480@2bpp): 4 pixels per byte, MSB-first, rows of 160.
// Every test paints a known background first and verifies through
// port 1, including an untouched neighbour byte. The framebuffer
// region starts at VRAM $00000; row y begins at y*160.
// =====================================================================
test_g2_pset:
    vera_addr(0, G2R10, VERA_INC_1)
    lda #$00
    ldx #8
    ldy #0
    jsr vera_fill               // row 10, bytes 0-7 = background

    stz X16_P1                  // (0,10) colour 3 -> byte 0 pixel 0
    stz X16_P0
    lda #10
    sta X16_P2
    stz X16_P3
    lda #3
    jsr gfx2_pset
    lda #5                      // (5,10) colour 2 -> byte 1 pixel 1
    sta X16_P0
    lda #2
    jsr gfx2_pset
    lda #10                     // (10,10) colour 1 -> byte 2 pixel 2
    sta X16_P0
    lda #1
    jsr gfx2_pset
    lda #15                     // (15,10) colour 3 -> byte 3 pixel 3
    sta X16_P0
    lda #3
    jsr gfx2_pset

    vera_addr(1, G2R10, VERA_INC_1)
    lda VERA_DATA1
    cmp #$C0
    bne test_g2_pset__fail_far
    lda VERA_DATA1
    cmp #$20
    bne test_g2_pset__fail_far
    lda VERA_DATA1
    cmp #$04
    bne test_g2_pset__fail_far
    lda VERA_DATA1
    cmp #$03
    bne test_g2_pset__fail_far
    lda VERA_DATA1              // byte 4: untouched background
    bne test_g2_pset__fail_far

    // the last pixel of the screen: (639,479) is byte 76,799
    vera_addr(0, 76799, VERA_INC_1)
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
    vera_addr(1, 76799, VERA_INC_1)
    lda VERA_DATA1
    cmp #$03
    bne test_g2_pset__fail_far
    bra test_g2_pset__clip

test_g2_pset__fail_far: // test_g2_pset__fail is out of branch range above
    jmp test_g2_pset__fail

test_g2_pset__clip:
    // clipping: (640,0) would land at byte 160, (0,480) at 76,800
    vera_addr(0, 160, VERA_INC_1)
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
    vera_addr(1, 160, VERA_INC_1)
    lda VERA_DATA1
    cmp #$11
    bne test_g2_pset__fail
    vera_addr(0, 76800, VERA_INC_1)
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
    vera_addr(1, 76800, VERA_INC_1)
    lda VERA_DATA1
    cmp #$22
    bne test_g2_pset__fail

    lda #0
    bra test_g2_pset__report
test_g2_pset__fail:
    lda #1
test_g2_pset__report:
    ldx #<test_g2_pset__name
    ldy #>test_g2_pset__name
    jmp t_result
test_g2_pset__name: .text "G2_PSET"
    .byte $00

// ---------------------------------------------------------------------
test_g2_read:
    vera_addr(0, G2R12, VERA_INC_1)
    lda #$1B                    // pixels 0,1,2,3 left to right
    sta VERA_DATA0

    stz X16_P0                  // walk the four pixels back out
    stz X16_P1
    lda #12
    sta X16_P2
    stz X16_P3
    jsr gfx2_read
    bcs test_g2_read__fail
    cmp #0
    bne test_g2_read__fail
    lda #1
    sta X16_P0
    jsr gfx2_read
    bcs test_g2_read__fail
    cmp #1
    bne test_g2_read__fail
    lda #2
    sta X16_P0
    jsr gfx2_read
    bcs test_g2_read__fail
    cmp #2
    bne test_g2_read__fail
    lda #3
    sta X16_P0
    jsr gfx2_read
    bcs test_g2_read__fail
    cmp #3
    bne test_g2_read__fail

    lda #<640                   // off screen reads carry set
    sta X16_P0
    lda #>640
    sta X16_P1
    jsr gfx2_read
    bcc test_g2_read__fail

    lda #0
    bra test_g2_read__report
test_g2_read__fail:
    lda #1
test_g2_read__report:
    ldx #<test_g2_read__name
    ldy #>test_g2_read__name
    jmp t_result
test_g2_read__name: .text "G2_READ"
    .byte $00

// ---------------------------------------------------------------------
// x=5 len=13 colour 3: pixels 5..17. Head = byte 1 pixels 1-3 ($3F),
// middle = bytes 2,3 ($FF), tail = byte 4 pixels 0-1 ($F0). The bytes
// either side must survive.
// ---------------------------------------------------------------------
test_g2_hline:
    vera_addr(0, G2R20, VERA_INC_1)
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

    vera_addr(1, G2R20, VERA_INC_1)
    lda VERA_DATA1              // byte 0: untouched
    bne test_g2_hline__fail
    lda VERA_DATA1
    cmp #$3F                    // head
    bne test_g2_hline__fail
    lda VERA_DATA1
    cmp #$FF                    // middle
    bne test_g2_hline__fail
    lda VERA_DATA1
    cmp #$FF
    bne test_g2_hline__fail
    lda VERA_DATA1
    cmp #$F0                    // tail
    bne test_g2_hline__fail
    lda VERA_DATA1              // byte 5: untouched
    bne test_g2_hline__fail
    lda #0
    bra test_g2_hline__report
test_g2_hline__fail:
    lda #1
test_g2_hline__report:
    ldx #<test_g2_hline__name
    ldy #>test_g2_hline__name
    jmp t_result
test_g2_hline__name: .text "G2_HLINE"
    .byte $00

// ---------------------------------------------------------------------
// a span that begins and ends inside one byte: x=1 len=2, colour 2
// ---------------------------------------------------------------------
test_g2_hline_short:
    vera_addr(0, G2R21, VERA_INC_1)
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

    vera_addr(1, G2R21, VERA_INC_1)
    lda VERA_DATA1
    cmp #$28                    // colour 2 in pixels 1,2 only
    bne test_g2_hline_short__fail
    lda VERA_DATA1              // the next byte: untouched
    bne test_g2_hline_short__fail
    lda #0
    bra test_g2_hline_short__report
test_g2_hline_short__fail:
    lda #1
test_g2_hline_short__report:
    ldx #<test_g2_hline_short__name
    ldy #>test_g2_hline_short__name
    jmp t_result
test_g2_hline_short__name: .text "G2_HLINE_SHORT"
    .byte $00

// ---------------------------------------------------------------------
// colour 0 ink onto a $FF background: proves vline really is RMW
// ---------------------------------------------------------------------
test_g2_vline:
    vera_addr(0, G2R30B1, VERA_INC_160)
    lda #$FF
    ldx #5
    ldy #0
    jsr vera_fill               // byte 1 of rows 30-34

    lda #6                      // x=6: byte 1, pixel 2
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

    vera_addr(1, G2R30B1, VERA_INC_160)
    ldx #4
test_g2_vline__check:
    lda VERA_DATA1
    cmp #$F3                    // pixel 2 cleared, the rest kept
    bne test_g2_vline__fail
    dex
    bne test_g2_vline__check
    lda VERA_DATA1              // row 34: untouched
    cmp #$FF
    bne test_g2_vline__fail
    lda #0
    bra test_g2_vline__report
test_g2_vline__fail:
    lda #1
test_g2_vline__report:
    ldx #<test_g2_vline__name
    ldy #>test_g2_vline__name
    jmp t_result
test_g2_vline__name: .text "G2_VLINE"
    .byte $00

// ---------------------------------------------------------------------
test_g2_rect:
    vera_addr(0, G2R40, VERA_INC_1)
    lda #$00
    ldx #<480
    ldy #>480
    jsr vera_fill               // rows 40-42 entirely

    lda #4                      // x=4 y=40 w=8 h=2, colour 1
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

    vera_addr(1, G2R40, VERA_INC_1)
    lda VERA_DATA1
    bne test_g2_rect__fail                   // byte 0 untouched
    lda VERA_DATA1
    cmp #$55
    bne test_g2_rect__fail
    lda VERA_DATA1
    cmp #$55
    bne test_g2_rect__fail
    lda VERA_DATA1
    bne test_g2_rect__fail                   // byte 3 untouched
    vera_addr(1, G2R41B1, VERA_INC_1)
    lda VERA_DATA1
    cmp #$55                    // second row filled too
    bne test_g2_rect__fail
    vera_addr(1, G2R42B1, VERA_INC_1)
    lda VERA_DATA1
    bne test_g2_rect__fail                   // row past the rect: untouched
    lda #0
    bra test_g2_rect__report
test_g2_rect__fail:
    lda #1
test_g2_rect__report:
    ldx #<test_g2_rect__name
    ldy #>test_g2_rect__name
    jmp t_result
test_g2_rect__name: .text "G2_RECT"
    .byte $00

// ---------------------------------------------------------------------
test_g2_frame:
    vera_addr(0, G2R50, VERA_INC_1)
    lda #$00
    ldx #<480
    ldy #>480
    jsr vera_fill               // rows 50-52

    stz X16_P0                  // x=0 y=50 w=16 h=3, colour 3
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

    vera_addr(1, G2R50, VERA_INC_1)
    ldx #4
test_g2_frame__top:
    lda VERA_DATA1              // the top edge: 16 solid pixels
    cmp #$FF
    bne test_g2_frame__fail
    dex
    bne test_g2_frame__top
    vera_addr(1, G2R51, VERA_INC_1)
    lda VERA_DATA1
    cmp #$C0                    // left edge only
    bne test_g2_frame__fail
    lda VERA_DATA1
    bne test_g2_frame__fail
    lda VERA_DATA1
    bne test_g2_frame__fail
    lda VERA_DATA1
    cmp #$03                    // right edge only
    bne test_g2_frame__fail
    vera_addr(1, G2R52, VERA_INC_1)
    lda VERA_DATA1              // the bottom edge
    cmp #$FF
    bne test_g2_frame__fail
    lda #0
    bra test_g2_frame__report
test_g2_frame__fail:
    lda #1
test_g2_frame__report:
    ldx #<test_g2_frame__name
    ldy #>test_g2_frame__name
    jmp t_result
test_g2_frame__name: .text "G2_FRAME"
    .byte $00

// ---------------------------------------------------------------------
// the 45-degree diagonal (0,60)-(7,67): pixel (i, 60+i) for every i
// ---------------------------------------------------------------------
test_g2_line:
    vera_addr(0, G2R60, VERA_INC_1)
    lda #$00
    ldx #<1280
    ldy #>1280
    jsr vera_fill               // rows 60-67

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

    vera_addr(1, G2R60, VERA_INC_1)
    lda VERA_DATA1
    cmp #$C0                    // (0,60)
    bne test_g2_line__fail
    vera_addr(1, G2R63, VERA_INC_1)
    lda VERA_DATA1
    cmp #$03                    // (3,63)
    bne test_g2_line__fail
    vera_addr(1, G2R67B1, VERA_INC_1)
    lda VERA_DATA1
    cmp #$03                    // (7,67)
    bne test_g2_line__fail
    vera_addr(1, G2R64B1, VERA_INC_1)
    lda VERA_DATA1
    cmp #$C0                    // (4,64): byte 1, pixel 0, alone
    bne test_g2_line__fail
    lda #0
    bra test_g2_line__report
test_g2_line__fail:
    lda #1
test_g2_line__report:
    ldx #<test_g2_line__name
    ldy #>test_g2_line__name
    jmp t_result
test_g2_line__name: .text "G2_LINE"
    .byte $00

// ---------------------------------------------------------------------
// pattern $F0 (left half ink): even bytes $FF, odd bytes $00
// ---------------------------------------------------------------------
test_g2_pattern:
    lda #<test_g2_pattern__pat
    ldx #>test_g2_pattern__pat
    ldy #3                      // background 0, foreground 3
    jsr gfx2_pattern_set

    vera_addr(0, G2R70, VERA_INC_1)
    lda #$55
    ldx #8
    ldy #0
    jsr vera_fill               // a non-zero background

    stz X16_P0                  // x=0 y=70 w=16 h=1
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

    vera_addr(1, G2R70, VERA_INC_1)
    lda VERA_DATA1
    cmp #$FF                    // even byte: the ink half
    bne test_g2_pattern__fail
    lda VERA_DATA1
    bne test_g2_pattern__fail                   // odd byte: the background half
    lda VERA_DATA1
    cmp #$FF
    bne test_g2_pattern__fail
    lda VERA_DATA1
    bne test_g2_pattern__fail
    lda VERA_DATA1              // byte 4: untouched background
    cmp #$55
    bne test_g2_pattern__fail
    lda #0
    bra test_g2_pattern__report
test_g2_pattern__fail:
    lda #1
test_g2_pattern__report:
    ldx #<test_g2_pattern__name
    ldy #>test_g2_pattern__name
    jmp t_result
test_g2_pattern__name: .text "G2_PATTERN"
    .byte $00
test_g2_pattern__pat: .byte $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0

// ---------------------------------------------------------------------
// the same pattern at x=2: a phase-2 head, an odd middle byte, a tail.
// Patterns anchor to the screen, not the span, so the head byte gets
// the EVEN pattern byte's pixels 2-3 and the tail the even byte again.
// ---------------------------------------------------------------------
test_g2_pattern_phase:
    lda #<test_g2_pattern_phase__pat2
    ldx #>test_g2_pattern_phase__pat2
    ldy #3
    jsr gfx2_pattern_set

    vera_addr(0, G2R74, VERA_INC_1)
    lda #$00
    ldx #4
    ldy #0
    jsr vera_fill

    lda #2                      // x=2 y=74 w=8 h=1
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

    vera_addr(1, G2R74, VERA_INC_1)
    lda VERA_DATA1
    cmp #$0F                    // head: even byte through pixels 2-3
    bne test_g2_pattern_phase__fail
    lda VERA_DATA1
    bne test_g2_pattern_phase__fail                   // middle: the odd (background) byte
    lda VERA_DATA1
    cmp #$F0                    // tail: even byte through pixels 0-1
    bne test_g2_pattern_phase__fail
    lda #0
    bra test_g2_pattern_phase__report
test_g2_pattern_phase__fail:
    lda #1
test_g2_pattern_phase__report:
    ldx #<test_g2_pattern_phase__name
    ldy #>test_g2_pattern_phase__name
    jmp t_result
test_g2_pattern_phase__name: .text "G2_PATTERN_PH"
    .byte $00
test_g2_pattern_phase__pat2: .byte $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0

// ---------------------------------------------------------------------
// blit op 0 lays the image down; blitting it again with XOR must
// return the background to zero.
// ---------------------------------------------------------------------
test_g2_blit:
    vera_addr(0, G2R80, VERA_INC_1)
    lda #$00
    ldx #<400
    ldy #>400
    jsr vera_fill               // rows 80-82 (two rows + slack)

    lda #8                      // x=8 (byte 2), y=80, 2x2 bytes
    sta X16_P0
    stz X16_P1
    lda #80
    sta X16_P2
    stz X16_P3
    lda #2
    sta X16_P4
    lda #2
    sta X16_P5
    lda #<test_g2_blit__img
    sta X16_P6
    lda #>test_g2_blit__img
    sta X16_P7
    lda #0                      // copy
    jsr gfx2_blit

    vera_addr(1, G2R80B2, VERA_INC_1)
    lda VERA_DATA1
    cmp #$DE
    bne test_g2_blit__fail_far
    lda VERA_DATA1
    cmp #$AD
    bne test_g2_blit__fail_far
    vera_addr(1, G2R81B2, VERA_INC_1)
    lda VERA_DATA1
    cmp #$BE
    bne test_g2_blit__fail_far
    lda VERA_DATA1
    cmp #$EF
    bne test_g2_blit__fail_far
    bra test_g2_blit__xor_pass

test_g2_blit__fail_far: // test_g2_blit__fail is out of branch range above
    jmp test_g2_blit__fail

test_g2_blit__xor_pass:
    lda #8                      // the same blit, XORed on top
    sta X16_P0
    stz X16_P1
    lda #80
    sta X16_P2
    stz X16_P3
    lda #2
    sta X16_P4
    lda #2
    sta X16_P5
    lda #<test_g2_blit__img
    sta X16_P6
    lda #>test_g2_blit__img
    sta X16_P7
    lda #3                      // xor
    jsr gfx2_blit

    vera_addr(1, G2R80B2, VERA_INC_1)
    lda VERA_DATA1
    bne test_g2_blit__fail
    lda VERA_DATA1
    bne test_g2_blit__fail
    vera_addr(1, G2R81B2, VERA_INC_1)
    lda VERA_DATA1
    bne test_g2_blit__fail
    lda VERA_DATA1
    bne test_g2_blit__fail
    lda #0
    bra test_g2_blit__report
test_g2_blit__fail:
    lda #1
test_g2_blit__report:
    ldx #<test_g2_blit__name
    ldy #>test_g2_blit__name
    jmp t_result
test_g2_blit__name: .text "G2_BLIT"
    .byte $00
test_g2_blit__img: .byte $DE, $AD, $BE, $EF

// ---------------------------------------------------------------------
// masked column blit onto a solid $FF background: keep pixels 2-3
// (mask $0F), ink pixels 0-1 with colour 1 (data $50) -> $5F
// ---------------------------------------------------------------------
test_g2_blitm:
    vera_addr(0, G2R90B3, VERA_INC_160)
    lda #$FF
    ldx #5
    ldy #0
    jsr vera_fill               // byte 3 of rows 90-94

    lda #12                     // x=12: byte 3, phase 0
    sta X16_P0
    stz X16_P1
    lda #90
    sta X16_P2
    stz X16_P3
    lda #4                      // 4 rows
    sta X16_P4
    lda #1                      // 1 column
    sta X16_P5
    lda #<test_g2_blitm__mcol
    sta X16_P6
    lda #>test_g2_blitm__mcol
    sta X16_P7
    jsr gfx2_blitm

    vera_addr(1, G2R90B3, VERA_INC_160)
    ldx #4
test_g2_blitm__check:
    lda VERA_DATA1
    cmp #$5F
    bne test_g2_blitm__fail
    dex
    bne test_g2_blitm__check
    lda VERA_DATA1              // row 94: untouched
    cmp #$FF
    bne test_g2_blitm__fail
    lda #0
    bra test_g2_blitm__report
test_g2_blitm__fail:
    lda #1
test_g2_blitm__report:
    ldx #<test_g2_blitm__name
    ldy #>test_g2_blitm__name
    jmp t_result
test_g2_blitm__name: .text "G2_BLITM"
    .byte $00
test_g2_blitm__mcol: .byte $0F, $50, $0F, $50, $0F, $50, $0F, $50   // (mask,data) x4

// ---------------------------------------------------------------------
// gfx2_clear floods exactly the 76,800 framebuffer bytes and nothing
// past them
// ---------------------------------------------------------------------
test_g2_clear:
    vera_addr(0, 76800, VERA_INC_1)
    lda #$77                    // sentinel one byte past the end
    sta VERA_DATA0

    lda #2
    jsr gfx2_clear

    vera_addr(1, 0, VERA_INC_1)
    lda VERA_DATA1
    cmp #$AA
    bne test_g2_clear__fail
    vera_addr(1, 38400, VERA_INC_1)
    lda VERA_DATA1              // the second fx_fill half
    cmp #$AA
    bne test_g2_clear__fail
    vera_addr(1, 76799, VERA_INC_1)
    lda VERA_DATA1              // the very last byte
    cmp #$AA
    bne test_g2_clear__fail
    lda VERA_DATA1              // ...and the sentinel after it
    cmp #$77
    bne test_g2_clear__fail
    lda #0
    bra test_g2_clear__report
test_g2_clear__fail:
    lda #1
test_g2_clear__report:
    ldx #<test_g2_clear__name
    ldy #>test_g2_clear__name
    jmp t_result
test_g2_clear__name: .text "G2_CLEAR"
    .byte $00

// ---------------------------------------------------------------------
// the mode registers land as programmed (runs last: it changes the
// display configuration and the first four palette entries)
// ---------------------------------------------------------------------
test_g2_init:
    jsr gfx2_init

    lda VERA_L0_CONFIG
    cmp #(VERA_LAYER_BITMAP | VERA_LAYER_BPP_2)
    bne test_g2_init__fail
    lda VERA_L0_TILEBASE
    cmp #$01
    bne test_g2_init__fail
    vera_dcsel(0)
    lda VERA_DC_HSCALE
    cmp #$80
    bne test_g2_init__fail
    lda VERA_DC_VSCALE
    cmp #$80
    bne test_g2_init__fail
    lda VERA_DC_VIDEO
    and #VERA_VIDEO_LAYER0_EN
    beq test_g2_init__fail
    lda VERA_DC_VIDEO
    and #VERA_VIDEO_LAYER1_EN
    bne test_g2_init__fail

    vera_addr(1, VRAM_PALETTE, VERA_INC_1)
    ldx #0
test_g2_init__pal:
    lda VERA_DATA1
    cmp test_g2_init__want,x
    bne test_g2_init__fail
    inx
    cpx #8
    bne test_g2_init__pal
    lda #0
    bra test_g2_init__report
test_g2_init__fail:
    lda #1
test_g2_init__report:
    ldx #<test_g2_init__name
    ldy #>test_g2_init__name
    jmp t_result
test_g2_init__name: .text "G2_INIT"
    .byte $00
test_g2_init__want: .byte $FF, $0F, $AA, $0A, $55, $05, $00, $00

// ---------------------------------------------------------------------
#import "testlib.asm"
#import "x16_code.asm"
