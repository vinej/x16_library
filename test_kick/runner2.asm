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

#define X16_USE_BITMAP2H
#define X16_USE_SHAPES  // pulls in VERA and VERAFX
#define X16_USE_SHAPES_POLY  // + regular polygons (pulls in MATH)
#define X16_USE_SHAPES_RRECT  // + rounded rectangles
#define X16_USE_SHAPES_ARC  // + arcs (pulls MATH + SHP_LINE)
#define X16_USE_SHAPES_PIE  // + filled pies (pulls SHAPES_ARC)
#define X16_USE_SHAPES_BEZIER  // + cubic Bezier curves (pulls SHP_LINE)
#define X16_USE_COLLIDE  // for the xm_collide16 macro test
#define X16_USE_BCD  // packed-BCD decimal add/subtract
#define X16_USE_STACK  // 8 KB LIFO stack in a HIRAM bank
#define X16_USE_RINGBUFFER  // 8 KB FIFO ring in a HIRAM bank
#define X16_USE_STRING  // string fundamentals
#define X16_USE_STRING_CTYPE  // character classification
#define X16_USE_STRING_CASE  // case folding
#define X16_USE_STRING_FIND  // searching
#define X16_USE_STRING_SLICE  // substrings
#define X16_USE_STRING_SORT  // sort an array of string pointers
#define X16_USE_SCREEN_EXTRA  // screen_addr / screen_scode / screen_blit
#define X16_USE_SPRITE  // sprite_get_pos' signed round trip
#define X16_USE_LOAD  // fs_save, to lay down a file to find
#define X16_USE_DOS  // mkdir/chdir around the directory tests
#define X16_USE_DIR  // reading a directory listing
#define X16_USE_BMX  // bmx_lasterr: the code behind the carry

#import "core/sugar.asm"        // optional friendly xm_* macros (gated; tested below)

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
    jsr test_str_sort
    jsr test_str_sugar
    jsr test_screen_scode
    jsr test_screen_addr
    jsr test_screen_blit
    jsr test_screen_scroll
    jsr test_g2_clear
    jsr test_g2_init
    jsr test_bmx_lasterr
    jsr test_dir_reads
    jsr test_dir_chdir
    jsr test_str_petscii_class
    jsr test_str_case_hibyte
    jsr test_str_append_self
    jsr test_ring_full_edge
    jsr test_shape_r0
    jsr test_sprite_pos_signed
    jsr test_str_pat_edge
    jsr test_word_underflow

    jsr t_summary
    rts

// =====================================================================
// video/screen -- direct text-map access.
//
// screen_addr is checked for its arithmetic rather than against a
// hard-coded VRAM layout, so the test survives a ROM that moves the map:
// one column is two bytes, one row is the stride L1_CONFIG advertises,
// the increment nibble is 1, and ADDRSEL is left at 0. The blits are
// then verified by reading the map back through the independent port 1.
// =====================================================================
test_screen_scode:
    lda #$41                    // 'a' unshifted -> 1
    jsr screen_scode
    cmp #$01
    bne test_screen_scode__fail
    lda #$C1                    // 'A' shifted   -> $41
    jsr screen_scode
    cmp #$41
    bne test_screen_scode__fail
    lda #$30                    // '0'           -> unchanged
    jsr screen_scode
    cmp #$30
    bne test_screen_scode__fail
    lda #$20                    // space         -> unchanged
    jsr screen_scode
    cmp #$20
    bne test_screen_scode__fail
    lda #$00
    jsr screen_scode
    cmp #$80
    bne test_screen_scode__fail
    lda #$60
    jsr screen_scode
    cmp #$40
    bne test_screen_scode__fail
    lda #$80
    jsr screen_scode
    cmp #$C0
    bne test_screen_scode__fail
    lda #$A0
    jsr screen_scode
    cmp #$60
    bne test_screen_scode__fail
    lda #$FF
    jsr screen_scode
    cmp #$7F
    bne test_screen_scode__fail

    lda #0
    bra test_screen_scode__report
test_screen_scode__fail:
    lda #1
test_screen_scode__report:
    ldx #<test_screen_scode__name
    ldy #>test_screen_scode__name
    jmp t_result
test_screen_scode__name: .text "SCREEN_SCODE"
    .byte $00

// ---------------------------------------------------------------------
test_screen_addr:
    ldx #0                      // (0,0)
    ldy #0
    jsr screen_addr
    lda VERA_ADDR_L
    sta X16_P4
    lda VERA_ADDR_M
    sta X16_P5
    lda VERA_ADDR_H
    and #$F0
    cmp #$10                    // increment must be 1
    bne test_screen_addr__fail
    lda VERA_CTRL
    and #$01                    // ...and port 0 still selected
    bne test_screen_addr__fail

    ldy #1                      // (0,1): one column on = two bytes
    ldx #0
    jsr screen_addr
    sec
    lda VERA_ADDR_L
    sbc X16_P4
    sta X16_P6
    lda VERA_ADDR_M
    sbc X16_P5
    ora X16_P6
    cmp #2
    bne test_screen_addr__fail

    ldx #1                      // (1,0): one row on = one stride
    ldy #0
    jsr screen_addr
    sec
    lda VERA_ADDR_L
    sbc X16_P4
    sta X16_P6
    lda VERA_ADDR_M
    sbc X16_P5
    sta X16_P7

    lda VERA_L1_CONFIG          // expected stride, straight from the spec
    lsr
    lsr
    lsr
    lsr
    and #3
    tax
    lda test_screen_addr__stride_lo,x
    cmp X16_P6
    bne test_screen_addr__fail
    lda test_screen_addr__stride_hi,x
    cmp X16_P7
    bne test_screen_addr__fail

    lda #0
    bra test_screen_addr__report
test_screen_addr__fail:
    lda #1
test_screen_addr__report:
    ldx #<test_screen_addr__name
    ldy #>test_screen_addr__name
    jmp t_result
test_screen_addr__stride_lo: .byte <64, <128, <256, <512
test_screen_addr__stride_hi: .byte >64, >128, >256, >512
test_screen_addr__name: .text "SCREEN_ADDR"
    .byte $00

// ---------------------------------------------------------------------
test_screen_blit:
    ldx #50                     // well below the harness's own output
    ldy #0
    jsr screen_addr
    lda VERA_ADDR_L
    sta X16_P4
    lda VERA_ADDR_M
    sta X16_P5
    lda VERA_ADDR_H
    sta X16_P6

    lda #<test_screen_blit__text
    sta X16_P0
    lda #>test_screen_blit__text
    sta X16_P1
    lda #3
    ldx #$61                    // fg 1, bg 6
    jsr screen_blit

    lda #2                      // then two spaces in a different colour
    ldx #$25
    ldy #$20
    jsr screen_blitfill

    vera_addrsel(1)  // read the map back through port 1
    lda X16_P4
    sta VERA_ADDR_L
    lda X16_P5
    sta VERA_ADDR_M
    lda X16_P6
    sta VERA_ADDR_H

    lda VERA_DATA1
    cmp #$01                    // 'a'
    bne test_screen_blit__fail
    lda VERA_DATA1
    cmp #$61
    bne test_screen_blit__fail
    lda VERA_DATA1
    cmp #$42                    // 'B'
    bne test_screen_blit__fail
    lda VERA_DATA1
    cmp #$61
    bne test_screen_blit__fail
    lda VERA_DATA1
    cmp #$30                    // '0'
    bne test_screen_blit__fail
    lda VERA_DATA1
    cmp #$61
    bne test_screen_blit__fail
    lda VERA_DATA1
    cmp #$20                    // the fill
    bne test_screen_blit__fail
    lda VERA_DATA1
    cmp #$25
    bne test_screen_blit__fail
    lda VERA_DATA1
    cmp #$20
    bne test_screen_blit__fail
    lda VERA_DATA1
    cmp #$25
    bne test_screen_blit__fail

    lda #0
    bra test_screen_blit__report
test_screen_blit__fail:
    lda #1
test_screen_blit__report:
    pha                         // +vera_addrsel clobbers A; the verdict
    vera_addrsel(0)  // has to survive it
    pla
    ldx #<test_screen_blit__name
    ldy #>test_screen_blit__name
    jmp t_result
test_screen_blit__text: .byte $41, $C2, $30       // 'a', 'B', '0' in PETSCII
test_screen_blit__name: .text "SCREEN_BLIT"
    .byte $00

// ---------------------------------------------------------------------
// screen_scroll: write three marker rows, slide them, and check that the
// picture moved and that the row it left behind was not touched.
test_screen_scroll:
    ldx #40                     // row 40 = "1", 41 = "2", 42 = "3"
    ldy #0
    jsr screen_addr
    lda #1
    ldx #$61
    ldy #$31
    jsr screen_blitfill
    ldx #41
    ldy #0
    jsr screen_addr
    lda #1
    ldx #$61
    ldy #$32
    jsr screen_blitfill
    ldx #42
    ldy #0
    jsr screen_addr
    lda #1
    ldx #$61
    ldy #$33
    jsr screen_blitfill

    lda #40                     // move rows 40..42 up by one
    sta X16_P0
    stz X16_P1
    lda #3
    sta X16_P2
    lda #1
    sta X16_P3
    sta X16_P4
    lda #0                      // up
    jsr screen_scroll

    ldx #40                     // row 40 now holds what row 41 had
    ldy #0
    jsr screen_addr1
    lda VERA_DATA1
    cmp #$32
    bne test_screen_scroll__fail
    ldx #41
    ldy #0
    jsr screen_addr1
    lda VERA_DATA1
    cmp #$33
    bne test_screen_scroll__fail
    ldx #42                     // the vacated row is left alone
    ldy #0
    jsr screen_addr1
    lda VERA_DATA1
    cmp #$33
    bne test_screen_scroll__fail

    lda #40                     // and back down again
    sta X16_P0
    stz X16_P1
    lda #3
    sta X16_P2
    lda #1
    sta X16_P3
    sta X16_P4
    lda #1                      // down
    jsr screen_scroll
    ldx #41
    ldy #0
    jsr screen_addr1
    lda VERA_DATA1
    cmp #$32
    bne test_screen_scroll__fail

    lda #40                     // a distance that leaves nothing does nothing
    sta X16_P0
    stz X16_P1
    lda #3
    sta X16_P2
    lda #1
    sta X16_P3
    lda #3
    sta X16_P4
    lda #0
    jsr screen_scroll
    ldx #41
    ldy #0
    jsr screen_addr1
    lda VERA_DATA1
    cmp #$32
    bne test_screen_scroll__fail

    lda #0
    bra test_screen_scroll__report
test_screen_scroll__fail:
    lda #1
test_screen_scroll__report:
    pha
    vera_addrsel(0)
    pla
    ldx #<test_screen_scroll__name
    ldy #>test_screen_scroll__name
    jmp t_result
test_screen_scroll__name: .text "SCREEN_SCROLL"
    .byte $00

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
    jsr gfx2h_pset
    lda #5                      // (5,10) colour 2 -> byte 1 pixel 1
    sta X16_P0
    lda #2
    jsr gfx2h_pset
    lda #10                     // (10,10) colour 1 -> byte 2 pixel 2
    sta X16_P0
    lda #1
    jsr gfx2h_pset
    lda #15                     // (15,10) colour 3 -> byte 3 pixel 3
    sta X16_P0
    lda #3
    jsr gfx2h_pset

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
    jsr gfx2h_pset
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
    jsr gfx2h_pset
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
    jsr gfx2h_pset
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
    jsr gfx2h_read
    bcs test_g2_read__fail
    cmp #0
    bne test_g2_read__fail
    lda #1
    sta X16_P0
    jsr gfx2h_read
    bcs test_g2_read__fail
    cmp #1
    bne test_g2_read__fail
    lda #2
    sta X16_P0
    jsr gfx2h_read
    bcs test_g2_read__fail
    cmp #2
    bne test_g2_read__fail
    lda #3
    sta X16_P0
    jsr gfx2h_read
    bcs test_g2_read__fail
    cmp #3
    bne test_g2_read__fail

    lda #<640                   // off screen reads carry set
    sta X16_P0
    lda #>640
    sta X16_P1
    jsr gfx2h_read
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
    jsr gfx2h_hline

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
    jsr gfx2h_hline

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
    jsr gfx2h_vline

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
    jsr gfx2h_rect

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
    jsr gfx2h_frame

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
    jsr gfx2h_line

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
    jsr gfx2h_pattern_set

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
    jsr gfx2h_pattern_rect

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
    jsr gfx2h_pattern_set

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
    jsr gfx2h_pattern_rect

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
    jsr gfx2h_blit

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
    jsr gfx2h_blit

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
    jsr gfx2h_blitm

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
// gfx2h_clear floods exactly the 76,800 framebuffer bytes and nothing
// past them
// ---------------------------------------------------------------------
test_g2_clear:
    vera_addr(0, 76800, VERA_INC_1)
    lda #$77                    // sentinel one byte past the end
    sta VERA_DATA0

    lda #2
    jsr gfx2h_clear

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
    jsr gfx2h_init

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

// SHAPE_CIRC: a midpoint circle's cardinal points land at exactly r
test_shape_circle:
    lda #100
    jsr shp_clear40             // a clean 40x40 patch at (100,100)
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
    lda #135                    // east
    ldx #120
    jsr shp_rd
    cmp #3
    bne test_shape_circle__report
    lda #105                    // west
    ldx #120
    jsr shp_rd
    cmp #3
    bne test_shape_circle__report
    lda #120                    // south
    ldx #135
    jsr shp_rd
    cmp #3
    bne test_shape_circle__report
    lda #120                    // centre stays clear: an outline
    ldx #120
    jsr shp_rd
    bne test_shape_circle__report
    ldy #0
test_shape_circle__report:
    tya
    ldx #<test_shape_circle__name
    ldy #>test_shape_circle__name
    jmp t_result
test_shape_circle__name: .text "SHAPE_CIRC"
    .byte 0

// SHAPE_DISC: filled to the rim, clear past it
test_shape_disc:
    lda #180
    jsr shp_clear40             // a clean patch at (180,100)
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
    lda #200                    // centre
    ldx #120
    jsr shp_rd
    cmp #2
    bne test_shape_disc__report
    lda #210                    // the rim
    ldx #120
    jsr shp_rd
    cmp #2
    bne test_shape_disc__report
    lda #200                    // two past the rim, straight down
    ldx #132
    jsr shp_rd
    bne test_shape_disc__report
    ldy #0
test_shape_disc__report:
    tya
    ldx #<test_shape_disc__name
    ldy #>test_shape_disc__name
    jmp t_result
test_shape_disc__name: .text "SHAPE_DISC"
    .byte 0

// SHAPE_ELLIP: the outline's cardinal points land at exactly rx / ry
test_shape_ellipse:
    lda #100
    jsr shp_clear40             // a clean 40x40 patch at (100,100)
    lda #120
    sta X16_P0
    stz X16_P1
    lda #120
    sta X16_P2
    stz X16_P3
    lda #15                     // rx = 15, ry = 8
    sta X16_P4
    lda #8
    sta X16_P5
    lda #3
    jsr shape_ellipse
    ldy #1
    lda #135                    // east
    ldx #120
    jsr shp_rd
    cmp #3
    bne test_shape_ellipse__report
    lda #105                    // west
    ldx #120
    jsr shp_rd
    cmp #3
    bne test_shape_ellipse__report
    lda #120                    // south
    ldx #128
    jsr shp_rd
    cmp #3
    bne test_shape_ellipse__report
    lda #120                    // one past the south pole: clear
    ldx #129
    jsr shp_rd
    bne test_shape_ellipse__report
    lda #120                    // centre stays clear: an outline
    ldx #120
    jsr shp_rd
    bne test_shape_ellipse__report
    ldy #0
test_shape_ellipse__report:
    tya
    ldx #<test_shape_ellipse__name
    ldy #>test_shape_ellipse__name
    jmp t_result
test_shape_ellipse__name: .text "SHAPE_ELLIP"
    .byte 0

// SHAPE_FELLIP: filled to both rims, clear past them
test_shape_fellipse:
    lda #180
    jsr shp_clear40             // a clean patch at (180,100)
    lda #200
    sta X16_P0
    stz X16_P1
    lda #120
    sta X16_P2
    stz X16_P3
    lda #12                     // rx = 12, ry = 9
    sta X16_P4
    lda #9
    sta X16_P5
    lda #2
    jsr shape_fellipse
    ldy #1
    lda #200                    // centre
    ldx #120
    jsr shp_rd
    cmp #2
    bne test_shape_fellipse__report
    lda #212                    // the east rim
    ldx #120
    jsr shp_rd
    cmp #2
    bne test_shape_fellipse__report
    lda #213                    // one past it
    ldx #120
    jsr shp_rd
    bne test_shape_fellipse__report
    lda #200                    // the north rim
    ldx #111
    jsr shp_rd
    cmp #2
    bne test_shape_fellipse__report
    lda #200                    // one past it
    ldx #110
    jsr shp_rd
    bne test_shape_fellipse__report
    ldy #0
test_shape_fellipse__report:
    tya
    ldx #<test_shape_fellipse__name
    ldy #>test_shape_fellipse__name
    jmp t_result
test_shape_fellipse__name: .text "SHAPE_FELLIP"
    .byte 0

// SHAPE_FLOOD: fills a framed box, stops at the frame
test_shape_flood:
    lda #55
    ldx #150
    jsr shp_clear40y            // a clean patch at (55,150)
    lda #70                     // the fence: a 20x20 frame, colour 3
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
    jsr gfx2h_frame
    lda #80                     // flood from inside, colour 1
    sta X16_P0
    stz X16_P1
    lda #170
    sta X16_P2
    stz X16_P3
    lda #1
    jsr shape_flood
    ldy #1
    bcs test_shape_flood__report                 // the stack must not overflow here
    lda #80                     // inside: filled
    ldx #170
    jsr shp_rd
    cmp #1
    bne test_shape_flood__report
    lda #71                     // the top-left inside corner: filled
    ldx #161
    jsr shp_rd
    cmp #1
    bne test_shape_flood__report
    lda #88                     // the bottom-right corner: filled (the fill
    ldx #178                    // must reach DOWN from the seed, not just up)
    jsr shp_rd
    cmp #1
    bne test_shape_flood__report
    lda #70                     // the fence itself: intact
    ldx #160
    jsr shp_rd
    cmp #3
    bne test_shape_flood__report
    lda #60                     // outside: untouched
    ldx #155
    jsr shp_rd
    bne test_shape_flood__report
    ldy #0
test_shape_flood__report:
    tya
    ldx #<test_shape_flood__name
    ldy #>test_shape_flood__name
    jmp t_result
test_shape_flood__name: .text "SHAPE_FLOOD"
    .byte 0

// SHAPE_POLYGON: a diamond (4-gon, rotation 0) -- outline, then filled
test_shape_polygon:
    lda #100
    jsr shp_clear40             // a clean patch at (100,100)
    lda #120                    // outline at (120,120), r=10, colour 3
    sta X16_P0
    stz X16_P1
    lda #120
    sta X16_P2
    stz X16_P3
    lda #10
    sta X16_P4                  // radius
    lda #4
    sta X16_P5                  // sides
    lda #0
    sta X16_P6                  // rotation: vertices at E, S, W, N
    lda #3
    jsr shape_polygon
    ldy #1
    lda #130                    // the east vertex
    ldx #120
    jsr shp_rd
    cmp #3
    bne test_shape_polygon__report
    lda #120                    // the north vertex
    ldx #110
    jsr shp_rd
    cmp #3
    bne test_shape_polygon__report
    lda #120                    // centre: an outline leaves it clear
    ldx #120
    jsr shp_rd
    bne test_shape_polygon__report

    lda #160
    jsr shp_clear40             // a clean patch at (160,100)
    lda #180                    // filled at (180,120), r=10, colour 2
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
    lda #180                    // centre: filled
    ldx #120
    jsr shp_rd
    cmp #2
    bne test_shape_polygon__report
    lda #180                    // interior, four rows up
    ldx #116
    jsr shp_rd
    cmp #2
    bne test_shape_polygon__report
    lda #180                    // above the north vertex: clear
    ldx #103
    jsr shp_rd
    bne test_shape_polygon__report
    ldy #0
test_shape_polygon__report:
    tya
    ldx #<test_shape_polygon__name
    ldy #>test_shape_polygon__name
    jmp t_result
test_shape_polygon__name: .text "SHAPE_POLYGON"
    .byte 0

test_shape_rrect:
    lda #200                    // clean patch at (200,100)
    ldx #100
    jsr shp_clear40y
    lda #200                    // outline rrect (200,100) 40x30 r=8 colour 3
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
    lda #220                    // top edge, mid: set
    ldx #100
    jsr shp_rd
    cmp #3
    bne test_shape_rrect__report
    lda #200                    // sharp corner: cut away, clear
    ldx #100
    jsr shp_rd
    bne test_shape_rrect__report
    lda #200                    // left edge, mid height: set
    ldx #115
    jsr shp_rd
    cmp #3
    bne test_shape_rrect__report
    lda #220                    // centre: outline leaves it clear
    ldx #115
    jsr shp_rd
    bne test_shape_rrect__report

    lda #40                     // clean patch at (40,160)
    ldx #160
    jsr shp_clear40y
    lda #40                     // filled rrect (40,160) 40x30 r=8 colour 2
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
    lda #60                     // centre: filled
    ldx #175
    jsr shp_rd
    cmp #2
    bne test_shape_rrect__report
    lda #40                     // sharp corner: cut away, clear
    ldx #160
    jsr shp_rd
    bne test_shape_rrect__report
    lda #60                     // top flat edge: filled
    ldx #160
    jsr shp_rd
    cmp #2
    bne test_shape_rrect__report
    lda #40                     // left edge at mid height: filled to x0
    ldx #175
    jsr shp_rd
    cmp #2
    bne test_shape_rrect__report
    ldy #0
test_shape_rrect__report:
    tya
    ldx #<test_shape_rrect__name
    ldy #>test_shape_rrect__name
    jmp t_result
test_shape_rrect__name: .text "SHAPE_RRECT"
    .byte 0

// A stadium: r = h/2, so the straight vertical sides vanish. Guards the
// regression where the empty side-run wrapped 16-bit and painted the whole
// x0/x1 columns top to bottom.
test_shape_stadium:
    lda #40                     // clear the column both above and over the shape
    ldx #120
    jsr shp_clear40y
    lda #40
    ldx #160
    jsr shp_clear40y
    lda #40                     // outline stadium (40,160) 60x40, r=20 = h/2
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
    lda #40                     // column x0, 20 rows above the shape: MUST be clear
    ldx #140
    jsr shp_rd
    beq test_shape_stadium__cont
test_shape_stadium__rep:
    jmp test_shape_stadium__report
test_shape_stadium__cont:
    lda #40                     // leftmost point of the left semicircle: set
    ldx #180
    jsr shp_rd
    cmp #3
    bne test_shape_stadium__rep
    lda #70                     // top straight edge between the ends: set
    ldx #160
    jsr shp_rd
    cmp #3
    bne test_shape_stadium__rep

    lda #40                     // clean patch for a filled stadium
    ldx #220
    jsr shp_clear40y
    lda #40                     // filled stadium (40,220) 60x40, r=20
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
    lda #70                     // interior: filled
    ldx #240
    jsr shp_rd
    cmp #2
    bne test_shape_stadium__rep
    lda #40                     // sharp corner: cut away by the round end, clear
    ldx #220
    jsr shp_rd
    bne test_shape_stadium__rep
    ldy #0
test_shape_stadium__report:
    tya
    ldx #<test_shape_stadium__name
    ldy #>test_shape_stadium__name
    jmp t_result
test_shape_stadium__name: .text "SHAPE_STADIUM"
    .byte 0

test_shape_arc:
    lda #80                     // clean patch at (80,80)
    ldx #80
    jsr shp_clear40y
    lda #100                    // arc centre (100,100) r=15, 0..64 (E->S)
    sta X16_P0
    stz X16_P1
    lda #100
    sta X16_P2
    stz X16_P3
    lda #15
    sta X16_P4                  // radius
    lda #0
    sta X16_P5                  // start angle: east
    lda #64
    sta X16_P6                  // end angle: south
    lda #3
    jsr shape_arc
    lda #115                    // east endpoint (cx+r, cy): set
    ldx #100
    jsr shp_rd
    cmp #3
    bne test_shape_arc__report
    lda #100                    // south endpoint (cx, cy+r): set
    ldx #115
    jsr shp_rd
    cmp #3
    bne test_shape_arc__report
    lda #85                     // west (not in 0..64): clear
    ldx #100
    jsr shp_rd
    bne test_shape_arc__report
    lda #100                    // north (not in 0..64): clear
    ldx #85
    jsr shp_rd
    bne test_shape_arc__report
    lda #100                    // centre: an outline leaves it clear
    ldx #100
    jsr shp_rd
    bne test_shape_arc__report
    ldy #0
test_shape_arc__report:
    tya
    ldx #<test_shape_arc__name
    ldy #>test_shape_arc__name
    jmp t_result
test_shape_arc__name: .text "SHAPE_ARC"
    .byte 0

test_shape_pie:
    lda #80                     // clean patch at (80,80)
    ldx #80
    jsr shp_clear40y
    lda #100                    // pie centre (100,100) r=15, 0..64 (SE quarter)
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
    lda #100                    // centre (the fan apex): filled
    ldx #100
    jsr shp_rd
    cmp #3
    bne test_shape_pie__report
    lda #105                    // SE interior (45 deg, r~7): filled
    ldx #105
    jsr shp_rd
    cmp #3
    bne test_shape_pie__report
    lda #110                    // on the east radius (angle 0): filled
    ldx #100
    jsr shp_rd
    cmp #3
    bne test_shape_pie__report
    lda #95                     // NW (opposite the wedge): clear
    ldx #95
    jsr shp_rd
    bne test_shape_pie__report
    lda #105                    // NE (outside 0..64): clear
    ldx #95
    jsr shp_rd
    bne test_shape_pie__report
    ldy #0
test_shape_pie__report:
    tya
    ldx #<test_shape_pie__name
    ldy #>test_shape_pie__name
    jmp t_result
test_shape_pie__name: .text "SHAPE_PIE"
    .byte 0

test_shape_bezier:
    lda #95                     // clean patch at (95,95)
    ldx #95
    jsr shp_clear40y
    lda #100                    // a straight (collinear) cubic on row 100
    sta bez_x0                  // P0 = (100,100)
    stz bez_x0+1
    lda #100
    sta bez_y0
    stz bez_y0+1
    lda #110                    // P1 = (110,100)
    sta bez_x1
    stz bez_x1+1
    lda #100
    sta bez_y1
    stz bez_y1+1
    lda #120                    // P2 = (120,100)
    sta bez_x2
    stz bez_x2+1
    lda #100
    sta bez_y2
    stz bez_y2+1
    lda #130                    // P3 = (130,100)
    sta bez_x3
    stz bez_x3+1
    lda #100
    sta bez_y3
    stz bez_y3+1
    lda #3
    jsr shape_bezier
    lda #100                    // P0 anchor: set
    ldx #100
    jsr shp_rd
    cmp #3
    bne test_shape_bezier__rep
    lda #130                    // P3 anchor: set
    ldx #100
    jsr shp_rd
    cmp #3
    bne test_shape_bezier__rep
    lda #115                    // midpoint sample (t=0.5): set
    ldx #100
    jsr shp_rd
    cmp #3
    bne test_shape_bezier__rep
    lda #115                    // ten rows below: a 1px line leaves it clear
    ldx #110
    jsr shp_rd
    beq test_shape_bezier__cont
test_shape_bezier__rep:
    jmp test_shape_bezier__report
test_shape_bezier__cont:
    lda #98                     // clean patch at (98,158)
    ldx #158
    jsr shp_clear40y
    lda #100                    // an arched cubic: handles pull upward
    sta bez_x0                  // P0 = (100,190)
    stz bez_x0+1
    lda #190
    sta bez_y0
    stz bez_y0+1
    lda #110                    // P1 = (110,160)
    sta bez_x1
    stz bez_x1+1
    lda #160
    sta bez_y1
    stz bez_y1+1
    lda #125                    // P2 = (125,160)
    sta bez_x2
    stz bez_x2+1
    lda #160
    sta bez_y2
    stz bez_y2+1
    lda #135                    // P3 = (135,190)
    sta bez_x3
    stz bez_x3+1
    lda #190
    sta bez_y3
    stz bez_y3+1
    lda #2
    jsr shape_bezier
    lda #100                    // P0 anchor: set
    ldx #190
    jsr shp_rd
    cmp #2
    bne test_shape_bezier__report
    lda #135                    // P3 anchor: set
    ldx #190
    jsr shp_rd
    cmp #2
    bne test_shape_bezier__report
    lda #117                    // the straight midpoint: curve arched away, clear
    ldx #190
    jsr shp_rd
    bne test_shape_bezier__report
    ldy #0
test_shape_bezier__report:
    tya
    ldx #<test_shape_bezier__name
    ldy #>test_shape_bezier__name
    jmp t_result
test_shape_bezier__name: .text "SHAPE_BEZIER"
    .byte 0

// The optional sugar macros expand to exactly the hand-written argument
// setup + jsr, so this both proves they work and (via the 7-way PRG hash)
// that they convert byte-identically across every assembler.
test_sugar:
    lda #180                    // clean patch at (180,80)
    ldx #80
    jsr shp_clear40y
    xm_shape_disc(200, 100, 12, 3)  // filled disc via macro
    lda #200                    // centre: filled
    ldx #100
    jsr shp_rd
    cmp #3
    bne test_sugar__report
    lda #180                    // clean patch at (180,140)
    ldx #140
    jsr shp_clear40y
    xm_shape_circle(200, 160, 12, 2)  // outline circle via macro
    lda #212                    // east rim (cx+r): set
    ldx #160
    jsr shp_rd
    cmp #2
    bne test_sugar__report
    lda #200                    // centre: an outline leaves it clear
    ldx #160
    jsr shp_rd
    bne test_sugar__report
    ldy #0
test_sugar__report:
    tya
    ldx #<test_sugar__name
    ldy #>test_sugar__name
    jmp t_result
test_sugar__name: .text "SUGAR_MACROS"
    .byte 0

// xm_collide16 writes the cl_* operands and calls collide16 (16-bit boxes).
test_sugar_collide:
    xm_collide16(10, 10, 20, 20, 15, 15, 20, 20)  // overlapping -> carry set
    bcc test_sugar_collide__fail
    xm_collide16(10, 10, 5, 5, 300, 300, 5, 5)  // disjoint -> carry clear
    bcs test_sugar_collide__fail
    lda #0
    bra test_sugar_collide__done
test_sugar_collide__fail:
    lda #1
test_sugar_collide__done:
    ldx #<test_sugar_collide__name
    ldy #>test_sugar_collide__name
    jmp t_result
test_sugar_collide__name: .text "SUGAR_COLLIDE"
    .byte 0

// Packed-BCD decimal add/subtract. Hex bytes ARE the decimal digits, low
// byte first: $0987 is nine-hundred-eighty-seven. Split across a few short
// tests so every branch to test_sugar_collide__fail stays in range.
test_bcd16: // 16-bit add then subtract
    lda #$87                    // 987 + 1111 = 2098
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
    bne test_bcd16__fail
    lda bcd_a+1
    cmp #$20
    bne test_bcd16__fail
    lda #$98                    // 2098 - 1111 = 987
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
    bne test_bcd16__fail
    lda bcd_a+1
    cmp #$09
    bne test_bcd16__fail
    lda #0
    bra test_bcd16__report
test_bcd16__fail:
    lda #1
test_bcd16__report:
    ldx #<test_bcd16__name
    ldy #>test_bcd16__name
    jmp t_result
test_bcd16__name: .text "BCD16"
    .byte 0

test_bcd8: // 8-bit carry out and borrow
    lda #$99                    // 99 + 01 = 00, carry set
    sta bcd_a
    lda #$01
    sta bcd_b
    jsr bcd_add8
    bcc test_bcd8__fail
    lda bcd_a
    bne test_bcd8__fail
    lda #$00                    // 00 - 01 = 99, carry clear (borrow)
    sta bcd_a
    lda #$01
    sta bcd_b
    jsr bcd_sub8
    bcs test_bcd8__fail
    lda bcd_a
    cmp #$99
    bne test_bcd8__fail
    lda #0
    bra test_bcd8__report
test_bcd8__fail:
    lda #1
test_bcd8__report:
    ldx #<test_bcd8__name
    ldy #>test_bcd8__name
    jmp t_result
test_bcd8__name: .text "BCD8"
    .byte 0

test_bcd_add32: // 32-bit add across bytes, and overflow
    i32_const(bcd_a, $00009999)  // 9999 + 1 = 10000
    i32_const(bcd_b, $00000001)
    jsr bcd_add32
    lda bcd_a
    bne test_bcd_add32__fail
    lda bcd_a+1
    bne test_bcd_add32__fail
    lda bcd_a+2
    cmp #$01
    bne test_bcd_add32__fail
    lda bcd_a+3
    bne test_bcd_add32__fail
    i32_const(bcd_a, $99999999)  // 99999999 + 1 = 0, carry set
    i32_const(bcd_b, $00000001)
    jsr bcd_add32
    bcc test_bcd_add32__fail
    lda bcd_a
    ora bcd_a+1
    ora bcd_a+2
    ora bcd_a+3
    bne test_bcd_add32__fail
    lda #0
    bra test_bcd_add32__report
test_bcd_add32__fail:
    lda #1
test_bcd_add32__report:
    ldx #<test_bcd_add32__name
    ldy #>test_bcd_add32__name
    jmp t_result
test_bcd_add32__name: .text "BCD_ADD32"
    .byte 0

test_bcd_ptr: // 32-bit subtract, then the in-place pair
    i32_const(bcd_a, $00010000)  // 10000 - 1 = 9999
    i32_const(bcd_b, $00000001)
    jsr bcd_sub32
    lda bcd_a
    cmp #$99
    bne test_bcd_ptr__fail
    lda bcd_a+1
    cmp #$99
    bne test_bcd_ptr__fail
    lda bcd_a+2
    ora bcd_a+3
    bne test_bcd_ptr__fail
    i32_const(bcdval32, $00000042)  // in place: 42 + 58 = 100
    i32_const(bcd_b, $00000058)
    lda #<bcdval32
    ldx #>bcdval32
    jsr bcd_addto
    lda bcdval32
    bne test_bcd_ptr__fail
    lda bcdval32+1
    cmp #$01
    bne test_bcd_ptr__fail
    i32_const(bcd_b, $00000001)  // in place: 100 - 1 = 99
    lda #<bcdval32
    ldx #>bcdval32
    jsr bcd_subfrom
    lda bcdval32
    cmp #$99
    bne test_bcd_ptr__fail
    lda bcdval32+1
    bne test_bcd_ptr__fail
    lda #0
    bra test_bcd_ptr__report
test_bcd_ptr__fail:
    lda #1
test_bcd_ptr__report:
    ldx #<test_bcd_ptr__name
    ldy #>test_bcd_ptr__name
    jmp t_result
test_bcd_ptr__name: .text "BCD_PTR"
    .byte 0
bcdval32: .byte 0, 0, 0, 0

// 8 KB banked LIFO stack. Uses bank 5 (the bank tests already prove banks
// round-trip); we check push/pop order and the empty flag through it.
test_stack:
    lda #5
    jsr stack_init
    jsr stack_isempty
    bcc test_stack__fail                   // empty right after init
    lda #42
    jsr stack_push
    lda #7
    jsr stack_push
    lda #99
    jsr stack_push
    jsr stack_size
    cmp #3
    bne test_stack__fail
    cpx #0
    bne test_stack__fail
    jsr stack_isempty
    bcs test_stack__fail                   // not empty with three bytes on it
    jsr stack_pop
    cmp #99                     // LIFO: last in, first out
    bne test_stack__fail
    jsr stack_pop
    cmp #7
    bne test_stack__fail
    jsr stack_pop
    cmp #42
    bne test_stack__fail
    jsr stack_isempty
    bcc test_stack__fail                   // empty again
    lda #0
    bra test_stack__report
test_stack__fail:
    lda #1
test_stack__report:
    ldx #<test_stack__name
    ldy #>test_stack__name
    jmp t_result
test_stack__name: .text "STACK"
    .byte 0

test_stack_word:
    lda #5
    jsr stack_init
    lda #<1000
    ldx #>1000
    jsr stack_pushw
    lda #<50
    ldx #>50
    jsr stack_pushw
    jsr stack_popw              // LIFO: 50 comes back first
    cmp #<50
    bne test_stack_word__fail
    cpx #>50
    bne test_stack_word__fail
    jsr stack_popw
    cmp #<1000
    bne test_stack_word__fail
    cpx #>1000
    bne test_stack_word__fail
    jsr stack_isempty
    bcc test_stack_word__fail
    lda #0
    bra test_stack_word__report
test_stack_word__fail:
    lda #1
test_stack_word__report:
    ldx #<test_stack_word__name
    ldy #>test_stack_word__name
    jmp t_result
test_stack_word__name: .text "STACK_WORD"
    .byte 0

// 8 KB banked FIFO ring. Bank 6.
test_ring:
    lda #6
    jsr ring_init
    jsr ring_isempty
    bcc test_ring__fail
    lda #10
    jsr ring_put
    lda #20
    jsr ring_put
    lda #30
    jsr ring_put
    jsr ring_size
    cmp #3
    bne test_ring__fail
    cpx #0
    bne test_ring__fail
    jsr ring_get               // FIFO: 10 comes out first
    cmp #10
    bne test_ring__fail
    jsr ring_get
    cmp #20
    bne test_ring__fail
    jsr ring_get
    cmp #30
    bne test_ring__fail
    jsr ring_isempty
    bcc test_ring__fail
    lda #0
    bra test_ring__report
test_ring__fail:
    lda #1
test_ring__report:
    ldx #<test_ring__name
    ldy #>test_ring__name
    jmp t_result
test_ring__name: .text "RING"
    .byte 0

test_ring_word:
    lda #6
    jsr ring_init
    lda #<777
    ldx #>777
    jsr ring_putw
    lda #<258
    ldx #>258
    jsr ring_putw
    jsr ring_getw              // FIFO: 777 first
    cmp #<777
    bne test_ring_word__fail
    cpx #>777
    bne test_ring_word__fail
    jsr ring_getw
    cmp #<258
    bne test_ring_word__fail
    cpx #>258
    bne test_ring_word__fail
    lda #0
    bra test_ring_word__report
test_ring_word__fail:
    lda #1
test_ring_word__report:
    ldx #<test_ring_word__name
    ldy #>test_ring_word__name
    jmp t_result
test_ring_word__name: .text "RING_WORD"
    .byte 0

// Drive the head/tail past the top of the bank to prove the wrap. Preset a
// consistent empty state near offset 8191, then queue across the boundary.
test_ring_wrap:
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
    lda #11                     // @8190
    jsr ring_put
    lda #22                     // @8191
    jsr ring_put
    lda #33                     // head wrapped -> @0
    jsr ring_put
    lda #44                     // @1
    jsr ring_put
    jsr ring_get
    cmp #11
    bne test_ring_wrap__fail
    jsr ring_get
    cmp #22
    bne test_ring_wrap__fail
    jsr ring_get               // tail wrapped -> reads @0
    cmp #33
    bne test_ring_wrap__fail
    jsr ring_get
    cmp #44
    bne test_ring_wrap__fail
    jsr ring_isempty
    bcc test_ring_wrap__fail
    lda #0
    bra test_ring_wrap__report
test_ring_wrap__fail:
    lda #1
test_ring_wrap__report:
    ldx #<test_ring_wrap__name
    ldy #>test_ring_wrap__name
    jmp t_result
test_ring_wrap__name: .text "RING_WRAP"
    .byte 0

// ---------------------------------------------------------------------
// String library. Small focused tests keep every branch to test_ring_wrap__fail in range.
test_str_core:
    lda #<sd_hello
    ldx #>sd_hello
    jsr str_length
    cpy #5
    bne test_str_core__fail
    lda #<sd_buf
    sta X16_P0
    lda #>sd_buf
    sta X16_P1
    lda #<sd_hello
    ldx #>sd_hello
    jsr str_copy
    cpy #5
    bne test_str_core__fail
    lda sd_buf
    cmp #'h'
    bne test_str_core__fail
    lda sd_buf+4
    cmp #'o'
    bne test_str_core__fail
    lda sd_buf+5
    bne test_str_core__fail
    lda #0
    bra test_str_core__report
test_str_core__fail:
    lda #1
test_str_core__report:
    ldx #<test_str_core__name
    ldy #>test_str_core__name
    jmp t_result
test_str_core__name: .text "STR_CORE"
    .byte 0

test_str_cmp:
    lda #<sd_abc2
    sta X16_P0
    lda #>sd_abc2
    sta X16_P1
    lda #<sd_abc                // "abc" vs "abc" = 0
    ldx #>sd_abc
    jsr str_compare
    bne test_str_cmp__fail
    lda #<sd_abd
    sta X16_P0
    lda #>sd_abd
    sta X16_P1
    lda #<sd_abc                // "abc" vs "abd" = -1
    ldx #>sd_abc
    jsr str_compare
    cmp #$FF
    bne test_str_cmp__fail
    lda #<sd_abc
    sta X16_P0
    lda #>sd_abc
    sta X16_P1
    lda #<sd_abd                // "abd" vs "abc" = 1
    ldx #>sd_abd
    jsr str_compare
    cmp #1
    bne test_str_cmp__fail
    lda #0
    bra test_str_cmp__report
test_str_cmp__fail:
    lda #1
test_str_cmp__report:
    ldx #<test_str_cmp__name
    ldy #>test_str_cmp__name
    jmp t_result
test_str_cmp__name: .text "STR_CMP"
    .byte 0

test_str_edit:
    lda #<sd_buf
    sta X16_P0
    lda #>sd_buf
    sta X16_P1
    lda #<sd_hello              // buf = copy of "hello"
    ldx #>sd_hello
    jsr str_copy
    lda #<sd_bang
    sta X16_P0
    lda #>sd_bang
    sta X16_P1
    lda #<sd_buf                // append "!!" -> "hello!!", A=7
    ldx #>sd_buf
    jsr str_append
    cmp #7
    bne test_str_edit__fail
    lda sd_buf+6
    cmp #'!'
    bne test_str_edit__fail
    lda sd_buf+7
    bne test_str_edit__fail
    lda #<sd_hi                 // hash("hi") = $74
    ldx #>sd_hi
    jsr str_hash
    cmp #$74
    bne test_str_edit__fail
    lda #0
    bra test_str_edit__report
test_str_edit__fail:
    lda #1
test_str_edit__report:
    ldx #<test_str_edit__name
    ldy #>test_str_edit__name
    jmp t_result
test_str_edit__name: .text "STR_EDIT"
    .byte 0

test_str_ctype:
    lda #'5'
    jsr str_isdigit
    bcc test_str_ctype__fail
    lda #'a'
    jsr str_isdigit
    bcs test_str_ctype__fail
    lda #'F'
    jsr str_isxdigit
    bcc test_str_ctype__fail
    lda #'g'
    jsr str_isxdigit
    bcs test_str_ctype__fail
    lda #'a'                    // PETSCII isupper: 97-122
    jsr str_isupper
    bcc test_str_ctype__fail
    lda #'A'                    // 65 is not upper in PETSCII
    jsr str_isupper
    bcs test_str_ctype__fail
    lda #'A'                    // but it is in ISO
    jsr str_isupper_iso
    bcc test_str_ctype__fail
    lda #32
    jsr str_isspace
    bcc test_str_ctype__fail
    lda #150                    // 128-159 not printable
    jsr str_isprint
    bcs test_str_ctype__fail
    lda #0
    bra test_str_ctype__report
test_str_ctype__fail:
    lda #1
test_str_ctype__report:
    ldx #<test_str_ctype__name
    ldy #>test_str_ctype__name
    jmp t_result
test_str_ctype__name: .text "STR_CTYPE"
    .byte 0

test_str_case:
    lda #'a'                    // PETSCII lowerchar('a'=97) -> 65
    jsr str_lowerchar
    cmp #65
    bne test_str_case__fail
    lda #'A'                    // PETSCII upperchar('A'=65) -> 97
    jsr str_upperchar
    cmp #97
    bne test_str_case__fail
    lda #'A'                    // ISO lowerchar('A'=65) -> 97
    jsr str_lowerchar_iso
    cmp #97
    bne test_str_case__fail
    lda #'a'                    // ISO upperchar('a'=97) -> 65
    jsr str_upperchar_iso
    cmp #65
    bne test_str_case__fail
    lda #0
    bra test_str_case__report
test_str_case__fail:
    lda #1
test_str_case__report:
    ldx #<test_str_case__name
    ldy #>test_str_case__name
    jmp t_result
test_str_case__name: .text "STR_CASE"
    .byte 0

test_str_lower:
    lda #<sd_buf
    sta X16_P0
    lda #>sd_buf
    sta X16_P1
    lda #<sd_HELLO             // buf = "HELLO", then lower_iso -> "hello"
    ldx #>sd_HELLO
    jsr str_copy
    lda #<sd_buf
    ldx #>sd_buf
    jsr str_lower_iso
    lda sd_buf
    cmp #'h'
    bne test_str_lower__fail
    lda #<sd_buf               // upper_iso -> "HELLO"
    ldx #>sd_buf
    jsr str_upper_iso
    lda sd_buf
    cmp #'H'
    bne test_str_lower__fail
    lda #<sd_hello
    sta X16_P0
    lda #>sd_hello
    sta X16_P1
    lda #<sd_Hello             // compare_nocase("Hello","hello") = 0
    ldx #>sd_Hello
    jsr str_compare_nocase
    bne test_str_lower__fail
    lda #0
    bra test_str_lower__report
test_str_lower__fail:
    lda #1
test_str_lower__report:
    ldx #<test_str_lower__name
    ldy #>test_str_lower__name
    jmp t_result
test_str_lower__name: .text "STR_LOWER"
    .byte 0

test_str_find:
    lda #<sd_hello             // find 'l' -> index 2
    ldx #>sd_hello
    ldy #'l'
    jsr str_find
    bcc test_str_find__fail
    cmp #2
    bne test_str_find__fail
    lda #<sd_hello             // rfind 'l' -> index 3
    ldx #>sd_hello
    ldy #'l'
    jsr str_rfind
    bcc test_str_find__fail
    cmp #3
    bne test_str_find__fail
    lda #<sd_hello             // find 'z' -> not found
    ldx #>sd_hello
    ldy #'z'
    jsr str_find
    bcs test_str_find__fail
    lda #<sd_line              // find_eol -> index 2 (the CR)
    ldx #>sd_line
    jsr str_find_eol
    bcc test_str_find__fail
    cmp #2
    bne test_str_find__fail
    lda #0
    bra test_str_find__report
test_str_find__fail:
    lda #1
test_str_find__report:
    ldx #<test_str_find__name
    ldy #>test_str_find__name
    jmp t_result
test_str_find__name: .text "STR_FIND"
    .byte 0

test_str_pat:
    lda #<sd_pat
    sta X16_P0
    lda #>sd_pat
    sta X16_P1
    lda #<sd_hello             // "hello" matches "he*o"
    ldx #>sd_hello
    jsr str_pattern_match
    bcc test_str_pat__fail
    lda #<sd_patq
    sta X16_P0
    lda #>sd_patq
    sta X16_P1
    lda #<sd_hello             // "hello" matches "h?llo"
    ldx #>sd_hello
    jsr str_pattern_match
    bcc test_str_pat__fail
    lda #<sd_patx
    sta X16_P0
    lda #>sd_patx
    sta X16_P1
    lda #<sd_hello             // "hello" does NOT match "he*x"
    ldx #>sd_hello
    jsr str_pattern_match
    bcs test_str_pat__fail
    lda #0
    bra test_str_pat__report
test_str_pat__fail:
    lda #1
test_str_pat__report:
    ldx #<test_str_pat__name
    ldy #>test_str_pat__name
    jmp t_result
test_str_pat__name: .text "STR_PAT"
    .byte 0

test_str_slice:
    lda #<sd_buf
    sta X16_P0
    lda #>sd_buf
    sta X16_P1
    lda #<sd_hello             // left 3 -> "hel"
    ldx #>sd_hello
    ldy #3
    jsr str_left
    lda sd_buf
    cmp #'h'
    bne test_str_slice__fail
    lda sd_buf+2
    cmp #'l'
    bne test_str_slice__fail
    lda sd_buf+3
    bne test_str_slice__fail
    lda #<sd_buf
    sta X16_P0
    lda #>sd_buf
    sta X16_P1
    lda #<sd_hello             // right 2 -> "lo"
    ldx #>sd_hello
    ldy #2
    jsr str_right
    lda sd_buf
    cmp #'l'
    bne test_str_slice__fail
    lda sd_buf+1
    cmp #'o'
    bne test_str_slice__fail
    lda #<sd_buf
    sta X16_P0
    lda #>sd_buf
    sta X16_P1
    lda #1                     // slice start 1 len 3 -> "ell"
    sta X16_P2
    lda #<sd_hello
    ldx #>sd_hello
    ldy #3
    jsr str_slice
    lda sd_buf
    cmp #'e'
    bne test_str_slice__fail
    lda sd_buf+2
    cmp #'l'
    bne test_str_slice__fail
    lda sd_buf+3
    bne test_str_slice__fail
    lda #0
    bra test_str_slice__report
test_str_slice__fail:
    lda #1
test_str_slice__report:
    ldx #<test_str_slice__name
    ldy #>test_str_slice__name
    jmp t_result
test_str_slice__name: .text "STR_SLICE"
    .byte 0

test_str_trim:
    lda #<sd_buf
    sta X16_P0
    lda #>sd_buf
    sta X16_P1
    lda #<sd_pad               // buf = "  hi  "
    ldx #>sd_pad
    jsr str_copy
    lda #<sd_buf               // trim both ends -> "hi"
    ldx #>sd_buf
    jsr str_trim
    lda sd_buf
    cmp #'h'
    bne test_str_trim__fail
    lda sd_buf+1
    cmp #'i'
    bne test_str_trim__fail
    lda sd_buf+2
    bne test_str_trim__fail
    lda #<sd_buf
    sta X16_P0
    lda #>sd_buf
    sta X16_P1
    lda #<sd_pad2              // buf = "ab  "
    ldx #>sd_pad2
    jsr str_copy
    lda #<sd_buf               // rtrim only -> "ab"
    ldx #>sd_buf
    jsr str_rtrim
    lda sd_buf+2
    bne test_str_trim__fail
    lda sd_buf+1
    cmp #'b'
    bne test_str_trim__fail
    lda #0
    bra test_str_trim__report
test_str_trim__fail:
    lda #1
test_str_trim__report:
    ldx #<test_str_trim__name
    ldy #>test_str_trim__name
    jmp t_result
test_str_trim__name: .text "STR_TRIM"
    .byte 0

// =====================================================================
// str_sort: permute an array of string pointers into ascending order.
// =====================================================================
test_str_sort:
    lda #<test_str_sort__sdelta
    sta test_str_sort__arr+0
    lda #>test_str_sort__sdelta
    sta test_str_sort__arr+1
    lda #<test_str_sort__salpha
    sta test_str_sort__arr+2
    lda #>test_str_sort__salpha
    sta test_str_sort__arr+3
    lda #<test_str_sort__scharlie
    sta test_str_sort__arr+4
    lda #>test_str_sort__scharlie
    sta test_str_sort__arr+5
    lda #<test_str_sort__sbravo
    sta test_str_sort__arr+6
    lda #>test_str_sort__sbravo
    sta test_str_sort__arr+7

    lda #<test_str_sort__arr
    sta X16_P0
    lda #>test_str_sort__arr
    sta X16_P1
    lda #4
    sta X16_P2
    stz X16_P3
    jsr str_sort

    // expect alpha, bravo, charlie, delta
    lda test_str_sort__arr+0
    cmp #<test_str_sort__salpha
    bne test_str_sort__fail
    lda test_str_sort__arr+2
    cmp #<test_str_sort__sbravo
    bne test_str_sort__fail
    lda test_str_sort__arr+4
    cmp #<test_str_sort__scharlie
    bne test_str_sort__fail
    lda test_str_sort__arr+6
    cmp #<test_str_sort__sdelta
    bne test_str_sort__fail
    lda test_str_sort__arr+1
    cmp #>test_str_sort__salpha
    bne test_str_sort__fail
    lda #0
    bra test_str_sort__report
test_str_sort__fail:
    lda #1
test_str_sort__report:
    ldx #<test_str_sort__name
    ldy #>test_str_sort__name
    jmp t_result
test_str_sort__salpha: .text "alpha"
    .byte 0
test_str_sort__sbravo: .text "bravo"
    .byte 0
test_str_sort__scharlie: .text "charlie"
    .byte 0
test_str_sort__sdelta: .text "delta"
    .byte 0
test_str_sort__arr: .fill 8, 0
test_str_sort__name: .text "STR_SORT"
    .byte 0

// The xm_str_* macros expand to the same setup + jsr, so this proves they
// work and (via the 7-way hash) that they convert byte-identically.
test_str_sugar:
    xm_str_copy(sd_hello, sd_buf)  // buf = "hello"
    xm_str_upper_iso(sd_buf)  // buf = "HELLO"
    lda sd_buf
    cmp #'H'
    bne test_str_sugar__fail
    xm_str_find(sd_hello, 'l')  // find 'l' -> index 2, carry set
    bcc test_str_sugar__fail
    cmp #2
    bne test_str_sugar__fail
    xm_str_pattern_match(sd_hello, sd_pat)  // "hello" matches "he*o"
    bcc test_str_sugar__fail
    lda #0
    bra test_str_sugar__report
test_str_sugar__fail:
    lda #1
test_str_sugar__report:
    ldx #<test_str_sugar__name
    ldy #>test_str_sugar__name
    jmp t_result
test_str_sugar__name: .text "STR_SUGAR"
    .byte 0

sd_hello: .text "hello"
    .byte 0
sd_hi: .text "hi"
    .byte 0
sd_bang: .text "!!"
    .byte 0
sd_abc: .text "abc"
    .byte 0
sd_abc2: .text "abc"
    .byte 0
sd_abd: .text "abd"
    .byte 0
sd_HELLO: .text "HELLO"
    .byte 0
sd_Hello: .text "Hello"
    .byte 0
sd_line: .text "ab"
    .byte 13
    .text "cd"
    .byte 0
sd_pat: .text "he*o"
    .byte 0
sd_patq: .text "h?llo"
    .byte 0
sd_patx: .text "he*x"
    .byte 0
sd_pad: .text "  hi  "
    .byte 0
sd_pad2: .text "ab  "
    .byte 0
sd_buf: .fill 24, 0

shp_rd: // read (A, X), both bytes
    sta X16_P0
    stz X16_P1
    stx X16_P2
    stz X16_P3
    phy
    jsr gfx2h_read
    ply
    ora #0                      // ply set the flags from Y; re-set from A
    rts

shp_clear40: // colour 0 over (A,100)+40x40
    ldx #100
shp_clear40y: // ...or over (A,X)+40x40
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
    jmp gfx2h_rect

// =====================================================================
// dir_open/dir_next must walk the listing the drive returns and find
// TESTDATA.BIN, which it writes first, so it stands alone. The
// header line has to come back as HOST and the file as PRG -- proving
// the type is read, not assumed -- and the name has to match exactly,
// which means the quotes were stripped and the terminator placed.
// =====================================================================
test_dir_reads:
    lda #<test_dir_reads__want                 // lay down the file this test looks for,
    sta X16_P0                  // so it does not lean on another runner
    lda #>test_dir_reads__want
    sta X16_P1
    lda #12
    sta X16_P2
    lda #8
    sta X16_P3
    lda #<test_dir_reads__src
    sta X16_P5
    lda #>test_dir_reads__src
    sta X16_P6
    lda #<(test_dir_reads__src + 4)
    sta X16_T6
    lda #>(test_dir_reads__src + 4)
    sta X16_T7
    jsr fs_save

    lda #0                      // no path: the current directory
    sta X16_P2
    lda #8
    sta X16_P3
    jsr dir_open
    bcs test_dir_reads__fail

    jsr test_dir_reads__entry                  // the header names the volume
    bcc test_dir_reads__fail_close
    jsr dir_type
    cmp #DIR_TYPE_HOST
    bne test_dir_reads__fail_close

    stz test_dir_reads__found
test_dir_reads__scan:
    jsr test_dir_reads__entry
    bcc test_dir_reads__done                   // end of the listing
    jsr dir_type
    cmp #DIR_TYPE_PRG
    bne test_dir_reads__scan
    ldx #0
test_dir_reads__cmp:
    lda test_dir_reads__want,x
    cmp test_dir_reads__buf,x
    bne test_dir_reads__scan                   // a different file: keep looking
    inx
    cpx #13                     // 12 characters and the terminator
    bne test_dir_reads__cmp
    lda #1
    sta test_dir_reads__found
    bra test_dir_reads__scan
test_dir_reads__done:
    jsr dir_close
    lda test_dir_reads__found
    beq test_dir_reads__fail
    lda #0
    bra test_dir_reads__report
test_dir_reads__fail_close:
    jsr dir_close
test_dir_reads__fail:
    lda #1
test_dir_reads__report:
    ldx #<test_dir_reads__name
    ldy #>test_dir_reads__name
    jmp t_result
test_dir_reads__entry:
    lda #<test_dir_reads__buf
    sta X16_P0
    lda #>test_dir_reads__buf
    sta X16_P1
    lda #test_dir_reads__buf_size
    sta X16_P2
    jmp dir_next
test_dir_reads__want: .text "TESTDATA.BIN"
    .byte $00
test_dir_reads__src: .byte $DE, $AD, $BE, $EF
test_dir_reads__found: .byte 0
.label test_dir_reads__buf_size = 40
test_dir_reads__buf: .fill 40, 0
test_dir_reads__name: .text "DIR_READS"
    .byte $00

// =====================================================================
// A directory made, entered, listed and left again. Inside it the only
// entries are "." and ".." -- both DIR -- which is also the proof that
// dir_next follows the current directory rather than the root, and that
// a name shorter than the buffer terminates where it should.
// =====================================================================
test_dir_chdir:
    lda #<test_dir_chdir__sub                  // make it (ignore "already exists")
    ldx #>test_dir_chdir__sub
    ldy #test_dir_chdir__sub_len
    jsr dos_mkdir

    lda #<test_dir_chdir__sub
    ldx #>test_dir_chdir__sub
    ldy #test_dir_chdir__sub_len
    jsr dos_chdir
    bcs test_dir_chdir__fail

    lda #0
    sta X16_P2
    lda #8
    sta X16_P3
    jsr dir_open
    bcs test_dir_chdir__fail_root

    stz test_dir_chdir__dirs
    stz test_dir_chdir__others
test_dir_chdir__scan:
    lda #<test_dir_chdir__buf
    sta X16_P0
    lda #>test_dir_chdir__buf
    sta X16_P1
    lda #test_dir_chdir__buf_size
    sta X16_P2
    jsr dir_next
    bcc test_dir_chdir__done
    jsr dir_type
    cmp #DIR_TYPE_DIR
    bne test_dir_chdir__notdir
    inc test_dir_chdir__dirs
    bra test_dir_chdir__scan
test_dir_chdir__notdir:
    cmp #DIR_TYPE_HOST          // the header line is expected
    beq test_dir_chdir__scan
    cmp #DIR_TYPE_NONE          // ...and so is "BLOCKS FREE."
    beq test_dir_chdir__scan
    inc test_dir_chdir__others
    bra test_dir_chdir__scan
test_dir_chdir__done:
    jsr dir_close

    lda #<test_dir_chdir__root                 // back to where the other tests live
    ldx #>test_dir_chdir__root
    ldy #test_dir_chdir__root_len
    jsr dos_chdir
    bcs test_dir_chdir__fail

    lda test_dir_chdir__others                 // nothing but . and .. in a new directory
    bne test_dir_chdir__fail
    lda test_dir_chdir__dirs
    cmp #2
    bne test_dir_chdir__fail
    lda #0
    bra test_dir_chdir__report
test_dir_chdir__fail_root:
    lda #<test_dir_chdir__root
    ldx #>test_dir_chdir__root
    ldy #test_dir_chdir__root_len
    jsr dos_chdir
test_dir_chdir__fail:
    lda #1
test_dir_chdir__report:
    ldx #<test_dir_chdir__name
    ldy #>test_dir_chdir__name
    jmp t_result
test_dir_chdir__sub: .text "dirtest"
.label test_dir_chdir__sub_len = 7
test_dir_chdir__root: .text "//"
.label test_dir_chdir__root_len = 2
test_dir_chdir__dirs: .byte 0
test_dir_chdir__others: .byte 0
.label test_dir_chdir__buf_size = 40
test_dir_chdir__buf: .fill 40, 0
test_dir_chdir__name: .text "DIR_CHDIR"
    .byte $00

// =====================================================================
// The carry says a bmx_* call failed; bmx_lasterr says why. Loading a
// file that is not there has to report BMX_ERR_IO and not, say, leave
// the code from some earlier call lying around -- so ask twice, either
// side of a call that works, and check it clears.
// =====================================================================
test_bmx_lasterr:
    lda #<test_bmx_lasterr__gone
    sta X16_P0
    lda #>test_bmx_lasterr__gone
    sta X16_P1
    lda #test_bmx_lasterr__gone_len
    sta X16_P2
    lda #8
    sta X16_P3
    stz X16_P4
    stz X16_P5
    stz X16_P6
    jsr bmx_load
    bcc test_bmx_lasterr__fail                   // it "loaded" a file that is not there
    jsr bmx_lasterr
    cmp #BMX_ERR_IO
    bne test_bmx_lasterr__fail

    lda #<test_bmx_lasterr__bmx                  // a real one, written here and read back
    sta X16_P0
    lda #>test_bmx_lasterr__bmx
    sta X16_P1
    lda #test_bmx_lasterr__bmx_len
    sta X16_P2
    lda #8
    sta X16_P3
    stz X16_P4
    lda #<$4000
    sta X16_P5
    lda #>$4000
    sta X16_P6
    jsr bmx_save
    bcs test_bmx_lasterr__fail
    jsr bmx_lasterr
    cmp #0                      // a call that worked leaves nothing behind
    bne test_bmx_lasterr__fail

    lda #0
    bra test_bmx_lasterr__report
test_bmx_lasterr__fail:
    lda #1
test_bmx_lasterr__report:
    ldx #<test_bmx_lasterr__name
    ldy #>test_bmx_lasterr__name
    jmp t_result
test_bmx_lasterr__gone: .text "NOSUCH.BMX"
.label test_bmx_lasterr__gone_len = 10
test_bmx_lasterr__bmx: .text "TESTOUT.BMX"
.label test_bmx_lasterr__bmx_len = 11
test_bmx_lasterr__name: .text "BMX_LASTERR"
    .byte $00

// =====================================================================
// PETSCII case classification. PETSCII puts lower case at 65-90 and
// upper at 97-122 / 193-218 -- the folding routines have always agreed,
// but str_islower tested 97-122, the SAME set as str_isupper, so no
// lower-case letter answered yes and str_isletter rejected ordinary
// PETSCII text outright.
// =====================================================================
test_str_petscii_class:
    lda #65                     // 'A' as PETSCII writes lower case
    jsr str_islower
    bcc test_str_petscii_class__fail
    lda #97                     // 97-122 is upper here, not lower
    jsr str_islower
    bcs test_str_petscii_class__fail
    lda #65
    jsr str_isletter
    bcc test_str_petscii_class__fail
    lda #218                    // the second upper range
    jsr str_isletter
    bcc test_str_petscii_class__fail
    lda #'a'                    // ISO keeps 'a'-'z' lower
    jsr str_islower_iso
    bcc test_str_petscii_class__fail
    lda #$C0                    // and folds the accented capitals
    jsr str_isupper_iso
    bcc test_str_petscii_class__fail
    lda #$D7                    // ...but the multiplication sign is
    jsr str_isupper_iso         // punctuation, not a letter
    bcs test_str_petscii_class__fail
    lda #0
    bra test_str_petscii_class__report
test_str_petscii_class__fail:
    lda #1
test_str_petscii_class__report:
    ldx #<test_str_petscii_class__name
    ldy #>test_str_petscii_class__name
    jmp t_result
test_str_petscii_class__name: .text "STR_PETSCII_CLASS"
    .byte 0

// =====================================================================
// str_lowerchar used to start with an unconditional `and #$7f`, which
// turned $80 into $00: str_lower wrote a terminator into the middle of
// the string, and str_compare_nocase then walked off the end of the
// shorter operand comparing whatever followed it.
// =====================================================================
test_str_case_hibyte:
    lda #$80
    jsr str_lowerchar
    cmp #$80                    // a control code is not a letter
    bne test_str_case_hibyte__fail
    lda #$A0                    // shift-space, likewise untouched
    jsr str_lowerchar
    cmp #$A0
    bne test_str_case_hibyte__fail
    lda #193                    // but 193-218 really is upper case
    jsr str_lowerchar
    cmp #65
    bne test_str_case_hibyte__fail

    lda #<test_str_case_hibyte__hi                   // the string keeps its length and its $80
    ldx #>test_str_case_hibyte__hi
    jsr str_lower
    cpy #4
    bne test_str_case_hibyte__fail
    lda test_str_case_hibyte__hi+2
    cmp #$80
    bne test_str_case_hibyte__fail
    lda test_str_case_hibyte__hi+3                   // the tail survived the fold
    cmp #67
    bne test_str_case_hibyte__fail

    lda #<test_str_case_hibyte__s1                   // s1 is longer, so it sorts after s2
    ldx #>test_str_case_hibyte__s1
    lda #<test_str_case_hibyte__s2
    sta X16_P0
    lda #>test_str_case_hibyte__s2
    sta X16_P1
    lda #<test_str_case_hibyte__s1
    ldx #>test_str_case_hibyte__s1
    jsr str_compare_nocase
    cmp #1
    bne test_str_case_hibyte__fail
    lda #0
    bra test_str_case_hibyte__report
test_str_case_hibyte__fail:
    lda #1
test_str_case_hibyte__report:
    ldx #<test_str_case_hibyte__name
    ldy #>test_str_case_hibyte__name
    jmp t_result
test_str_case_hibyte__hi: .byte 97, 98, $80, 99, 0
test_str_case_hibyte__s1: .byte 65, 66, $80, 88, 0
test_str_case_hibyte__s2: .byte 65, 66, 0
test_str_case_hibyte__name: .text "STR_CASE_HIBYTE"
    .byte 0

// =====================================================================
// Appending a string to itself: the copy overwrites the suffix's own
// terminator with its first byte, so a copy-until-NUL loop never saw the
// end and sprayed 256 bytes past the buffer.
// =====================================================================
test_str_append_self:
    lda #<test_str_append_self__buf                  // suffix and target are the same string
    sta X16_P0
    lda #>test_str_append_self__buf
    sta X16_P1
    lda #<test_str_append_self__buf
    ldx #>test_str_append_self__buf
    jsr str_append
    cmp #6                      // "abc" + "abc"
    bne test_str_append_self__fail
    lda test_str_append_self__buf+3
    cmp #'a'
    bne test_str_append_self__fail
    lda test_str_append_self__buf+5
    cmp #'c'
    bne test_str_append_self__fail
    lda test_str_append_self__buf+6                  // terminated, and nothing beyond it
    bne test_str_append_self__fail
    lda test_str_append_self__buf+7
    cmp #$5A
    bne test_str_append_self__fail
    lda #0
    bra test_str_append_self__report
test_str_append_self__fail:
    lda #1
test_str_append_self__report:
    ldx #<test_str_append_self__name
    ldy #>test_str_append_self__name
    jmp t_result
test_str_append_self__buf: .text "abc"
    .byte 0
       .fill 4, $5A             // a guard the old 256-byte run walked over
test_str_append_self__name: .text "STR_APPEND_SELF"
    .byte 0

// =====================================================================
// ring_isfull has to arm while two bytes still fit, or a caller that
// obeys it can drive ring_putw one word past the end and leave
// ring_free reporting $FFFF.
// =====================================================================
test_ring_full_edge:
    lda #6
    jsr ring_init
test_ring_full_edge__fill: // exactly the guarded pattern a caller
    jsr ring_isfull             // writes: put a word while one still fits
    bcs test_ring_full_edge__atcap
    lda #$11
    ldx #$22
    jsr ring_putw
    bra test_ring_full_edge__fill
test_ring_full_edge__atcap:
    jsr ring_free
    cpx #0                      // the count must not have run past the
    bne test_ring_full_edge__fail                   // end and underflowed free to $FFFF
    cmp #2                      // and at most one odd byte can be left
    bcs test_ring_full_edge__fail
    lda #0
    bra test_ring_full_edge__report
test_ring_full_edge__fail:
    lda #1
test_ring_full_edge__report:
    ldx #<test_ring_full_edge__name
    ldy #>test_ring_full_edge__name
    jmp t_result
test_ring_full_edge__name: .text "RING_FULL_EDGE"
    .byte 0

// =====================================================================
// A radius of 0 is documented and degenerate: one pixel. The midpoint
// walk stepped x from 0 to 255 and sprayed plots (and, for a disc,
// unclipped 511-pixel spans) right across VRAM.
// =====================================================================
test_shape_r0:
    lda #100
    jsr shp_clear40
    lda #120
    sta X16_P0
    stz X16_P1
    lda #120
    sta X16_P2
    stz X16_P3
    stz X16_P4                  // r = 0
    lda #3
    jsr shape_circle
    ldy #1
    lda #120                    // the centre is the whole circle
    ldx #120
    jsr shp_rd
    cmp #3
    bne test_shape_r0__report
    lda #130                    // and nothing else in the patch moved
    ldx #120
    jsr shp_rd
    bne test_shape_r0__report
    lda #110
    ldx #125
    jsr shp_rd
    bne test_shape_r0__report
    ldy #0
test_shape_r0__report:
    tya
    ldx #<test_shape_r0__name
    ldy #>test_shape_r0__name
    jmp t_result
test_shape_r0__name: .text "SHAPE_R0"
    .byte 0

// =====================================================================
// VERA's sprite position field is 10 bits and UNSIGNED, 0..1023, and
// the whole 640-wide display is inside it. x = 600 is an ordinary
// on-screen position whose bit 9 is set, so a sprite_get_pos that read
// bit 9 as a sign would answer -424 for it. A coordinate written
// negative is masked into the field and comes back as what is stored
// -- 1019 for -5, which is where the hardware draws it.
// =====================================================================
test_sprite_pos_signed:
    jsr sprite_init_all
    lda #<600
    sta X16_P0
    lda #>600
    sta X16_P1
    lda #<-5
    sta X16_P2
    lda #>-5
    sta X16_P3
    ldx #4
    jsr sprite_pos

    stz X16_P0
    stz X16_P1
    stz X16_P2
    stz X16_P3
    ldx #4
    jsr sprite_get_pos
    lda X16_P0
    cmp #<600
    bne test_sprite_pos_signed__fail
    lda X16_P1
    cmp #>600
    bne test_sprite_pos_signed__fail
    lda X16_P2
    cmp #<1019
    bne test_sprite_pos_signed__fail
    lda X16_P3
    cmp #>1019
    bne test_sprite_pos_signed__fail
    lda #0
    bra test_sprite_pos_signed__report
test_sprite_pos_signed__fail:
    lda #1
test_sprite_pos_signed__report:
    ldx #<test_sprite_pos_signed__name
    ldy #>test_sprite_pos_signed__name
    jmp t_result
test_sprite_pos_signed__name: .text "SPRITE_POS_UNSIGNED"
    .byte 0

// =====================================================================
// The wildcard shapes the old recursive matcher could not survive: a
// pattern with more '*' than its 4-bytes-of-stack-each could afford, and
// the "a*a*a*a*b" shape that made it retry the tail from scratch after
// every failed position.
// =====================================================================
test_str_pat_edge:
    lda #<test_str_pat_edge__stars
    sta X16_P0
    lda #>test_str_pat_edge__stars
    sta X16_P1
    lda #<test_str_pat_edge__aaa
    ldx #>test_str_pat_edge__aaa
    jsr str_pattern_match
    bcc test_str_pat_edge__fail
    lda #<test_str_pat_edge__evil                 // no 'b' anywhere: the answer is no, and
    sta X16_P0                  // it has to arrive this decade
    lda #>test_str_pat_edge__evil
    sta X16_P1
    lda #<test_str_pat_edge__aaa
    ldx #>test_str_pat_edge__aaa
    jsr str_pattern_match
    bcs test_str_pat_edge__fail
    lda #<test_str_pat_edge__star1                // '*' may swallow nothing at all
    sta X16_P0
    lda #>test_str_pat_edge__star1
    sta X16_P1
    lda #<test_str_pat_edge__empty
    ldx #>test_str_pat_edge__empty
    jsr str_pattern_match
    bcc test_str_pat_edge__fail
    lda #<test_str_pat_edge__empty                // an empty pattern matches only the
    sta X16_P0                  // empty string
    lda #>test_str_pat_edge__empty
    sta X16_P1
    lda #<test_str_pat_edge__aaa
    ldx #>test_str_pat_edge__aaa
    jsr str_pattern_match
    bcs test_str_pat_edge__fail
    lda #<test_str_pat_edge__lead                 // a '*' that has to give ground twice
    sta X16_P0
    lda #>test_str_pat_edge__lead
    sta X16_P1
    lda #<test_str_pat_edge__hello
    ldx #>test_str_pat_edge__hello
    jsr str_pattern_match
    bcc test_str_pat_edge__fail
    lda #0
    bra test_str_pat_edge__report
test_str_pat_edge__fail:
    lda #1
test_str_pat_edge__report:
    ldx #<test_str_pat_edge__name
    ldy #>test_str_pat_edge__name
    jmp t_result
test_str_pat_edge__stars: .text "*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*"
    .byte 0
test_str_pat_edge__evil: .text "a*a*a*a*b"
    .byte 0
test_str_pat_edge__aaa: .text "aaaaaaaaaaaaaaaaaaaaaaaa"
    .byte 0
test_str_pat_edge__star1: .text "*"
    .byte 0
test_str_pat_edge__empty: .byte 0
test_str_pat_edge__lead: .text "*llo"
    .byte 0
test_str_pat_edge__hello: .text "hello"
    .byte 0
test_str_pat_edge__name: .text "STR_PAT_EDGE"
    .byte 0

// =====================================================================
// One byte stored is not empty, but it is not a word either: the word
// readers used to sail past the documented isempty guard and leave the
// pointer above the data for the rest of the run.
// =====================================================================
test_word_underflow:
    lda #6
    jsr stack_init
    lda #$5A
    jsr stack_push              // exactly one byte
    jsr stack_isempty
    bcs test_word_underflow__fail                   // ...so isempty says there IS something
    jsr stack_popw
    bcc test_word_underflow__fail                   // but a word must be refused
    jsr stack_size
    cmp #1                      // and nothing may have moved
    bne test_word_underflow__fail
    cpx #0
    bne test_word_underflow__fail
    jsr stack_pop               // the byte itself still comes back
    cmp #$5A
    bne test_word_underflow__fail

    lda #7
    jsr ring_init
    lda #$A5
    jsr ring_put
    jsr ring_isempty
    bcs test_word_underflow__fail
    jsr ring_getw
    bcc test_word_underflow__fail
    jsr ring_size
    cmp #1
    bne test_word_underflow__fail
    cpx #0
    bne test_word_underflow__fail
    jsr ring_get
    cmp #$A5
    bne test_word_underflow__fail
    lda #0
    bra test_word_underflow__report
test_word_underflow__fail:
    lda #1
test_word_underflow__report:
    ldx #<test_word_underflow__name
    ldy #>test_word_underflow__name
    jmp t_result
test_word_underflow__name: .text "WORD_UNDERFLOW"
    .byte 0

#import "x16_code.asm"
