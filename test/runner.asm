;ACME
; =====================================================================
; x16lib :: test/runner.asm -- on-target regression tests
; =====================================================================
;   .\build.ps1 -Test
;
; Every test drives the library one way and verifies through an
; independent path (write via port 0, read back via port 1), so a bug in
; the address plumbing cannot hide behind itself.
; =====================================================================

!cpu 65c02
!source "x16.asm"

X16_USE_ALL = 1

; Scratch VRAM well clear of the text screen ($1B000) and of VERA's own
; registers ($1F9C0+).
TESTVRAM = $04000

; The harness's zero-page pointer. Declared here, before anything uses
; it, so ACME sizes the addressing mode on the first pass; testlib.asm
; picks up this value rather than its own default.
T_ZP = $70

* = $0801
    +basic_stub

; ---------------------------------------------------------------------
main
    jsr t_init

    jsr test_fill
    jsr test_fill_zero
    jsr test_fill_stride
    jsr test_copy
    jsr test_dcsel_preserves_addrsel
    jsr test_has_fx
    jsr test_border
    jsr test_palette
    jsr test_sprite_pos
    jsr test_sprite_image
    jsr test_mul88
    jsr test_mul88_negative
    jsr test_collide_overlap
    jsr test_collide_apart
    jsr test_collide_touching
    jsr test_tile_addr
    jsr test_tile_roundtrip
    jsr test_irq_hook
    jsr test_vsync_counter
    jsr test_fx_mult
    jsr test_fx_mult_signed
    jsr test_fx_accum_dirty
    jsr test_fx_fill
    jsr test_bank_roundtrip
    jsr test_bank_boundary
    jsr test_gfx_pset
    jsr test_gfx_clip
    jsr test_gfx_vline
    jsr test_gfx_line
    jsr test_psg_regs
    jsr test_pcm_rate_clamp
    jsr test_ym_write
    jsr test_bits
    jsr test_number_dec
    jsr test_number_hex
    jsr test_number_parse
    jsr test_fs_roundtrip
    jsr test_cls_clears
    jsr test_color_reaches_vram

    jsr t_summary
    rts

; =====================================================================
; vera_fill writes exactly `count` bytes and not one more.
; =====================================================================
test_fill
    ; Poison 200 bytes with $00 so a runaway fill is visible.
    +vera_addr 0, TESTVRAM, VERA_INC_1
    lda #$00
    ldx #200
    ldy #0
    jsr vera_fill

    ; Fill the first 100 with $AB.
    +vera_addr 0, TESTVRAM, VERA_INC_1
    lda #$AB
    ldx #100
    ldy #0
    jsr vera_fill

    ; Read back through the OTHER port.
    +vera_addr 1, TESTVRAM, VERA_INC_1
    lda #$AB
    ldx #100
    jsr t_vcmp_const
    bne @fail

    ; The 101st byte must still be $00.
    lda VERA_DATA1              ; port 1 has auto-advanced to byte 100
    cmp #$00
    bne @fail

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "VERA_FILL", $00

; =====================================================================
; A count of 0 must write nothing at all.  The 16-bit loop rounds a
; zero low byte up to a full page, so this is the edge case that breaks
; a naive implementation.
; =====================================================================
test_fill_zero
    +vera_addr 0, TESTVRAM, VERA_INC_1
    lda #$11
    ldx #4
    ldy #0
    jsr vera_fill

    +vera_addr 0, TESTVRAM, VERA_INC_1
    lda #$EE
    ldx #0                      ; count = 0
    ldy #0
    jsr vera_fill

    +vera_addr 1, TESTVRAM, VERA_INC_1
    lda #$11
    ldx #4
    jsr t_vcmp_const
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "VERA_FILL_ZERO_COUNT", $00

; =====================================================================
; The ADDR_H increment field is an INDEX, not a byte count.
; VERA_INC_2 must step by 2, leaving the odd bytes untouched.
; =====================================================================
test_fill_stride
    ; Clear 32 bytes.
    +vera_addr 0, TESTVRAM, VERA_INC_1
    lda #$00
    ldx #32
    ldy #0
    jsr vera_fill

    ; Write 8 bytes of $55, stepping by 2.
    +vera_addr 0, TESTVRAM, VERA_INC_2
    lda #$55
    ldx #8
    ldy #0
    jsr vera_fill

    ; Even offsets are $55, odd offsets are still $00.
    ; Read linearly and check the alternation.
    +vera_addr 1, TESTVRAM, VERA_INC_1
    ldx #8
@loop
    lda VERA_DATA1              ; even offset
    cmp #$55
    bne @fail
    lda VERA_DATA1              ; odd offset
    cmp #$00
    bne @fail
    dex
    bne @loop

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "VERA_INC_STRIDE", $00

; =====================================================================
; vera_copy streams through both data ports at once.
; =====================================================================
test_copy
    ; Lay down a known ramp at TESTVRAM.
    +vera_addr 0, TESTVRAM, VERA_INC_1
    ldx #0
@write
    txa
    sta VERA_DATA0
    inx
    cpx #100
    bne @write

    ; Copy it 1 KB further along: port 0 reads, port 1 writes.
    +vera_addr 0, TESTVRAM, VERA_INC_1
    +vera_addr 1, TESTVRAM + $400, VERA_INC_1
    ldx #100
    ldy #0
    jsr vera_copy

    ; Verify the destination holds the same ramp.
    +vera_addr 1, TESTVRAM + $400, VERA_INC_1
    ldx #0
@check
    lda VERA_DATA1
    stx X16_T3
    cmp X16_T3
    bne @fail
    inx
    cpx #100
    bne @check

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "VERA_COPY", $00

; =====================================================================
; +vera_dcsel must not clobber ADDRSEL.  CTRL packs RESET(7),
; DCSEL(6:1) and ADDRSEL(0) into one byte, so a naive `sta VERA_CTRL`
; silently switches the active address port out from under the caller.
; =====================================================================
test_dcsel_preserves_addrsel
    +vera_addrsel 1             ; ADDRSEL = 1
    +vera_dcsel 2               ; select the FX register bank

    lda VERA_CTRL
    and #VERA_CTRL_ADDRSEL
    beq @fail                   ; ADDRSEL got cleared -> bug

    lda VERA_CTRL
    and #VERA_CTRL_DCSEL
    cmp #(2 << 1)
    bne @fail                   ; DCSEL didn't take

    ; And the other direction: changing ADDRSEL must not disturb DCSEL.
    +vera_addrsel 0
    lda VERA_CTRL
    and #VERA_CTRL_DCSEL
    cmp #(2 << 1)
    bne @fail

    +vera_dcsel 0
    lda #0
    bra @report
@fail
    +vera_dcsel 0
    +vera_addrsel 0
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "DCSEL_KEEPS_ADDRSEL", $00

; =====================================================================
; vera_has_fx probes DCSEL=63 and must leave DCSEL back at 0.
; =====================================================================
test_has_fx
    +vera_addrsel 0
    +vera_dcsel 0
    jsr vera_has_fx
    bcc @fail                   ; r49 emulator has FX

    lda VERA_CTRL               ; DCSEL must be back to 0
    and #VERA_CTRL_DCSEL
    bne @fail

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "VERA_HAS_FX", $00

; =====================================================================
; screen_border must select DCSEL=0 before writing DC_BORDER -- at
; DCSEL=2 that same address is FX_MULT.
; =====================================================================
test_border
    +vera_dcsel 2               ; leave a hostile DCSEL behind
    lda #7
    jsr screen_border

    +vera_dcsel 0
    lda VERA_DC_BORDER
    cmp #7
    bne @fail

    lda #6                      ; restore the default border
    jsr screen_border
    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "SCREEN_BORDER", $00

; =====================================================================
; A 12-bit $0RGB colour stores little-endian into a palette entry.
; =====================================================================
test_palette
    ldx #1
    lda #$00                    ; green/blue nibbles
    ldy #$0F                    ; red nibble  -> $0F00, pure red
    jsr pal_set

    +vera_addr 1, VRAM_PALETTE + 2, VERA_INC_1
    lda VERA_DATA1
    cmp #$00
    bne @fail
    lda VERA_DATA1
    cmp #$0F
    bne @fail

    ; Put entry 1 back to white so the rest of the run is readable.
    ldx #1
    lda #$FF
    ldy #$0F
    jsr pal_set
    lda #0
    bra @report
@fail
    ldx #1
    lda #$FF
    ldy #$0F
    jsr pal_set
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "PAL_SET", $00

; =====================================================================
; A sprite's 10-bit X and Y split across two bytes each.  Write via
; sprite_pos, read back via sprite_get_pos, and also check the raw
; record so a symmetrical bug in both cannot hide.
; =====================================================================
test_sprite_pos
    jsr sprite_init_all

    lda #<$0123
    sta X16_P0
    lda #>$0123
    sta X16_P1
    lda #<$00A5
    sta X16_P2
    lda #>$00A5
    sta X16_P3
    ldx #3
    jsr sprite_pos

    ; Independent read of sprite 3's record, bytes 2..5.
    +vera_addr 1, VRAM_SPRITE_ATTR + (3 * 8) + 2, VERA_INC_1
    lda VERA_DATA1
    cmp #$23                    ; X low
    bne @fail
    lda VERA_DATA1
    cmp #$01                    ; X high, masked to 2 bits
    bne @fail
    lda VERA_DATA1
    cmp #$A5                    ; Y low
    bne @fail
    lda VERA_DATA1
    cmp #$00                    ; Y high
    bne @fail

    ; And the round trip.
    stz X16_P0
    stz X16_P1
    stz X16_P2
    stz X16_P3
    ldx #3
    jsr sprite_get_pos
    lda X16_P0
    cmp #$23
    bne @fail
    lda X16_P1
    cmp #$01
    bne @fail
    lda X16_P2
    cmp #$A5
    bne @fail

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "SPRITE_POS", $00

; =====================================================================
; The image address is stored as bits 16:5 across two bytes.
; $13000 (the KERNAL's sprite data area) must encode as $80/$09:
;   byte0 = addr 12:5  = ($13000 >> 5)  & $FF = $80
;   byte1 = addr 16:13 = ($13000 >> 13) & $0F = $09, plus mode bit 7
; =====================================================================
test_sprite_image
    jsr sprite_init_all

    lda #<VRAM_SPRITE_DATA
    sta X16_P0
    lda #>VRAM_SPRITE_DATA
    sta X16_P1
    lda #^VRAM_SPRITE_DATA
    sta X16_P2
    ldx #5
    lda #SPRITE_MODE_8BPP
    jsr sprite_image

    +vera_addr 1, VRAM_SPRITE_ATTR + (5 * 8), VERA_INC_1
    lda VERA_DATA1
    cmp #$80
    bne @fail
    lda VERA_DATA1
    cmp #(SPRITE_MODE_8BPP | $09)
    bne @fail

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "SPRITE_IMAGE", $00

; =====================================================================
; 8.8 fixed point: 1.5 * 2.0 = 3.0, i.e. 384 * 512 >> 8 = 768.
; =====================================================================
test_mul88
    lda #<384
    sta X16_P0
    lda #>384
    sta X16_P1
    lda #<512
    sta X16_P2
    lda #>512
    sta X16_P3
    jsr mul88

    lda X16_P0
    cmp #<768
    bne @fail
    lda X16_P1
    cmp #>768
    bne @fail

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "MUL88", $00

; =====================================================================
; -1.5 * 2.0 = -3.0.  One negative operand must flip the sign exactly
; once; two negatives must not flip it at all.
; =====================================================================
test_mul88_negative
    lda #<-384
    sta X16_P0
    lda #>-384
    sta X16_P1
    lda #<512
    sta X16_P2
    lda #>512
    sta X16_P3
    jsr mul88
    lda X16_P0
    cmp #<-768
    bne @fail
    lda X16_P1
    cmp #>-768
    bne @fail

    ; Both negative: -1.5 * -2.0 = +3.0
    lda #<-384
    sta X16_P0
    lda #>-384
    sta X16_P1
    lda #<-512
    sta X16_P2
    lda #>-512
    sta X16_P3
    jsr mul88
    lda X16_P0
    cmp #<768
    bne @fail
    lda X16_P1
    cmp #>768
    bne @fail

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "MUL88_SIGNED", $00

; =====================================================================
; collide8: boxes that genuinely overlap.
; =====================================================================
test_collide_overlap
    lda #0   : sta X16_P0       ; ax
    lda #0   : sta X16_P1       ; ay
    lda #10  : sta X16_P2       ; aw
    lda #10  : sta X16_P3       ; ah
    lda #5   : sta X16_P4       ; bx
    lda #5   : sta X16_P5       ; by
    lda #10  : sta X16_P6       ; bw
    lda #10  : sta X16_P7       ; bh
    jsr collide8
    lda #0
    bcs @report                 ; carry set = overlap = pass
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "COLLIDE_OVERLAP", $00

; =====================================================================
; collide8: boxes nowhere near each other.
; =====================================================================
test_collide_apart
    lda #0   : sta X16_P0
    lda #0   : sta X16_P1
    lda #10  : sta X16_P2
    lda #10  : sta X16_P3
    lda #20  : sta X16_P4
    lda #20  : sta X16_P5
    lda #5   : sta X16_P6
    lda #5   : sta X16_P7
    jsr collide8
    lda #0
    bcc @report                 ; carry clear = no overlap = pass
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "COLLIDE_APART", $00

; =====================================================================
; collide8: edges that merely touch must NOT count as a collision.
; Box A spans x 0..9, box B starts at x 10.  This is the case a naive
; `<=` comparison gets wrong, and it is what GAME.TXT specifies.
; =====================================================================
test_collide_touching
    lda #0   : sta X16_P0
    lda #0   : sta X16_P1
    lda #10  : sta X16_P2
    lda #10  : sta X16_P3
    lda #10  : sta X16_P4       ; exactly at A's right edge
    lda #0   : sta X16_P5
    lda #10  : sta X16_P6
    lda #10  : sta X16_P7
    jsr collide8
    lda #0
    bcc @report
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "COLLIDE_TOUCHING", $00

; =====================================================================
; tile_setptr must derive the cell address from L1_CONFIG / L1_MAPBASE,
; not from a hardcoded screen width.  With the KERNAL's default text
; setup (L1_CONFIG = $60 -> 128-wide map, MAPBASE = $D8 -> $1B000),
; cell (col 5, row 3) is at $1B000 + (3*128 + 5)*2 = $1B30A.
;
; Verified by writing through tile_put and reading the absolute address
; back through the other port -- if tile_setptr computed the wrong cell,
; a tile_get using the same wrong maths would agree with it and hide the
; bug.
; =====================================================================
test_tile_addr
    lda #$41                    ; screen code
    sta X16_P0
    lda #$12                    ; attribute
    sta X16_P1
    ldx #5                      ; column
    ldy #3                      ; row
    jsr tile_put

    +vera_addr 1, $1B30A, VERA_INC_1
    lda VERA_DATA1
    cmp #$41
    bne @fail
    lda VERA_DATA1
    cmp #$12
    bne @fail

    ; And confirm the map really is configured the way we assumed.
    lda VERA_L1_CONFIG
    cmp #$60
    bne @fail
    lda VERA_L1_MAPBASE
    cmp #$D8
    bne @fail

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "TILE_ADDR", $00

; =====================================================================
; tile_put / tile_get round trip, at a cell far enough along that the
; row shift and the column add both matter.
; =====================================================================
test_tile_roundtrip
    lda #$5A
    sta X16_P0
    lda #$3C
    sta X16_P1
    ldx #77                     ; column
    ldy #9                      ; row
    jsr tile_put

    ldx #77
    ldy #9
    jsr tile_get                ; A = code, X = attribute
    cmp #$5A
    bne @fail
    cpx #$3C
    bne @fail

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "TILE_ROUNDTRIP", $00

; =====================================================================
; irq_install must hook CINV, save the real previous vector, and be
; idempotent.  A second install without the irq_armed guard would store
; irq_handler as its own "previous" vector -- so the handler's chaining
; jmp (irq_old_vector) would jump to itself and hang the machine, and
; irq_remove would leave our handler installed forever.
;
; Fully testable headless: no interrupt needs to fire.
; =====================================================================
test_irq_hook
    lda CINV
    sta @old
    lda CINV+1
    sta @old+1

    jsr irq_install
    lda CINV
    cmp #<irq_handler
    bne @fail
    lda CINV+1
    cmp #>irq_handler
    bne @fail

    jsr irq_install             ; second install must change nothing
    lda irq_old_vector
    cmp @old
    bne @fail
    lda irq_old_vector+1
    cmp @old+1
    bne @fail

    jsr irq_remove
    lda CINV
    cmp @old
    bne @fail
    lda CINV+1
    cmp @old+1
    bne @fail

    lda #0
    bra @report
@fail
    jsr irq_remove
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@old  !word 0
@name !text "IRQ_HOOK", $00

; =====================================================================
; The VSYNC hook must actually tick -- where VSYNC exists at all.
;
; x16emu's -testbench mode is headless: it runs no video, so VERA never
; raises a VSYNC interrupt and the KERNAL's jiffy clock stands still.
; That is a property of the harness, not a bug in irq.asm, so use the
; jiffy clock (RDTIM, which only advances inside the IRQ) as an
; INDEPENDENT oracle:
;
;   frames advanced           -> pass
;   frames stuck, jiffy stuck -> no interrupts here at all -> skip
;   frames stuck, jiffy moved -> interrupts ran, our counter did not
;                                -> a real bug -> fail
;
; Bounded spin rather than a blocking vsync_wait, so a broken counter
; reports a failure instead of hanging the harness until its timeout.
; The spin is ~460k cycles, several frames at 8 MHz.
; =====================================================================
test_vsync_counter
    jsr irq_install
    jsr RDTIM                   ; A = jiffy bits 0-7
    sta @jiffy0
    jsr irq_frames
    sta @start

    ldy #0
@outer
    ldx #0
@inner
    jsr irq_frames
    sec
    sbc @start                  ; byte subtraction wraps correctly
    cmp #2
    bcs @ok                     ; two frames elapsed
    dex
    bne @inner
    dey
    bne @outer

    ; Counter never moved. Did anything interrupt at all?
    jsr RDTIM
    sec
    sbc @jiffy0
    beq @skip                   ; jiffy frozen: this machine has no VSYNC
    jsr irq_remove
    lda #1                      ; jiffy moved but we missed every frame
    bra @report
@skip
    jsr irq_remove
    lda #<@name
    ldx #>@name
    jmp t_skip
@ok
    jsr irq_remove
    lda #0
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@jiffy0 !byte 0
@start  !byte 0
@name   !text "VSYNC_COUNTER", $00

; =====================================================================
; The FX hardware multiplier: 1000 * 1000 = 1000000 = $000F4240.
; Cross-checked against the software umul16, so the two independent
; implementations have to agree.
; =====================================================================
test_fx_mult
    jsr vera_has_fx
    bcc @skip

    lda #<1000
    sta X16_P0
    lda #>1000
    sta X16_P1
    lda #<1000
    sta X16_P2
    lda #>1000
    sta X16_P3
    jsr fx_mult

    lda X16_P4
    cmp #$40
    bne @fail
    lda X16_P5
    cmp #$42
    bne @fail
    lda X16_P6
    cmp #$0F
    bne @fail
    lda X16_P7
    cmp #$00
    bne @fail

    ; Same product through the software path.
    lda #<1000
    sta X16_P0
    lda #>1000
    sta X16_P1
    lda #<1000
    sta X16_P2
    lda #>1000
    sta X16_P3
    jsr umul16
    lda X16_P4
    cmp #$40
    bne @fail
    lda X16_P5
    cmp #$42
    bne @fail
    lda X16_P6
    cmp #$0F
    bne @fail
    lda X16_P7
    cmp #$00
    bne @fail

    lda #0
    bra @report
@skip
    lda #<@name
    ldx #>@name
    jmp t_skip
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "FX_MULT", $00

; =====================================================================
; The FX multiplier is signed: -1000 * 1000 = -1000000 = $FFF0BDC0.
; =====================================================================
test_fx_mult_signed
    jsr vera_has_fx
    bcc @skip

    lda #<-1000
    sta X16_P0
    lda #>-1000
    sta X16_P1
    lda #<1000
    sta X16_P2
    lda #>1000
    sta X16_P3
    jsr fx_mult

    lda X16_P4
    cmp #$C0
    bne @fail
    lda X16_P5
    cmp #$BD
    bne @fail
    lda X16_P6
    cmp #$F0
    bne @fail
    lda X16_P7
    cmp #$FF
    bne @fail

    lda #0
    bra @report
@skip
    lda #<@name
    ldx #>@name
    jmp t_skip
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "FX_MULT_SIGNED", $00

; =====================================================================
; The FX multiplier adds its result to the accumulator before writing it
; out, so fx_mult must clear the accumulator first (by reading
; FX_ACCUM_RESET). Dirty the accumulator on purpose -- multiply 300*300
; with the Accumulate bit set -- then check a plain fx_mult is still
; exact. Without the reset this returns 1000000 + 90000.
; =====================================================================
test_fx_accum_dirty
    jsr vera_has_fx
    bcc @skip

    ; Multiply-and-accumulate 300 * 300 to leave 90000 in the accumulator.
    +vera_dcsel 2
    stz VERA_FX_CTRL
    lda #(VERA_FX_MULT_ENABLE | VERA_FX_MULT_ACCUMULATE)
    sta VERA_FX_MULT
    +vera_dcsel 6
    lda #<300
    sta VERA_FX_CACHE_L
    lda #>300
    sta VERA_FX_CACHE_M
    lda #<300
    sta VERA_FX_CACHE_H
    lda #>300
    sta VERA_FX_CACHE_U
    lda VERA_FX_ACCUM           ; a read triggers the accumulate
    jsr fx_off

    ; A clean multiply must be unaffected by that leftover state.
    lda #<1000
    sta X16_P0
    lda #>1000
    sta X16_P1
    lda #<1000
    sta X16_P2
    lda #>1000
    sta X16_P3
    jsr fx_mult

    lda X16_P4
    cmp #$40
    bne @fail
    lda X16_P5
    cmp #$42
    bne @fail
    lda X16_P6
    cmp #$0F
    bne @fail
    lda X16_P7
    cmp #$00
    bne @fail

    lda #0
    bra @report
@skip
    lda #<@name
    ldx #>@name
    jmp t_skip
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "FX_ACCUM_RESET", $00

; =====================================================================
; fx_fill writes four bytes per store through the 32-bit cache. Use a
; count of 10, which is not a multiple of 4, so the 2-byte tail path
; runs too -- and check byte 11 is untouched.
; =====================================================================
test_fx_fill
    jsr vera_has_fx
    bcc @skip

    +vera_addr 0, TESTVRAM + $100, VERA_INC_1
    lda #$00
    ldx #16
    ldy #0
    jsr vera_fill

    lda #<(TESTVRAM + $100)
    sta X16_P0
    lda #>(TESTVRAM + $100)
    sta X16_P1
    lda #^(TESTVRAM + $100)
    sta X16_P2
    lda #10
    sta X16_P3
    lda #0
    sta X16_P4
    lda #$C3
    jsr fx_fill

    +vera_addr 1, TESTVRAM + $100, VERA_INC_1
    lda #$C3
    ldx #10
    jsr t_vcmp_const
    bne @fail
    lda VERA_DATA1              ; the 11th byte must still be zero
    cmp #$00
    bne @fail

    lda #0
    bra @report
@skip
    lda #<@name
    ldx #>@name
    jmp t_skip
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "FX_FILL", $00

; =====================================================================
; mem_to_bank / bank_to_mem round trip, and RAM_BANK must come back the
; way the caller left it.
; =====================================================================
test_bank_roundtrip
    lda RAM_BANK
    sta @saved
    lda #3
    sta RAM_BANK                ; a bank the copy must restore

    lda #<@src
    sta X16_P0
    lda #>@src
    sta X16_P1
    lda #5
    sta X16_P2                  ; destination bank
    lda #<100
    sta X16_P3
    lda #>100
    sta X16_P4                  ; destination offset
    lda #8
    sta X16_P5
    lda #0
    sta X16_P6
    jsr mem_to_bank

    lda RAM_BANK
    cmp #3
    bne @fail                   ; caller's bank was not restored

    lda #5
    sta X16_P0
    lda #<100
    sta X16_P1
    lda #>100
    sta X16_P2
    lda #<@dst
    sta X16_P3
    lda #>@dst
    sta X16_P4
    lda #8
    sta X16_P5
    lda #0
    sta X16_P6
    jsr bank_to_mem

    ldx #0
@cmp
    lda @src,x
    cmp @dst,x
    bne @fail
    inx
    cpx #8
    bne @cmp

    lda @saved
    sta RAM_BANK
    lda #0
    bra @report
@fail
    lda @saved
    sta RAM_BANK
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@src   !byte $10, $21, $32, $43, $54, $65, $76, $87
@dst   !fill 8, 0
@saved !byte 0
@name  !text "BANK_ROUNDTRIP", $00

; =====================================================================
; A copy starting at offset 8190 must spill into the next bank: two
; bytes land at the end of bank 5, two at the start of bank 6.
; Verified with bank_peek, which selects each bank independently.
; =====================================================================
test_bank_boundary
    lda RAM_BANK
    sta @saved

    lda #<@pat
    sta X16_P0
    lda #>@pat
    sta X16_P1
    lda #5
    sta X16_P2
    lda #<8190
    sta X16_P3
    lda #>8190
    sta X16_P4
    lda #4
    sta X16_P5
    lda #0
    sta X16_P6
    jsr mem_to_bank

    lda #<8190
    sta X16_P0
    lda #>8190
    sta X16_P1
    lda #5
    jsr bank_peek
    cmp #$AA
    bne @fail

    lda #<8191
    sta X16_P0
    lda #>8191
    sta X16_P1
    lda #5
    jsr bank_peek
    cmp #$BB
    bne @fail

    stz X16_P0                  ; bank 6, offset 0
    stz X16_P1
    lda #6
    jsr bank_peek
    cmp #$CC
    bne @fail

    lda #1
    sta X16_P0
    stz X16_P1
    lda #6
    jsr bank_peek
    cmp #$DD
    bne @fail

    lda @saved
    sta RAM_BANK
    lda #0
    bra @report
@fail
    lda @saved
    sta RAM_BANK
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@pat   !byte $AA, $BB, $CC, $DD
@saved !byte 0
@name  !text "BANK_BOUNDARY", $00

; =====================================================================
; A bitmap pixel is at y*320 + x. (100, 50) is 50*320+100 = 16100.
; =====================================================================
test_gfx_pset
    lda #<100
    sta X16_P0
    lda #>100
    sta X16_P1
    lda #50
    sta X16_P2
    lda #$5A
    sta X16_P3
    jsr gfx_pset

    +vera_addr 1, VRAM_BITMAP + 16100, VERA_INC_1
    lda VERA_DATA1
    cmp #$5A
    bne @fail
    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "GFX_PSET", $00

; =====================================================================
; gfx_pset clips. x = 320 is off the right edge; unclipped it would
; write y*320 + 320, which is the first pixel of the NEXT row -- a bug
; that looks like a stray dot rather than a crash. Same for y = 240.
; =====================================================================
test_gfx_clip
    ; Sentinel where an unclipped (320, 0) would land: offset 320.
    +vera_addr 0, VRAM_BITMAP + 320, VERA_INC_1
    lda #$11
    sta VERA_DATA0
    lda #<320
    sta X16_P0
    lda #>320
    sta X16_P1
    stz X16_P2
    lda #$99
    sta X16_P3
    jsr gfx_pset

    +vera_addr 1, VRAM_BITMAP + 320, VERA_INC_1
    lda VERA_DATA1
    cmp #$11
    bne @fail                   ; the clip did not hold

    ; Sentinel where an unclipped (0, 240) would land: offset 76800.
    +vera_addr 0, VRAM_BITMAP + 76800, VERA_INC_1
    lda #$22
    sta VERA_DATA0
    stz X16_P0
    stz X16_P1
    lda #240
    sta X16_P2
    lda #$99
    sta X16_P3
    jsr gfx_pset

    +vera_addr 1, VRAM_BITMAP + 76800, VERA_INC_1
    lda VERA_DATA1
    cmp #$22
    bne @fail

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "GFX_CLIP", $00

; =====================================================================
; gfx_vline walks the column with VERA_INC_320, so pixels land 320
; bytes apart: (3,1) then +320 each. Check the neighbours stay clear.
; =====================================================================
test_gfx_vline
    +vera_addr 0, VRAM_BITMAP + 320, VERA_INC_1
    lda #$00
    ldx #<1600
    ldy #>1600
    jsr vera_fill               ; clear rows 1..5

    lda #3
    sta X16_P0
    stz X16_P1
    lda #1
    sta X16_P2
    lda #$88
    sta X16_P3
    lda #4
    sta X16_P4
    jsr gfx_vline

    ; Four pixels, 320 bytes apart, starting at 1*320 + 3 = 323.
    ; Each is followed by an untouched neighbour.
    +vera_addr 1, VRAM_BITMAP + 323, VERA_INC_1
    lda VERA_DATA1
    cmp #$88
    bne @fail_far
    lda VERA_DATA1
    cmp #$00
    bne @fail_far

    +vera_addr 1, VRAM_BITMAP + 643, VERA_INC_1
    lda VERA_DATA1
    cmp #$88
    bne @fail_far
    lda VERA_DATA1
    cmp #$00
    bne @fail_far
    bra @rest

@fail_far                       ; @fail is out of branch range from here
    jmp @fail

@rest
    +vera_addr 1, VRAM_BITMAP + 963, VERA_INC_1
    lda VERA_DATA1
    cmp #$88
    bne @fail
    lda VERA_DATA1
    cmp #$00
    bne @fail

    +vera_addr 1, VRAM_BITMAP + 1283, VERA_INC_1
    lda VERA_DATA1
    cmp #$88
    bne @fail
    lda VERA_DATA1
    cmp #$00
    bne @fail

    ; and the fifth row must be clear -- the length was 4
    +vera_addr 1, VRAM_BITMAP + 1603, VERA_INC_1
    lda VERA_DATA1
    cmp #$00
    bne @fail

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "GFX_VLINE", $00

; =====================================================================
; gfx_line, Bresenham. A pure diagonal (0,0)-(3,3) must hit exactly
; (0,0) (1,1) (2,2) (3,3), i.e. offsets 0, 321, 642, 963.
; =====================================================================
test_gfx_line
    +vera_addr 0, VRAM_BITMAP, VERA_INC_1
    lda #$00
    ldx #<1300
    ldy #>1300
    jsr vera_fill

    stz X16_P0                  ; x0
    stz X16_P1
    stz X16_P2                  ; y0
    lda #3                      ; x1
    sta X16_P3
    stz X16_P4
    lda #3                      ; y1
    sta X16_P5
    lda #$C7                    ; colour
    sta X16_P6
    jsr gfx_line

    +vera_addr 1, VRAM_BITMAP + 0, VERA_INC_1
    lda VERA_DATA1
    cmp #$C7
    bne @fail
    lda VERA_DATA1              ; (1,0) must stay clear
    cmp #$00
    bne @fail

    +vera_addr 1, VRAM_BITMAP + 321, VERA_INC_1
    lda VERA_DATA1
    cmp #$C7
    bne @fail
    +vera_addr 1, VRAM_BITMAP + 642, VERA_INC_1
    lda VERA_DATA1
    cmp #$C7
    bne @fail
    +vera_addr 1, VRAM_BITMAP + 963, VERA_INC_1
    lda VERA_DATA1
    cmp #$C7
    bne @fail

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "GFX_LINE", $00

; =====================================================================
; PSG voice 3 lives at $1F9C0 + 3*4 = $1F9CC.
;   byte 2 = right|left|volume  -> $C0 | 63 = $FF
;   byte 3 = waveform<<6 | pw   -> triangle ($80) | 32 = $A0
; =====================================================================
test_psg_regs
    jsr psg_init

    ldx #3
    lda #<$04A5
    sta X16_P0
    lda #>$04A5
    sta X16_P1
    jsr psg_set_freq

    ldx #3
    lda #63
    ldy #PSG_PAN_BOTH
    jsr psg_set_vol

    ldx #3
    lda #PSG_WAVE_TRIANGLE
    ldy #32
    jsr psg_set_wave

    +vera_addr 1, VRAM_PSG + (3 * 4), VERA_INC_1
    lda VERA_DATA1
    cmp #$A5
    bne @fail
    lda VERA_DATA1
    cmp #$04
    bne @fail
    lda VERA_DATA1
    cmp #$FF
    bne @fail
    lda VERA_DATA1
    cmp #$A0
    bne @fail

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "PSG_REGS", $00

; =====================================================================
; AUDIO_RATE above 128 is invalid, so pcm_rate clamps. Checked on the
; returned A rather than by reading the register back, so the test does
; not depend on that register being readable.
; =====================================================================
test_pcm_rate_clamp
    lda #200
    jsr pcm_rate
    cmp #128
    bne @fail

    lda #64
    jsr pcm_rate
    cmp #64
    bne @fail

    lda #0                      ; stop playback again
    jsr pcm_rate

    jsr pcm_empty               ; nothing was pushed: the FIFO is empty
    bcc @fail

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "PCM_RATE_CLAMP", $00

; =====================================================================
; ym_write must complete rather than time out on the busy flag.
; =====================================================================
test_ym_write
    lda #$00                    ; value
    ldx #$20                    ; RL/FB/CONNECT for channel 0
    jsr ym_write
    bcs @fail                   ; carry set = the chip stayed busy

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "YM_WRITE", $00

; =====================================================================
; Bit and nibble helpers.
; =====================================================================
test_bits
    lda #$0A
    ldx #$05
    jsr catnib
    cmp #$A5
    bne @fail

    lda #$A5
    jsr hinib
    cmp #$0A
    bne @fail
    lda #$A5
    jsr lonib
    cmp #$05
    bne @fail

    lda #<@cell
    sta X16_PTR0
    lda #>@cell
    sta X16_PTR0+1

    lda #$00
    sta @cell
    lda #%00000110
    jsr bit_set
    lda @cell
    cmp #%00000110
    bne @fail

    lda #%00000010
    jsr bit_clr
    lda @cell
    cmp #%00000100
    bne @fail

    lda #%00000100
    jsr bit_test
    beq @fail                   ; the bit is set, so Z must be clear
    lda #%00001000
    jsr bit_test
    bne @fail                   ; that bit is clear

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@cell !byte 0
@name !text "BITS", $00

; =====================================================================
; u16_to_dec: no leading zeros, but zero itself still prints "0".
; =====================================================================
test_number_dec
    lda #<65535
    sta X16_P0
    lda #>65535
    sta X16_P1
    jsr u16_to_dec
    cpy #5
    bne @fail
    lda #<@max
    ldx #>@max
    jsr cmp_num_buf
    bcs @fail

    stz X16_P0                  ; zero must not vanish
    stz X16_P1
    jsr u16_to_dec
    cpy #1
    bne @fail
    lda #<@zero
    ldx #>@zero
    jsr cmp_num_buf
    bcs @fail

    lda #<1000                  ; interior zeros must survive
    sta X16_P0
    lda #>1000
    sta X16_P1
    jsr u16_to_dec
    cpy #4
    bne @fail
    lda #<@thou
    ldx #>@thou
    jsr cmp_num_buf
    bcs @fail

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@max  !text "65535", $00
@zero !text "0", $00
@thou !text "1000", $00
@name !text "NUMBER_DEC", $00

; =====================================================================
test_number_hex
    lda #<$BEEF
    sta X16_P0
    lda #>$BEEF
    sta X16_P1
    jsr u16_to_hex
    cpy #4
    bne @fail
    lda #<@beef
    ldx #>@beef
    jsr cmp_num_buf
    bcs @fail

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@beef !text "BEEF", $00
@name !text "NUMBER_HEX", $00

; =====================================================================
test_number_parse
    lda #<@good
    sta X16_P0
    lda #>@good
    sta X16_P1
    lda #4
    sta X16_P2
    jsr dec_to_u16
    bcs @fail
    lda X16_P4
    cmp #<1234
    bne @fail
    lda X16_P5
    cmp #>1234
    bne @fail

    lda #<@bad                  ; a non-digit must be rejected
    sta X16_P0
    lda #>@bad
    sta X16_P1
    lda #4
    sta X16_P2
    jsr dec_to_u16
    bcc @fail

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@good !text "1234"
@bad  !text "12A4"
@name !text "NUMBER_PARSE", $00

; =====================================================================
; Save a block to device 8, load it back to a different address, and
; compare. build.ps1 points -fsroot at test\fsroot, so this touches a
; scratch directory rather than a real SD-card image.
; =====================================================================
test_fs_roundtrip
    lda #<@fname
    sta X16_P0
    lda #>@fname
    sta X16_P1
    lda #@fname_len
    sta X16_P2
    lda #8
    sta X16_P3
    lda #<@src
    sta X16_P5
    lda #>@src
    sta X16_P6
    lda #<(@src + 8)            ; end address, exclusive
    sta X16_T6
    lda #>(@src + 8)
    sta X16_T7
    jsr fs_save
    bcs @fail

    lda #<@fname
    sta X16_P0
    lda #>@fname
    sta X16_P1
    lda #@fname_len
    sta X16_P2
    lda #8
    sta X16_P3
    lda #FS_SA_ADDR             ; ignore the PRG header, load where we say
    sta X16_P4
    lda #<@dst
    sta X16_P5
    lda #>@dst
    sta X16_P6
    jsr fs_load
    bcs @fail

    ldx #0
@cmp
    lda @src,x
    cmp @dst,x
    bne @fail
    inx
    cpx #8
    bne @cmp

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@fname     !text "TESTDATA.BIN"
@fname_len = 12
@src       !byte $DE, $AD, $BE, $EF, $CA, $FE, $BA, $BE
@dst       !fill 8, 0
@name      !text "FS_ROUNDTRIP", $00

; ---------------------------------------------------------------------
; cmp_num_buf -- compare util/number's output buffer against a
; NUL-terminated expected string.
;   in:  A = expected lo, X = expected hi
;   out: carry clear when they match
;
; Uses the harness's own zero-page pointer, not the library's, so a bug
; in the library's scratch cannot make this agree by accident.
; ---------------------------------------------------------------------
cmp_num_buf
    sta T_ZP
    stx T_ZP+1
    ldy #0
@loop
    lda (T_ZP),y
    cmp num_buf,y
    bne @bad
    cmp #0
    beq @ok                     ; both terminated at the same place
    iny
    bne @loop
@bad
    sec
    rts
@ok
    clc
    rts

; =====================================================================
; screen_cls must clear the screen even when entered with port 1
; selected.  Plant a sentinel in the tilemap, clear, and check it went.
; =====================================================================
test_cls_clears
    +vera_addr 0, VRAM_TEXT + (10 * 2), VERA_INC_1
    lda #$AA                    ; sentinel screen code at column 10
    sta VERA_DATA0

    +vera_addrsel 1             ; hostile: leave port 1 selected
    jsr screen_cls

    +vera_addr 1, VRAM_TEXT + (10 * 2), VERA_INC_1
    lda VERA_DATA1
    cmp #$20                    ; a cleared cell holds a space
    bne @fail
    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "CLS_CLEARS", $00

; =====================================================================
; screen_color must actually change what CHROUT puts in VRAM, not just
; poke a KERNAL variable.  Verify through the tilemap attribute byte.
;
; Entered deliberately with ADDRSEL = 1, the state any code that used
; +vera_addr 1 or vera_copy leaves behind. The KERNAL's screen scroller
; writes VERA_ADDR_* before selecting the port, so it corrupts the
; display unless screen_cls forces ADDRSEL = 0 first. Remove that guard
; from video/screen.asm and this test fails.
; =====================================================================
test_color_reaches_vram
    +vera_addrsel 1
    jsr screen_cls
    lda #1                      ; foreground white
    ldx #6                      ; background blue
    jsr screen_color

    +vera_addrsel 1
    ldx #0                      ; row 0
    ldy #0                      ; column 0
    jsr screen_locate

    +vera_addrsel 1
    lda #'X'
    jsr screen_chrout

    ; Cell (0,0) is two bytes: screen code, then attribute.
    +vera_addr 1, VRAM_TEXT, VERA_INC_1
    lda VERA_DATA1
    sta @gotchar
    lda VERA_DATA1
    sta @gotattr

    ; Exactly the screen code for 'X'. Checking merely "not zero" would
    ; accept the blank ($20) left behind when a mis-selected port sends
    ; the character somewhere else entirely.
    lda @gotchar
    cmp #$18
    bne @fail
    lda @gotattr
    cmp #$61                    ; fg 1 | bg 6 << 4
    bne @fail

    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@gotchar !byte 0
@gotattr !byte 0
@name !text "COLOR_TO_VRAM", $00

; ---------------------------------------------------------------------
!source "test/testlib.asm"
!source "x16_code.asm"
