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

    processor 65c02
    include "x16.asm"

; Not X16_USE_ALL: with every module the code alone would push this PRG
; past the $9EFF load ceiling. The modules tested HERE are gated
; explicitly; newer modules (bitmap2, ...) live in runner2.asm, and
; .\build.ps1 -Test runs every runner.
X16_USE_VERA       = 1
X16_USE_SCREEN     = 1
X16_USE_PALETTE    = 1
X16_USE_TILE       = 1
X16_USE_SPRITE     = 1
X16_USE_BITMAP     = 1
X16_USE_VERAFX     = 1
X16_USE_IRQ        = 1
X16_USE_PSG        = 1
X16_USE_YM         = 1
X16_USE_PCM        = 1
X16_USE_PCM_STREAM = 1
X16_USE_INPUT      = 1
X16_USE_BANK       = 1
X16_USE_BANKALLOC  = 1
X16_USE_MEM        = 1
X16_USE_LOAD       = 1
X16_USE_DOS        = 1
X16_USE_BMX        = 1
X16_USE_MATH       = 1
X16_USE_CLIP       = 1
X16_USE_BUFFERS    = 1
X16_USE_ADPCM      = 1
X16_USE_ZX0        = 1
X16_USE_TSC        = 1
X16_USE_FIXED      = 1
X16_USE_COLLIDE    = 1
X16_USE_BITS       = 1
X16_USE_NUMBER     = 1
X16_USE_INT16      = 1
X16_USE_INT32      = 1
X16_USE_FLOAT      = 1

; Scratch VRAM well clear of the text screen ($1B000) and of VERA's own
; registers ($1F9C0+).
TESTVRAM = $04000

; The harness's zero-page pointer. Declared here, before anything uses
; it, so ACME sizes the addressing mode on the first pass; testlib.asm
; picks up this value rather than its own default.
T_ZP = $70

    org $0801
    basic_stub

; ---------------------------------------------------------------------
    SUBROUTINE
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
    jsr test_collide16
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
    jsr test_gfx_read8
    jsr test_gfx_pat8
    jsr test_gfx_blit8
    jsr test_psg_regs
    jsr test_pcm_rate_clamp
    jsr test_ym_write
    jsr test_ym_channel_in_a
    jsr test_bits
    jsr test_number_dec
    jsr test_number_hex
    jsr test_number_parse
    jsr test_i16_arith
    jsr test_i16_divmod
    jsr test_i16_divmod_s
    jsr test_i16_cmp
    jsr test_i16_sqrt
    jsr test_i16_to_dec
    jsr test_i32_addsub
    jsr test_i32_mul
    jsr test_i32_divmod
    jsr test_i32_cmp
    jsr test_i32_to_dec
    jsr test_f_roundtrip
    jsr test_f_sub_order
    jsr test_f_div_order
    jsr test_f_sqrt
    jsr test_f_str
    jsr test_fs_roundtrip
    jsr test_cls_clears
    jsr test_color_reaches_vram

    jsr test_vera_set_addr
    jsr test_vera_addr_decr
    jsr test_copy_zero
    jsr test_fill_page
    jsr test_pal_load
    jsr test_pal_load_zero
    jsr test_sprite_zdepth
    jsr test_sprite_size_pal
    jsr test_sprite_enable
    jsr test_layer_enable
    jsr test_layer_scroll
    jsr test_gfx_clear_full
    jsr test_gfx_hline_long
    jsr test_gfx_rect
    jsr test_gfx_frame
    jsr test_gfx_line_steep
    jsr test_umul16_edge
    jsr test_mul88_frac
    jsr test_collide8_9bit
    jsr test_bit_put
    jsr test_i16_convert
    jsr test_i16_mul_neg
    jsr test_i32_shift
    jsr test_i32_convert
    jsr test_number_hex_low
    jsr test_number_parse_edge
    jsr test_f_neg_cmp
    jsr test_f_pow
    jsr test_f_ln_exp
    jsr test_f_int_floor
    jsr test_psg_note_off
    jsr test_pcm_fifo
    jsr test_key_empty
    jsr test_fs_missing
    jsr test_fs_vload
    jsr test_bank_poke
    jsr test_bank_zero_count
    jsr test_screen_mode_rt
    jsr test_screen_cursor
    jsr test_screen_puts_vram

    jsr test_mem_fill
    jsr test_mem_copy
    jsr test_mem_crc
    jsr test_mem_decompress
    jsr test_bank_copy_far
    jsr test_bank_alloc
    jsr test_irq_line_regs
    jsr test_irq_line_fires
    jsr test_sprcol_regs
    jsr test_fx_line
    jsr test_fx_triangle
    jsr test_pcm_stream
    jsr test_irq_remove_aflow

    jsr test_irq_save_regs
    jsr test_math_rnd
    jsr test_math_sin
    jsr test_math_atan2
    jsr test_math_lerp
    jsr test_clip_line
    jsr test_gfx_text
    jsr test_psg_env
    jsr test_fx_copy
    jsr test_fx_transp
    jsr test_buffers
    jsr test_adpcm
    jsr test_dos
    jsr test_bmx
    jsr test_bmx_missing
    jsr test_bmx_truncated
    jsr test_bmx_short_pal
    jsr test_zx0
    jsr test_tsc
    jsr test_fx_affine
    jsr test_pcm_stream_bank
    jsr test_pcm_stream_loop

    jsr t_summary
    rts

; =====================================================================
; vera_fill writes exactly `count` bytes and not one more.
; =====================================================================
    SUBROUTINE
test_fill
    ; Poison 200 bytes with $00 so a runaway fill is visible.
    vera_addr 0, TESTVRAM, VERA_INC_1
    lda #$00
    ldx #200
    ldy #0
    jsr vera_fill

    ; Fill the first 100 with $AB.
    vera_addr 0, TESTVRAM, VERA_INC_1
    lda #$AB
    ldx #100
    ldy #0
    jsr vera_fill

    ; Read back through the OTHER port.
    vera_addr 1, TESTVRAM, VERA_INC_1
    lda #$AB
    ldx #100
    jsr t_vcmp_const
    bne .fail

    ; The 101st byte must still be $00.
    lda VERA_DATA1              ; port 1 has auto-advanced to byte 100
    cmp #$00
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "VERA_FILL", $00

; =====================================================================
; A count of 0 must write nothing at all.  The 16-bit loop rounds a
; zero low byte up to a full page, so this is the edge case that breaks
; a naive implementation.
; =====================================================================
    SUBROUTINE
test_fill_zero
    vera_addr 0, TESTVRAM, VERA_INC_1
    lda #$11
    ldx #4
    ldy #0
    jsr vera_fill

    vera_addr 0, TESTVRAM, VERA_INC_1
    lda #$EE
    ldx #0                      ; count = 0
    ldy #0
    jsr vera_fill

    vera_addr 1, TESTVRAM, VERA_INC_1
    lda #$11
    ldx #4
    jsr t_vcmp_const
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "VERA_FILL_ZERO_COUNT", $00

; =====================================================================
; The ADDR_H increment field is an INDEX, not a byte count.
; VERA_INC_2 must step by 2, leaving the odd bytes untouched.
; =====================================================================
    SUBROUTINE
test_fill_stride
    ; Clear 32 bytes.
    vera_addr 0, TESTVRAM, VERA_INC_1
    lda #$00
    ldx #32
    ldy #0
    jsr vera_fill

    ; Write 8 bytes of $55, stepping by 2.
    vera_addr 0, TESTVRAM, VERA_INC_2
    lda #$55
    ldx #8
    ldy #0
    jsr vera_fill

    ; Even offsets are $55, odd offsets are still $00.
    ; Read linearly and check the alternation.
    vera_addr 1, TESTVRAM, VERA_INC_1
    ldx #8
.loop
    lda VERA_DATA1              ; even offset
    cmp #$55
    bne .fail
    lda VERA_DATA1              ; odd offset
    cmp #$00
    bne .fail
    dex
    bne .loop

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "VERA_INC_STRIDE", $00

; =====================================================================
; vera_copy streams through both data ports at once.
; =====================================================================
    SUBROUTINE
test_copy
    ; Lay down a known ramp at TESTVRAM.
    vera_addr 0, TESTVRAM, VERA_INC_1
    ldx #0
.write
    txa
    sta VERA_DATA0
    inx
    cpx #100
    bne .write

    ; Copy it 1 KB further along: port 0 reads, port 1 writes.
    vera_addr 0, TESTVRAM, VERA_INC_1
    vera_addr 1, TESTVRAM + $400, VERA_INC_1
    ldx #100
    ldy #0
    jsr vera_copy

    ; Verify the destination holds the same ramp.
    vera_addr 1, TESTVRAM + $400, VERA_INC_1
    ldx #0
.check
    lda VERA_DATA1
    stx X16_T3
    cmp X16_T3
    bne .fail
    inx
    cpx #100
    bne .check

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "VERA_COPY", $00

; =====================================================================
; +vera_dcsel must not clobber ADDRSEL.  CTRL packs RESET(7),
; DCSEL(6:1) and ADDRSEL(0) into one byte, so a naive `sta VERA_CTRL`
; silently switches the active address port out from under the caller.
; =====================================================================
    SUBROUTINE
test_dcsel_preserves_addrsel
    vera_addrsel 1             ; ADDRSEL = 1
    vera_dcsel 2               ; select the FX register bank

    lda VERA_CTRL
    and #VERA_CTRL_ADDRSEL
    beq .fail                   ; ADDRSEL got cleared -> bug

    lda VERA_CTRL
    and #VERA_CTRL_DCSEL
    cmp #(2 << 1)
    bne .fail                   ; DCSEL didn't take

    ; And the other direction: changing ADDRSEL must not disturb DCSEL.
    vera_addrsel 0
    lda VERA_CTRL
    and #VERA_CTRL_DCSEL
    cmp #(2 << 1)
    bne .fail

    vera_dcsel 0
    lda #0
    bra .report
.fail
    vera_dcsel 0
    vera_addrsel 0
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "DCSEL_KEEPS_ADDRSEL", $00

; =====================================================================
; vera_has_fx probes DCSEL=63 and must leave DCSEL back at 0.
; =====================================================================
    SUBROUTINE
test_has_fx
    vera_addrsel 0
    vera_dcsel 0
    jsr vera_has_fx
    bcc .fail                   ; r49 emulator has FX

    lda VERA_CTRL               ; DCSEL must be back to 0
    and #VERA_CTRL_DCSEL
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "VERA_HAS_FX", $00

; =====================================================================
; screen_border must select DCSEL=0 before writing DC_BORDER -- at
; DCSEL=2 that same address is FX_MULT.
; =====================================================================
    SUBROUTINE
test_border
    vera_dcsel 2               ; leave a hostile DCSEL behind
    lda #7
    jsr screen_border

    vera_dcsel 0
    lda VERA_DC_BORDER
    cmp #7
    bne .fail

    lda #6                      ; restore the default border
    jsr screen_border
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SCREEN_BORDER", $00

; =====================================================================
; A 12-bit $0RGB colour stores little-endian into a palette entry.
; =====================================================================
    SUBROUTINE
test_palette
    ldx #1
    lda #$00                    ; green/blue nibbles
    ldy #$0F                    ; red nibble  -> $0F00, pure red
    jsr pal_set

    vera_addr 1, VRAM_PALETTE + 2, VERA_INC_1
    lda VERA_DATA1
    cmp #$00
    bne .fail
    lda VERA_DATA1
    cmp #$0F
    bne .fail

    ; Put entry 1 back to white so the rest of the run is readable.
    ldx #1
    lda #$FF
    ldy #$0F
    jsr pal_set
    lda #0
    bra .report
.fail
    ldx #1
    lda #$FF
    ldy #$0F
    jsr pal_set
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "PAL_SET", $00

; =====================================================================
; A sprite's 10-bit X and Y split across two bytes each.  Write via
; sprite_pos, read back via sprite_get_pos, and also check the raw
; record so a symmetrical bug in both cannot hide.
; =====================================================================
    SUBROUTINE
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
    vera_addr 1, VRAM_SPRITE_ATTR + (3 * 8) + 2, VERA_INC_1
    lda VERA_DATA1
    cmp #$23                    ; X low
    bne .fail
    lda VERA_DATA1
    cmp #$01                    ; X high, masked to 2 bits
    bne .fail
    lda VERA_DATA1
    cmp #$A5                    ; Y low
    bne .fail
    lda VERA_DATA1
    cmp #$00                    ; Y high
    bne .fail

    ; And the round trip.
    stz X16_P0
    stz X16_P1
    stz X16_P2
    stz X16_P3
    ldx #3
    jsr sprite_get_pos
    lda X16_P0
    cmp #$23
    bne .fail
    lda X16_P1
    cmp #$01
    bne .fail
    lda X16_P2
    cmp #$A5
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SPRITE_POS", $00

; =====================================================================
; The image address is stored as bits 16:5 across two bytes.
; $13000 (the KERNAL's sprite data area) must encode as $80/$09:
;   byte0 = addr 12:5  = ($13000 >> 5)  & $FF = $80
;   byte1 = addr 16:13 = ($13000 >> 13) & $0F = $09, plus mode bit 7
; =====================================================================
    SUBROUTINE
test_sprite_image
    jsr sprite_init_all

    lda #<VRAM_SPRITE_DATA
    sta X16_P0
    lda #>VRAM_SPRITE_DATA
    sta X16_P1
    lda #(VRAM_SPRITE_DATA >> 16)
    sta X16_P2
    ldx #5
    lda #SPRITE_MODE_8BPP
    jsr sprite_image

    vera_addr 1, VRAM_SPRITE_ATTR + (5 * 8), VERA_INC_1
    lda VERA_DATA1
    cmp #$80
    bne .fail
    lda VERA_DATA1
    cmp #(SPRITE_MODE_8BPP | $09)
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SPRITE_IMAGE", $00

; =====================================================================
; 8.8 fixed point: 1.5 * 2.0 = 3.0, i.e. 384 * 512 >> 8 = 768.
; =====================================================================
    SUBROUTINE
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
    bne .fail
    lda X16_P1
    cmp #>768
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "MUL88", $00

; =====================================================================
; -1.5 * 2.0 = -3.0.  One negative operand must flip the sign exactly
; once; two negatives must not flip it at all.
; =====================================================================
    SUBROUTINE
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
    bne .fail
    lda X16_P1
    cmp #>-768
    bne .fail

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
    bne .fail
    lda X16_P1
    cmp #>768
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "MUL88_SIGNED", $00

; =====================================================================
; collide8: boxes that genuinely overlap.
; =====================================================================
    SUBROUTINE
test_collide_overlap
    lda #0  
    sta X16_P0       ; ax
    lda #0  
    sta X16_P1       ; ay
    lda #10 
    sta X16_P2       ; aw
    lda #10 
    sta X16_P3       ; ah
    lda #5  
    sta X16_P4       ; bx
    lda #5  
    sta X16_P5       ; by
    lda #10 
    sta X16_P6       ; bw
    lda #10 
    sta X16_P7       ; bh
    jsr collide8
    lda #0
    bcs .report                 ; carry set = overlap = pass
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "COLLIDE_OVERLAP", $00

; =====================================================================
; collide8: boxes nowhere near each other.
; =====================================================================
    SUBROUTINE
test_collide_apart
    lda #0  
    sta X16_P0
    lda #0  
    sta X16_P1
    lda #10 
    sta X16_P2
    lda #10 
    sta X16_P3
    lda #20 
    sta X16_P4
    lda #20 
    sta X16_P5
    lda #5  
    sta X16_P6
    lda #5  
    sta X16_P7
    jsr collide8
    lda #0
    bcc .report                 ; carry clear = no overlap = pass
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "COLLIDE_APART", $00

; =====================================================================
; collide8: edges that merely touch must NOT count as a collision.
; Box A spans x 0..9, box B starts at x 10.  This is the case a naive
; `<=` comparison gets wrong, and it is what GAME.TXT specifies.
; =====================================================================
    SUBROUTINE
test_collide_touching
    lda #0  
    sta X16_P0
    lda #0  
    sta X16_P1
    lda #10 
    sta X16_P2
    lda #10 
    sta X16_P3
    lda #10 
    sta X16_P4       ; exactly at A's right edge
    lda #0  
    sta X16_P5
    lda #10 
    sta X16_P6
    lda #10 
    sta X16_P7
    jsr collide8
    lda #0
    bcc .report
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "COLLIDE_TOUCHING", $00

; =====================================================================
; collide16 works in display space, where the X16's default text mode is
; 640x480. Everything here lives past x=255, which collide8 could not
; even express -- the exact case bounce.asm needs.
; =====================================================================
    MAC set16
    lda #<({2})
    sta {1}
    lda #>({2})
    sta {1} + 1
    ENDM

    SUBROUTINE
test_collide16
    ; A = (300,200,80,80) overlapping B = (350,250,40,40)
    set16 cl_ax, 300
    set16 cl_ay, 200
    set16 cl_aw, 80
    set16 cl_ah, 80
    set16 cl_bx, 350
    set16 cl_by, 250
    set16 cl_bw, 40
    set16 cl_bh, 40
    jsr collide16
    bcc .fail_far               ; must overlap

    ; Move B clear of A on x only. Boxes that miss on one axis miss.
    set16 cl_bx, 500
    jsr collide16
    bcs .fail_far

    ; Edges that merely touch: A spans x 300..379, B starts at 380.
    set16 cl_bx, 380
    set16 cl_by, 200
    jsr collide16
    bcs .fail_far               ; touching is not overlapping
    bra .deeper

.fail_far                       ; .fail is out of branch range from here
    jmp .fail

.deeper
    ; One pixel of penetration is an overlap.
    set16 cl_bx, 379
    jsr collide16
    bcc .fail

    ; Both far past 255 on both axes, and only just overlapping.
    set16 cl_ax, 600
    set16 cl_ay, 400
    set16 cl_aw, 16
    set16 cl_ah, 16
    set16 cl_bx, 615
    set16 cl_by, 415
    set16 cl_bw, 16
    set16 cl_bh, 16
    jsr collide16
    bcc .fail

    set16 cl_bx, 616           ; one pixel further: now only touching
    set16 cl_by, 416
    jsr collide16
    bcs .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "COLLIDE16", $00

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
    SUBROUTINE
test_tile_addr
    lda #$41                    ; screen code
    sta X16_P0
    lda #$12                    ; attribute
    sta X16_P1
    ldx #5                      ; column
    ldy #3                      ; row
    jsr tile_put

    vera_addr 1, $1B30A, VERA_INC_1
    lda VERA_DATA1
    cmp #$41
    bne .fail
    lda VERA_DATA1
    cmp #$12
    bne .fail

    ; And confirm the map really is configured the way we assumed.
    lda VERA_L1_CONFIG
    cmp #$60
    bne .fail
    lda VERA_L1_MAPBASE
    cmp #$D8
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "TILE_ADDR", $00

; =====================================================================
; tile_put / tile_get round trip, at a cell far enough along that the
; row shift and the column add both matter.
; =====================================================================
    SUBROUTINE
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
    bne .fail
    cpx #$3C
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "TILE_ROUNDTRIP", $00

; =====================================================================
; irq_install must hook CINV, save the real previous vector, and be
; idempotent.  A second install without the irq_armed guard would store
; irq_handler as its own "previous" vector -- so the handler's chaining
; jmp (irq_old_vector) would jump to itself and hang the machine, and
; irq_remove would leave our handler installed forever.
;
; Fully testable headless: no interrupt needs to fire.
; =====================================================================
    SUBROUTINE
test_irq_hook
    lda CINV
    sta .old
    lda CINV+1
    sta .old+1

    jsr irq_install
    lda CINV
    cmp #<irq_handler
    bne .fail
    lda CINV+1
    cmp #>irq_handler
    bne .fail

    jsr irq_install             ; second install must change nothing
    lda irq_old_vector
    cmp .old
    bne .fail
    lda irq_old_vector+1
    cmp .old+1
    bne .fail

    jsr irq_remove
    lda CINV
    cmp .old
    bne .fail
    lda CINV+1
    cmp .old+1
    bne .fail

    lda #0
    bra .report
.fail
    jsr irq_remove
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.old  dc.w 0
.name dc.b "IRQ_HOOK", $00

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
    SUBROUTINE
test_vsync_counter
    jsr irq_install
    jsr RDTIM                   ; A = jiffy bits 0-7
    sta .jiffy0
    jsr irq_frames
    sta .start

    ldy #0
.outer
    ldx #0
.inner
    jsr irq_frames
    sec
    sbc .start                  ; byte subtraction wraps correctly
    cmp #2
    bcs .ok                     ; two frames elapsed
    dex
    bne .inner
    dey
    bne .outer

    ; Counter never moved. Did anything interrupt at all?
    jsr RDTIM
    sec
    sbc .jiffy0
    beq .skip                   ; jiffy frozen: this machine has no VSYNC
    jsr irq_remove
    lda #1                      ; jiffy moved but we missed every frame
    bra .report
.skip
    jsr irq_remove
    lda #<.name
    ldx #>.name
    jmp t_skip
.ok
    jsr irq_remove
    lda #0
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.jiffy0 dc.b 0
.start  dc.b 0
.name   dc.b "VSYNC_COUNTER", $00

; =====================================================================
; The FX hardware multiplier: 1000 * 1000 = 1000000 = $000F4240.
; Cross-checked against the software umul16, so the two independent
; implementations have to agree.
; =====================================================================
    SUBROUTINE
test_fx_mult
    jsr vera_has_fx
    bcc .skip

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
    bne .fail
    lda X16_P5
    cmp #$42
    bne .fail
    lda X16_P6
    cmp #$0F
    bne .fail
    lda X16_P7
    cmp #$00
    bne .fail

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
    bne .fail
    lda X16_P5
    cmp #$42
    bne .fail
    lda X16_P6
    cmp #$0F
    bne .fail
    lda X16_P7
    cmp #$00
    bne .fail

    lda #0
    bra .report
.skip
    lda #<.name
    ldx #>.name
    jmp t_skip
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "FX_MULT", $00

; =====================================================================
; The FX multiplier is signed: -1000 * 1000 = -1000000 = $FFF0BDC0.
; =====================================================================
    SUBROUTINE
test_fx_mult_signed
    jsr vera_has_fx
    bcc .skip

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
    bne .fail
    lda X16_P5
    cmp #$BD
    bne .fail
    lda X16_P6
    cmp #$F0
    bne .fail
    lda X16_P7
    cmp #$FF
    bne .fail

    lda #0
    bra .report
.skip
    lda #<.name
    ldx #>.name
    jmp t_skip
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "FX_MULT_SIGNED", $00

; =====================================================================
; The FX multiplier adds its result to the accumulator before writing it
; out, so fx_mult must clear the accumulator first (by reading
; FX_ACCUM_RESET). Dirty the accumulator on purpose -- multiply 300*300
; with the Accumulate bit set -- then check a plain fx_mult is still
; exact. Without the reset this returns 1000000 + 90000.
; =====================================================================
    SUBROUTINE
test_fx_accum_dirty
    jsr vera_has_fx
    bcc .skip

    ; Multiply-and-accumulate 300 * 300 to leave 90000 in the accumulator.
    vera_dcsel 2
    stz VERA_FX_CTRL
    lda #(VERA_FX_MULT_ENABLE | VERA_FX_MULT_ACCUMULATE)
    sta VERA_FX_MULT
    vera_dcsel 6
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
    bne .fail
    lda X16_P5
    cmp #$42
    bne .fail
    lda X16_P6
    cmp #$0F
    bne .fail
    lda X16_P7
    cmp #$00
    bne .fail

    lda #0
    bra .report
.skip
    lda #<.name
    ldx #>.name
    jmp t_skip
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "FX_ACCUM_RESET", $00

; =====================================================================
; fx_fill writes four bytes per store through the 32-bit cache. Use a
; count of 10, which is not a multiple of 4, so the 2-byte tail path
; runs too -- and check byte 11 is untouched.
; =====================================================================
    SUBROUTINE
test_fx_fill
    jsr vera_has_fx
    bcc .skip

    vera_addr 0, TESTVRAM + $100, VERA_INC_1
    lda #$00
    ldx #16
    ldy #0
    jsr vera_fill

    lda #<(TESTVRAM + $100)
    sta X16_P0
    lda #>(TESTVRAM + $100)
    sta X16_P1
    lda #((TESTVRAM + $100) >> 16)
    sta X16_P2
    lda #10
    sta X16_P3
    lda #0
    sta X16_P4
    lda #$C3
    jsr fx_fill

    vera_addr 1, TESTVRAM + $100, VERA_INC_1
    lda #$C3
    ldx #10
    jsr t_vcmp_const
    bne .fail
    lda VERA_DATA1              ; the 11th byte must still be zero
    cmp #$00
    bne .fail

    lda #0
    bra .report
.skip
    lda #<.name
    ldx #>.name
    jmp t_skip
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "FX_FILL", $00

; =====================================================================
; mem_to_bank / bank_to_mem round trip, and RAM_BANK must come back the
; way the caller left it.
; =====================================================================
    SUBROUTINE
test_bank_roundtrip
    lda RAM_BANK
    sta .saved
    lda #3
    sta RAM_BANK                ; a bank the copy must restore

    lda #<.src
    sta X16_P0
    lda #>.src
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
    bne .fail                   ; caller's bank was not restored

    lda #5
    sta X16_P0
    lda #<100
    sta X16_P1
    lda #>100
    sta X16_P2
    lda #<.dst
    sta X16_P3
    lda #>.dst
    sta X16_P4
    lda #8
    sta X16_P5
    lda #0
    sta X16_P6
    jsr bank_to_mem

    ldx #0
.cmp
    lda .src,x
    cmp .dst,x
    bne .fail
    inx
    cpx #8
    bne .cmp

    lda .saved
    sta RAM_BANK
    lda #0
    bra .report
.fail
    lda .saved
    sta RAM_BANK
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.src   dc.b $10, $21, $32, $43, $54, $65, $76, $87
.dst   ds 8, 0
.saved dc.b 0
.name  dc.b "BANK_ROUNDTRIP", $00

; =====================================================================
; A copy starting at offset 8190 must spill into the next bank: two
; bytes land at the end of bank 5, two at the start of bank 6.
; Verified with bank_peek, which selects each bank independently.
; =====================================================================
    SUBROUTINE
test_bank_boundary
    lda RAM_BANK
    sta .saved

    lda #<.pat
    sta X16_P0
    lda #>.pat
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
    bne .fail

    lda #<8191
    sta X16_P0
    lda #>8191
    sta X16_P1
    lda #5
    jsr bank_peek
    cmp #$BB
    bne .fail

    stz X16_P0                  ; bank 6, offset 0
    stz X16_P1
    lda #6
    jsr bank_peek
    cmp #$CC
    bne .fail

    lda #1
    sta X16_P0
    stz X16_P1
    lda #6
    jsr bank_peek
    cmp #$DD
    bne .fail

    lda .saved
    sta RAM_BANK
    lda #0
    bra .report
.fail
    lda .saved
    sta RAM_BANK
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.pat   dc.b $AA, $BB, $CC, $DD
.saved dc.b 0
.name  dc.b "BANK_BOUNDARY", $00

; =====================================================================
; A bitmap pixel is at y*320 + x. (100, 50) is 50*320+100 = 16100.
; =====================================================================
    SUBROUTINE
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

    vera_addr 1, VRAM_BITMAP + 16100, VERA_INC_1
    lda VERA_DATA1
    cmp #$5A
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "GFX_PSET", $00

; =====================================================================
; gfx_pset clips. x = 320 is off the right edge; unclipped it would
; write y*320 + 320, which is the first pixel of the NEXT row -- a bug
; that looks like a stray dot rather than a crash. Same for y = 240.
; =====================================================================
    SUBROUTINE
test_gfx_clip
    ; Sentinel where an unclipped (320, 0) would land: offset 320.
    vera_addr 0, VRAM_BITMAP + 320, VERA_INC_1
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

    vera_addr 1, VRAM_BITMAP + 320, VERA_INC_1
    lda VERA_DATA1
    cmp #$11
    bne .fail                   ; the clip did not hold

    ; Sentinel where an unclipped (0, 240) would land: offset 76800.
    vera_addr 0, VRAM_BITMAP + 76800, VERA_INC_1
    lda #$22
    sta VERA_DATA0
    stz X16_P0
    stz X16_P1
    lda #240
    sta X16_P2
    lda #$99
    sta X16_P3
    jsr gfx_pset

    vera_addr 1, VRAM_BITMAP + 76800, VERA_INC_1
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
.name dc.b "GFX_CLIP", $00

; =====================================================================
; gfx_vline walks the column with VERA_INC_320, so pixels land 320
; bytes apart: (3,1) then +320 each. Check the neighbours stay clear.
; =====================================================================
    SUBROUTINE
test_gfx_vline
    vera_addr 0, VRAM_BITMAP + 320, VERA_INC_1
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
    vera_addr 1, VRAM_BITMAP + 323, VERA_INC_1
    lda VERA_DATA1
    cmp #$88
    bne .fail_far
    lda VERA_DATA1
    cmp #$00
    bne .fail_far

    vera_addr 1, VRAM_BITMAP + 643, VERA_INC_1
    lda VERA_DATA1
    cmp #$88
    bne .fail_far
    lda VERA_DATA1
    cmp #$00
    bne .fail_far
    bra .rest

.fail_far                       ; .fail is out of branch range from here
    jmp .fail

.rest
    vera_addr 1, VRAM_BITMAP + 963, VERA_INC_1
    lda VERA_DATA1
    cmp #$88
    bne .fail
    lda VERA_DATA1
    cmp #$00
    bne .fail

    vera_addr 1, VRAM_BITMAP + 1283, VERA_INC_1
    lda VERA_DATA1
    cmp #$88
    bne .fail
    lda VERA_DATA1
    cmp #$00
    bne .fail

    ; and the fifth row must be clear -- the length was 4
    vera_addr 1, VRAM_BITMAP + 1603, VERA_INC_1
    lda VERA_DATA1
    cmp #$00
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "GFX_VLINE", $00

; =====================================================================
; gfx_line, Bresenham. A pure diagonal (0,0)-(3,3) must hit exactly
; (0,0) (1,1) (2,2) (3,3), i.e. offsets 0, 321, 642, 963.
; =====================================================================
    SUBROUTINE
test_gfx_line
    vera_addr 0, VRAM_BITMAP, VERA_INC_1
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

    vera_addr 1, VRAM_BITMAP + 0, VERA_INC_1
    lda VERA_DATA1
    cmp #$C7
    bne .fail
    lda VERA_DATA1              ; (1,0) must stay clear
    cmp #$00
    bne .fail

    vera_addr 1, VRAM_BITMAP + 321, VERA_INC_1
    lda VERA_DATA1
    cmp #$C7
    bne .fail
    vera_addr 1, VRAM_BITMAP + 642, VERA_INC_1
    lda VERA_DATA1
    cmp #$C7
    bne .fail
    vera_addr 1, VRAM_BITMAP + 963, VERA_INC_1
    lda VERA_DATA1
    cmp #$C7
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "GFX_LINE", $00

; =====================================================================
; PSG voice 3 lives at $1F9C0 + 3*4 = $1F9CC.
;   byte 2 = right|left|volume  -> $C0 | 63 = $FF
;   byte 3 = waveform<<6 | pw   -> triangle ($80) | 32 = $A0
; =====================================================================
    SUBROUTINE
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

    vera_addr 1, VRAM_PSG + (3 * 4), VERA_INC_1
    lda VERA_DATA1
    cmp #$A5
    bne .fail
    lda VERA_DATA1
    cmp #$04
    bne .fail
    lda VERA_DATA1
    cmp #$FF
    bne .fail
    lda VERA_DATA1
    cmp #$A0
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "PSG_REGS", $00

; =====================================================================
; AUDIO_RATE above 128 is invalid, so pcm_rate clamps. Checked on the
; returned A rather than by reading the register back, so the test does
; not depend on that register being readable.
; =====================================================================
    SUBROUTINE
test_pcm_rate_clamp
    lda #200
    jsr pcm_rate
    cmp #128
    bne .fail

    lda #64
    jsr pcm_rate
    cmp #64
    bne .fail

    lda #0                      ; stop playback again
    jsr pcm_rate

    jsr pcm_empty               ; nothing was pushed: the FIFO is empty
    bcc .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "PCM_RATE_CLAMP", $00

; =====================================================================
; ym_write must complete rather than time out on the busy flag.
; =====================================================================
    SUBROUTINE
test_ym_write
    lda #$00                    ; value
    ldx #$20                    ; RL/FB/CONNECT for channel 0
    jsr ym_write
    bcs .fail                   ; carry set = the chip stayed busy

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "YM_WRITE", $00

; =====================================================================
; The ROM's FM note API takes the CHANNEL IN runner_A and the payload in runner_X --
; the opposite of the register-level ym_write, and the opposite of what
; you would guess. Swapping them plays a valid-looking note on the wrong
; channel, so nothing crashes and nothing complains.
;
; Pin it down through the driver's own shadow: set a distinctive pan on
; channel 5, then read it back per channel. If the arguments were
; reversed, the setting would land on channel 2 (the pan value) instead.
; =====================================================================
    SUBROUTINE
test_ym_channel_in_a
    jsr ym_init
    bcs .skip                   ; no YM2151 on this machine

    lda #5                      ; channel
    ldx #2                      ; pan = right
    jsr ym_pan
    bcs .fail

    lda #5
    jsr ym_get_pan
    cpx #2
    bne .fail                   ; the pan did not reach channel 5

    lda #2                      ; the channel the swapped call would hit
    jsr ym_get_pan
    cpx #2
    beq .fail                   ; ...and it must not have landed there

    ; Attenuation travels the same way round.
    lda #5
    ldx #40
    jsr ym_vol
    bcs .fail
    lda #5
    jsr ym_get_vol
    cpx #40
    bne .fail

    lda #0
    bra .report
.skip
    lda #<.name
    ldx #>.name
    jmp t_skip
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "YM_CHANNEL_IN_A", $00

; =====================================================================
; Bit and nibble helpers.
; =====================================================================
    SUBROUTINE
test_bits
    lda #$0A
    ldx #$05
    jsr catnib
    cmp #$A5
    bne .fail

    lda #$A5
    jsr hinib
    cmp #$0A
    bne .fail
    lda #$A5
    jsr lonib
    cmp #$05
    bne .fail

    lda #<.cell
    sta X16_PTR0
    lda #>.cell
    sta X16_PTR0+1

    lda #$00
    sta .cell
    lda #%00000110
    jsr bit_set
    lda .cell
    cmp #%00000110
    bne .fail

    lda #%00000010
    jsr bit_clr
    lda .cell
    cmp #%00000100
    bne .fail

    lda #%00000100
    jsr bit_test
    beq .fail                   ; the bit is set, so Z must be clear
    lda #%00001000
    jsr bit_test
    bne .fail                   ; that bit is clear

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.cell dc.b 0
.name dc.b "BITS", $00

; =====================================================================
; u16_to_dec: no leading zeros, but zero itself still prints "0".
; =====================================================================
    SUBROUTINE
test_number_dec
    lda #<65535
    sta X16_P0
    lda #>65535
    sta X16_P1
    jsr u16_to_dec
    cpy #5
    bne .fail
    lda #<.max
    ldx #>.max
    jsr cmp_num_buf
    bcs .fail

    stz X16_P0                  ; zero must not vanish
    stz X16_P1
    jsr u16_to_dec
    cpy #1
    bne .fail
    lda #<.zero
    ldx #>.zero
    jsr cmp_num_buf
    bcs .fail

    lda #<1000                  ; interior zeros must survive
    sta X16_P0
    lda #>1000
    sta X16_P1
    jsr u16_to_dec
    cpy #4
    bne .fail
    lda #<.thou
    ldx #>.thou
    jsr cmp_num_buf
    bcs .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.max  dc.b "65535", $00
.zero dc.b "0", $00
.thou dc.b "1000", $00
.name dc.b "NUMBER_DEC", $00

; =====================================================================
    SUBROUTINE
test_number_hex
    lda #<$BEEF
    sta X16_P0
    lda #>$BEEF
    sta X16_P1
    jsr u16_to_hex
    cpy #4
    bne .fail
    lda #<.beef
    ldx #>.beef
    jsr cmp_num_buf
    bcs .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.beef dc.b "BEEF", $00
.name dc.b "NUMBER_HEX", $00

; =====================================================================
    SUBROUTINE
test_number_parse
    lda #<.good
    sta X16_P0
    lda #>.good
    sta X16_P1
    lda #4
    sta X16_P2
    jsr dec_to_u16
    bcs .fail
    lda X16_P4
    cmp #<1234
    bne .fail
    lda X16_P5
    cmp #>1234
    bne .fail

    lda #<.bad                  ; a non-digit must be rejected
    sta X16_P0
    lda #>.bad
    sta X16_P1
    lda #4
    sta X16_P2
    jsr dec_to_u16
    bcc .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.good dc.b "1234"
.bad  dc.b "12A4"
.name dc.b "NUMBER_PARSE", $00

; =====================================================================
; Branchless equality checks for the multi-byte integer tests.
;
; Each byte's difference is ORed into chk_err, which ends up zero only if
; every comparison matched. A branching version puts .fail out of range
; after a few expansions -- and chk_err is already exactly the convention
; t_result wants (0 = pass).
; =====================================================================
    SUBROUTINE
chk_err dc.b 0

    MAC chk16
    lda {1}
    eor #<({2})
    ora chk_err
    sta chk_err
    lda {1} + 1
    eor #>({2})
    ora chk_err
    sta chk_err
    ENDM

    MAC chk32
    lda {1}
    eor #<({2})
    ora chk_err
    sta chk_err
    lda {1} + 1
    eor #>({2})
    ora chk_err
    sta chk_err
    lda {1} + 2
    eor #<(({2}) >> 16)
    ora chk_err
    sta chk_err
    lda {1} + 3
    eor #<(({2}) >> 24)
    ora chk_err
    sta chk_err
    ENDM

; Fold a carry flag into chk_err. runner_want is 1 to require carry set.
    MAC chk_carry
    lda #0
    rol
    eor #({1})
    ora chk_err
    sta chk_err
    ENDM

    SUBROUTINE
test_i16_arith
    stz chk_err
    i16_const i16_a, 30000
    i16_const i16_b, 12345
    jsr i16_add
    chk16 i16_a, 42345

    i16_const i16_a, $0100     ; a borrow out of the low byte
    i16_const i16_b, 1
    jsr i16_sub
    chk16 i16_a, $00FF

    i16_const i16_a, 5         ; 5 - 7 = -2
    i16_const i16_b, 7
    jsr i16_sub
    chk16 i16_a, $FFFE

    jsr i16_neg
    chk16 i16_a, 2

    i16_const i16_a, $FFFB     ; |-5| = 5
    jsr i16_abs
    chk16 i16_a, 5

    i16_const i16_a, 1000      ; 1000 * 60 = 60000, still unsigned-clean
    i16_const i16_b, 60
    jsr i16_mul
    chk16 i16_a, 60000

    i16_const i16_a, 300       ; 300 * 300 = 90000, wraps to 24464
    i16_const i16_b, 300
    jsr i16_mul
    chk16 i16_a, 24464

    i16_const i16_a, $8001     ; arithmetic vs logical right shift
    jsr i16_asr
    chk16 i16_a, $C000
    i16_const i16_a, $8001
    jsr i16_shr
    chk16 i16_a, $4000

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "I16_ARITH", $00

; =====================================================================
; 16-bit unsigned divide, and the divide-by-zero guard.
; =====================================================================
    SUBROUTINE
test_i16_divmod
    stz chk_err
    i16_const i16_a, 1000
    i16_const i16_b, 7
    jsr i16_divmod
    chk_carry 0
    chk16 i16_a, 142           ; 7 * 142 = 994
    chk16 i16_r, 6

    i16_const i16_a, 65535     ; the full range
    i16_const i16_b, 256
    jsr i16_divmod
    chk_carry 0
    chk16 i16_a, 255
    chk16 i16_r, 255

    i16_const i16_a, 42        ; divide by zero must report, not crash
    i16_const i16_b, 0
    jsr i16_divmod
    chk_carry 1
    chk16 i16_a, 42            ; ...and leave the operand alone

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "I16_DIVMOD", $00

; =====================================================================
; Signed divide truncates toward zero, and the remainder takes the sign
; of the DIVIDEND. -7 / 2 is -3 remainder -1, not -4 remainder 1. Get
; that wrong and the quotient is still plausible, just off by one.
; =====================================================================
    SUBROUTINE
test_i16_divmod_s
    stz chk_err

    i16_const i16_a, -7
    i16_const i16_b, 2
    jsr i16_divmod_s
    chk_carry 0
    chk16 i16_a, -3
    chk16 i16_r, -1

    i16_const i16_a, 7         ; positive over negative
    i16_const i16_b, -2
    jsr i16_divmod_s
    chk16 i16_a, -3
    chk16 i16_r, 1             ; dividend was positive

    i16_const i16_a, -7        ; both negative
    i16_const i16_b, -2
    jsr i16_divmod_s
    chk16 i16_a, 3
    chk16 i16_r, -1

    i16_const i16_a, 1000      ; and it agrees with the unsigned form
    i16_const i16_b, 7         ; when both operands are positive
    jsr i16_divmod_s
    chk16 i16_a, 142
    chk16 i16_r, 6

    i16_const i16_a, -1
    i16_const i16_b, 0
    jsr i16_divmod_s
    chk_carry 1

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "I16_DIVMOD_S", $00

; =====================================================================
; Signed and unsigned comparison must disagree about $FFFF: -1 signed,
; the largest value unsigned.
; =====================================================================
    SUBROUTINE
test_i16_cmp
    i16_const i16_a, $FFFF
    i16_const i16_b, 1

    jsr i16_cmpu
    cmp #1
    bne .fail                   ; unsigned: a > b

    jsr i16_cmps
    cmp #$FF
    bne .fail                   ; signed: a is -1, so a < b

    i16_const i16_a, 12345
    i16_const i16_b, 12345
    jsr i16_cmps
    bne .fail                   ; Z set on equality
    cmp #0
    bne .fail

    i16_const i16_a, $8000     ; most negative vs most positive
    i16_const i16_b, $7FFF
    jsr i16_cmps
    cmp #$FF
    bne .fail
    jsr i16_cmpu
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
.name dc.b "I16_CMP", $00

; =====================================================================
; Integer square root: floor, exactly. The interesting cases are the
; boundaries either side of a perfect square, and the full range.
; =====================================================================
    SUBROUTINE
test_i16_sqrt
    stz chk_err

    i16_const i16_a, 0
    jsr i16_sqrt
    eor #0
    ora chk_err
    sta chk_err

    i16_const i16_a, 15        ; just under 16
    jsr i16_sqrt
    eor #3
    ora chk_err
    sta chk_err

    i16_const i16_a, 16
    jsr i16_sqrt
    eor #4
    ora chk_err
    sta chk_err

    i16_const i16_a, 144
    jsr i16_sqrt
    eor #12
    ora chk_err
    sta chk_err

    i16_const i16_a, 65024     ; 255*255 = 65025, so this floors to 254
    jsr i16_sqrt
    eor #254
    ora chk_err
    sta chk_err

    i16_const i16_a, 65535     ; the largest input
    jsr i16_sqrt
    eor #255
    ora chk_err
    sta chk_err

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "I16_SQRT", $00

; =====================================================================
; Decimal output, signed and unsigned. $FFFF prints as 65535 or -1
; depending which you ask for.
; =====================================================================
    SUBROUTINE
test_i16_to_dec
    i16_const i16_a, $FFFF
    jsr i16_to_dec              ; unsigned: 65535
    cpy #5
    bne .fail_far
    lda #<.max
    ldx #>.max
    jsr cmp_num_buf             ; i16_to_dec returns number.asm's buffer
    bcs .fail_far

    i16_const i16_a, $FFFF
    jsr i16_to_dec_s            ; signed: the same bits are -1
    cpy #2
    bne .fail_far
    lda #<.minus1
    ldx #>.minus1
    jsr cmp_i16_buf
    bcs .fail_far
    bra .rest

.fail_far                       ; .fail is out of branch range from here
    jmp .fail

.rest
    ; -32768 is its own negation. i16_to_dec_s negates it anyway and then
    ; prints the result UNSIGNED, where $8000 reads as 32768. The minus
    ; sign is added separately, so the answer comes out right.
    i16_const i16_a, -32768
    jsr i16_to_dec_s
    cpy #6
    bne .fail
    lda #<.min
    ldx #>.min
    jsr cmp_i16_buf
    bcs .fail

    i16_const i16_a, 1234      ; positive: no sign printed
    jsr i16_to_dec_s
    cpy #4
    bne .fail
    lda #<.pos
    ldx #>.pos
    jsr cmp_i16_buf
    bcs .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.max    dc.b "65535", $00
.minus1 dc.b "-1", $00
.min    dc.b "-32768", $00
.pos    dc.b "1234", $00
.name   dc.b "I16_TO_DEC", $00

; ---------------------------------------------------------------------
    SUBROUTINE
cmp_i16_buf
    sta T_ZP
    stx T_ZP+1
    ldy #0
.loop
    lda (T_ZP),y
    cmp i16_buf,y
    bne .bad
    cmp #0
    beq .ok
    iny
    bne .loop
.bad
    sec
    rts
.ok
    clc
    rts

; =====================================================================
; 32-bit add and subtract, including a borrow all the way to the top.
; =====================================================================
    SUBROUTINE
test_i32_addsub
    stz chk_err
    i32_const i32_a, 1000000
    i32_const i32_b, 2345678
    jsr i32_add
    chk32 i32_a, 3345678

    i32_const i32_a, $00010000 ; a borrow across every byte
    i32_const i32_b, 1
    jsr i32_sub
    chk32 i32_a, $0000FFFF

    i32_const i32_a, 5         ; 5 - 7 = -2, two's complement
    i32_const i32_b, 7
    jsr i32_sub
    chk32 i32_a, $FFFFFFFE

    jsr i32_neg                 ; -(-2) = 2
    chk32 i32_a, 2

    i32_const i32_a, $FFFFFFFB ; |-5| = 5
    jsr i32_abs
    chk32 i32_a, 5

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "I32_ADDSUB", $00

; =====================================================================
; 32-bit multiply. 100000 * 37 = 3700000 needs more than 16 bits on both
; sides of the product.
; =====================================================================
    SUBROUTINE
test_i32_mul
    stz chk_err
    i32_const i32_a, 100000
    i32_const i32_b, 37
    jsr i32_mul
    chk32 i32_a, 3700000

    i32_const i32_a, 65536     ; 65536 * 65536 wraps to zero, exactly
    i32_const i32_b, 65536
    jsr i32_mul
    chk32 i32_a, 0

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "I32_MUL", $00

; =====================================================================
; 32-bit unsigned divide, and the divide-by-zero guard.
; =====================================================================
    SUBROUTINE
test_i32_divmod
    stz chk_err
    i32_const i32_a, 1000000
    i32_const i32_b, 7
    jsr i32_divmod
    chk_carry 0                ; success: carry clear
    chk32 i32_a, 142857        ; 7 * 142857 = 999999
    chk32 i32_r, 1

    i32_const i32_a, 4294967295
    i32_const i32_b, 65536
    jsr i32_divmod
    chk_carry 0
    chk32 i32_a, 65535
    chk32 i32_r, 65535

    i32_const i32_a, 42        ; dividing by zero must report, not crash
    i32_const i32_b, 0
    jsr i32_divmod
    chk_carry 1                ; carry must be SET
    chk32 i32_a, 42            ; ...and the operand left alone

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "I32_DIVMOD", $00

; =====================================================================
; Signed and unsigned comparison disagree, and must each be right.
; $FFFFFFFF is -1 signed, but the largest value unsigned.
; =====================================================================
    SUBROUTINE
test_i32_cmp
    i32_const i32_a, $FFFFFFFF
    i32_const i32_b, 1

    jsr i32_cmpu                ; unsigned: a > b
    cmp #1
    bne .fail

    jsr i32_cmps                ; signed: a is -1, so a < b
    cmp #$FF
    bne .fail

    i32_const i32_a, 12345     ; equality
    i32_const i32_b, 12345
    jsr i32_cmps
    bne .fail                   ; Z must be set
    cmp #0
    bne .fail

    i32_const i32_a, $80000000 ; most negative vs most positive
    i32_const i32_b, $7FFFFFFF
    jsr i32_cmps
    cmp #$FF
    bne .fail
    jsr i32_cmpu
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
.name dc.b "I32_CMP", $00

; =====================================================================
; 32-bit decimal output, including the full-range value and zero.
; =====================================================================
    SUBROUTINE
test_i32_to_dec
    i32_const i32_a, 4294967295
    jsr i32_to_dec
    cpy #10
    bne .fail
    lda #<.max
    ldx #>.max
    jsr cmp_i32_buf
    bcs .fail

    i32_const i32_a, 0
    jsr i32_to_dec
    cpy #1
    bne .fail
    lda #<.zero
    ldx #>.zero
    jsr cmp_i32_buf
    bcs .fail

    i32_const i32_a, 1000000
    jsr i32_to_dec
    cpy #7
    bne .fail
    lda #<.mil
    ldx #>.mil
    jsr cmp_i32_buf
    bcs .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.max  dc.b "4294967295", $00
.zero dc.b "0", $00
.mil  dc.b "1000000", $00
.name dc.b "I32_TO_DEC", $00

; ---------------------------------------------------------------------
    SUBROUTINE
cmp_i32_buf
    sta T_ZP
    stx T_ZP+1
    ldy #0
.loop
    lda (T_ZP),y
    cmp i32_buf,y
    bne .bad
    cmp #0
    beq .ok
    iny
    bne .loop
.bad
    sec
    rts
.ok
    clc
    rts

; =====================================================================
; Floating point, through the ROM's library in BANK_BASIC.
; 12345 -> float -> back is exact: the mantissa is 32 bits.
; =====================================================================
    SUBROUTINE
test_f_roundtrip
    lda #<12345
    ldx #>12345
    jsr f_from_s16
    jsr f_to_s16
    cmp #<12345
    bne .fail
    cpx #>12345
    bne .fail

    lda #<-4321                 ; negatives too
    ldx #>-4321
    jsr f_from_s16
    jsr f_to_s16
    cmp #<-4321
    bne .fail
    cpx #>-4321
    bne .fail

    lda #<9999                  ; and a store / load round trip
    ldx #>9999
    jsr f_from_s16
    lda #<.tmp
    ldy #>.tmp
    jsr f_store
    jsr f_zero
    lda #<.tmp
    ldy #>.tmp
    jsr f_load
    jsr f_to_s16
    cmp #<9999
    bne .fail
    cpx #>9999
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.tmp  ds FP_SIZE, 0
.name dc.b "F_ROUNDTRIP", $00

; =====================================================================
; f_sub must compute FAC - mem, not mem - FAC.
;
; The ROM's fp_fsub does `jsr conupk` (ARG = mem) and then the ARG-first
; subtraction, so it yields mem - FAC -- the opposite of what jumptab.s
; documents. 10 - 3 is 7, and -7 if you get it backwards; both are valid
; floats, so nothing crashes.
; =====================================================================
    SUBROUTINE
test_f_sub_order
    lda #<3
    ldx #>3
    jsr f_from_s16
    lda #<.three
    ldy #>.three
    jsr f_store

    lda #<10
    ldx #>10
    jsr f_from_s16
    lda #<.three
    ldy #>.three
    jsr f_sub                   ; FAC = 10 - 3
    jsr f_to_s16
    cmp #7
    bne .fail
    cpx #0
    bne .fail

    lda #<10                    ; and the raw order, mem - FAC = -7
    ldx #>10
    jsr f_from_s16
    lda #<.three
    ldy #>.three
    jsr f_rsub
    jsr f_to_s16
    cmp #<-7
    bne .fail
    cpx #>-7
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.three ds FP_SIZE, 0
.name  dc.b "F_SUB_ORDER", $00

; =====================================================================
; f_div must compute FAC / mem. 100 / 4 = 25; backwards it would be 0.
; f_rdiv gives the ROM's mem / FAC, which is how you build 1/x.
; =====================================================================
    SUBROUTINE
test_f_div_order
    lda #<4
    ldx #>4
    jsr f_from_s16
    lda #<.four
    ldy #>.four
    jsr f_store

    lda #<100
    ldx #>100
    jsr f_from_s16
    lda #<.hundred
    ldy #>.hundred
    jsr f_store

    lda #<100
    ldx #>100
    jsr f_from_s16
    lda #<.four
    ldy #>.four
    jsr f_div                   ; FAC = 100 / 4
    jsr f_to_s16
    cmp #25
    bne .fail
    cpx #0
    bne .fail

    ; f_rdiv is the ROM's order: mem / FAC = 4 / 100 = .04
    ;
    ; Checked as a string, not by multiplying back by 100 and comparing
    ; to 4. f_to_s16 goes through qint, which FLOORS -- and .04 * 100 in
    ; binary floating point lands a hair below 4.0, so it would floor to
    ; 3. That is the float behaving correctly, not the division.
    lda #<100
    ldx #>100
    jsr f_from_s16
    lda #<.four
    ldy #>.four
    jsr f_rdiv
    jsr f_to_str_trim
    sta T_ZP
    stx T_ZP+1
    ldy #0
.cmp
    lda (T_ZP),y
    cmp .expect,y
    bne .fail
    iny
    cpy #4                      ; ".04" plus its terminator
    bne .cmp

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.four    ds FP_SIZE, 0
.hundred ds FP_SIZE, 0
.expect  dc.b ".04", $00
.name    dc.b "F_DIV_ORDER", $00

; =====================================================================
; sqrt(144) = 12 exactly, and sgn / abs behave.
; =====================================================================
    SUBROUTINE
test_f_sqrt
    lda #<144
    ldx #>144
    jsr f_from_s16
    jsr f_sqrt
    jsr f_to_s16
    cmp #12
    bne .fail
    cpx #0
    bne .fail

    lda #<-5
    ldx #>-5
    jsr f_from_s16
    jsr f_sgn
    cmp #$FF                    ; negative
    bne .fail

    lda #<-5
    ldx #>-5
    jsr f_from_s16
    jsr f_abs
    jsr f_to_s16
    cmp #5
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "F_SQRT", $00

; =====================================================================
; String conversion, both ways. f_from_str parses "2.5"; doubling it
; gives 5, which proves the fraction survived. f_to_str_trim then prints
; it back, past the leading space the ROM puts on positive numbers.
; =====================================================================
    SUBROUTINE
test_f_str
    lda #<.str
    ldy #>.str
    ldx #3
    jsr f_from_str              ; FAC = 2.5

    lda #<2                     ; * 2 = 5
    ldx #>2
    jsr f_from_s16
    lda #<.two
    ldy #>.two
    jsr f_store

    lda #<.str
    ldy #>.str
    ldx #3
    jsr f_from_str
    lda #<.two
    ldy #>.two
    jsr f_mul
    jsr f_to_s16
    cmp #5
    bne .fail
    cpx #0
    bne .fail

    ; And formatting: 2.5 back to text.
    lda #<.str
    ldy #>.str
    ldx #3
    jsr f_from_str
    jsr f_to_str_trim
    sta T_ZP
    stx T_ZP+1
    ldy #0
.cmp
    lda (T_ZP),y
    cmp .str,y
    bne .fail
    iny
    cpy #3
    bne .cmp

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.str  dc.b "2.5"
.two  ds FP_SIZE, 0
.name dc.b "F_STR", $00

; =====================================================================
; Save a block to device 8, load it back to a different address, and
; compare. build.ps1 points -fsroot at test\fsroot, so this touches a
; scratch directory rather than a real SD-card image.
; =====================================================================
    SUBROUTINE
test_fs_roundtrip
    lda #<.fname
    sta X16_P0
    lda #>.fname
    sta X16_P1
    lda #.fname_len
    sta X16_P2
    lda #8
    sta X16_P3
    lda #<.src
    sta X16_P5
    lda #>.src
    sta X16_P6
    lda #<(.src + 8)            ; end address, exclusive
    sta X16_T6
    lda #>(.src + 8)
    sta X16_T7
    jsr fs_save
    bcs .fail

    lda #<.fname
    sta X16_P0
    lda #>.fname
    sta X16_P1
    lda #.fname_len
    sta X16_P2
    lda #8
    sta X16_P3
    lda #FS_SA_ADDR             ; ignore the PRG header, load where we say
    sta X16_P4
    lda #<.dst
    sta X16_P5
    lda #>.dst
    sta X16_P6
    jsr fs_load
    bcs .fail

    ldx #0
.cmp
    lda .src,x
    cmp .dst,x
    bne .fail
    inx
    cpx #8
    bne .cmp

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.fname     dc.b "TESTDATA.BIN"
.fname_len = 12
.src       dc.b $DE, $AD, $BE, $EF, $CA, $FE, $BA, $BE
.dst       ds 8, 0
.name      dc.b "FS_ROUNDTRIP", $00

; ---------------------------------------------------------------------
; cmp_num_buf -- compare util/number's output buffer against a
; NUL-terminated expected string.
;   in:  A = expected lo, X = expected hi
;   out: carry clear when they match
;
; Uses the harness's own zero-page pointer, not the library's, so a bug
; in the library's scratch cannot make this agree by accident.
; ---------------------------------------------------------------------
    SUBROUTINE
cmp_num_buf
    sta T_ZP
    stx T_ZP+1
    ldy #0
.loop
    lda (T_ZP),y
    cmp num_buf,y
    bne .bad
    cmp #0
    beq .ok                     ; both terminated at the same place
    iny
    bne .loop
.bad
    sec
    rts
.ok
    clc
    rts

; =====================================================================
; screen_cls must clear the screen even when entered with port 1
; selected.  Plant a sentinel in the tilemap, clear, and check it went.
; =====================================================================
    SUBROUTINE
test_cls_clears
    vera_addr 0, VRAM_TEXT + (10 * 2), VERA_INC_1
    lda #$AA                    ; sentinel screen code at column 10
    sta VERA_DATA0

    vera_addrsel 1             ; hostile: leave port 1 selected
    jsr screen_cls

    vera_addr 1, VRAM_TEXT + (10 * 2), VERA_INC_1
    lda VERA_DATA1
    cmp #$20                    ; a cleared cell holds a space
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "CLS_CLEARS", $00

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
    SUBROUTINE
test_color_reaches_vram
    vera_addrsel 1
    jsr screen_cls
    lda #1                      ; foreground white
    ldx #6                      ; background blue
    jsr screen_color

    vera_addrsel 1
    ldx #0                      ; row 0
    ldy #0                      ; column 0
    jsr screen_locate

    vera_addrsel 1
    lda #'X
    jsr screen_chrout

    ; Cell (0,0) is two bytes: screen code, then attribute.
    vera_addr 1, VRAM_TEXT, VERA_INC_1
    lda VERA_DATA1
    sta .gotchar
    lda VERA_DATA1
    sta .gotattr

    ; Exactly the screen code for 'X. Checking merely "not zero" would
    ; accept the blank ($20) left behind when a mis-selected port sends
    ; the character somewhere else entirely.
    lda .gotchar
    cmp #$18
    bne .fail
    lda .gotattr
    cmp #$61                    ; fg 1 | bg 6 << 4
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.gotchar dc.b 0
.gotattr dc.b 0
.name dc.b "COLOR_TO_VRAM", $00

; =====================================================================
; ============ additional coverage: the tests below fill the ==========
; ============ gaps found in the 2026-07 stability review    ==========
; =====================================================================

; Fold one VERA_DATA1 read into chk_err (see chk16 above). Branchless,
; so long tests never push .fail out of branch range.
    MAC chkv
    lda VERA_DATA1
    eor #({1})
    ora chk_err
    sta chk_err
    ENDM

; =====================================================================
; vera_set_addr0/1 are the run-time form of +vera_addr: A/X/Y carry an
; address composed at run time. Write through port 0, read through
; port 1, both pointed by the routines under test.
; =====================================================================
    SUBROUTINE
test_vera_set_addr
    lda #<(TESTVRAM + $300)
    ldx #>(TESTVRAM + $300)
    ldy #(VERA_INC_1 << 4)      ; bank 0, increment 1
    jsr vera_set_addr0
    lda #$5E
    sta VERA_DATA0
    lda #$6F
    sta VERA_DATA0              ; the increment must have applied

    lda #<(TESTVRAM + $300)
    ldx #>(TESTVRAM + $300)
    ldy #(VERA_INC_1 << 4)
    jsr vera_set_addr1
    stz chk_err
    chkv $5E
    chkv $6F
    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "VERA_SET_ADDR", $00

; =====================================================================
; +vera_addr_decr walks DOWN. Writing 4 bytes from TESTVRAM+$403 must
; land them in descending addresses.
; =====================================================================
    SUBROUTINE
test_vera_addr_decr
    vera_addr_decr 0, TESTVRAM + $403, VERA_INC_1
    lda #$04
    sta VERA_DATA0              ; -> $403
    lda #$03
    sta VERA_DATA0              ; -> $402
    lda #$02
    sta VERA_DATA0              ; -> $401
    lda #$01
    sta VERA_DATA0              ; -> $400

    vera_addr 1, TESTVRAM + $400, VERA_INC_1
    stz chk_err
    chkv $01
    chkv $02
    chkv $03
    chkv $04
    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "VERA_ADDR_DECR", $00

; =====================================================================
; vera_copy with a count of 0 must copy nothing -- the same rounding
; trap as vera_fill's.
; =====================================================================
    SUBROUTINE
test_copy_zero
    vera_addr 0, TESTVRAM + $480, VERA_INC_1
    lda #$DD                    ; poison the destination
    ldx #4
    ldy #0
    jsr vera_fill

    vera_addr 0, TESTVRAM, VERA_INC_1          ; source: anything
    vera_addr 1, TESTVRAM + $480, VERA_INC_1
    ldx #0
    ldy #0
    jsr vera_copy

    vera_addr 1, TESTVRAM + $480, VERA_INC_1
    lda #$DD
    ldx #4
    jsr t_vcmp_const            ; A = 0 when all four survived
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "VERA_COPY_ZERO", $00

; =====================================================================
; vera_fill's 16-bit count loop: an exact page multiple ($0200) must
; not gain a page, and one-past-a-page ($0101) must not lose the tail.
; =====================================================================
    SUBROUTINE
test_fill_page
    stz chk_err

    ; poison 514 bytes at +$500, then fill exactly 512
    vera_addr 0, TESTVRAM + $500, VERA_INC_1
    lda #$00
    ldx #<514
    ldy #>514
    jsr vera_fill
    vera_addr 0, TESTVRAM + $500, VERA_INC_1
    lda #$7A
    ldx #<$0200
    ldy #>$0200
    jsr vera_fill

    vera_addr 1, TESTVRAM + $500, VERA_INC_1   ; first byte
    chkv $7A
    vera_addr 1, TESTVRAM + $500 + 511, VERA_INC_1
    chkv $7A                   ; last byte of the 512
    chkv $00                   ; the 513th must be untouched

    ; and 257 = one full page plus one byte
    vera_addr 0, TESTVRAM + $800, VERA_INC_1
    lda #$00
    ldx #<260
    ldy #>260
    jsr vera_fill
    vera_addr 0, TESTVRAM + $800, VERA_INC_1
    lda #$3B
    ldx #<$0101
    ldy #>$0101
    jsr vera_fill

    vera_addr 1, TESTVRAM + $800 + 256, VERA_INC_1
    chkv $3B                   ; byte 257 written
    chkv $00                   ; byte 258 not

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "VERA_FILL_PAGE", $00

; =====================================================================
; pal_load streams entries. Index 200 forces the *2 to carry into
; ADDR_M ($1FA00 -> $1FB90), the path pal_set's test never exercises.
; =====================================================================
    SUBROUTINE
test_pal_load
    lda #<.colors
    sta X16_PTR0
    lda #>.colors
    sta X16_PTR0+1
    lda #200                    ; first index
    ldx #3                      ; three entries
    jsr pal_load

    vera_addr 1, VRAM_PALETTE + (200 * 2), VERA_INC_1
    stz chk_err
    chkv $23
    chkv $01
    chkv $56
    chkv $04
    chkv $89
    chkv $07
    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.colors dc.b $23, $01, $56, $04, $89, $07   ; $0123, $0456, $0789
.name   dc.b "PAL_LOAD", $00

; =====================================================================
; pal_load with a count of 0 must load nothing. Without the guard the
; 8-bit loop counter wraps and 256 entries -- the entire palette --
; get overwritten with garbage.
; =====================================================================
    SUBROUTINE
test_pal_load_zero
    ldx #210                    ; plant a known entry
    lda #$AB
    ldy #$0C
    jsr pal_set

    lda #<.junk
    sta X16_PTR0
    lda #>.junk
    sta X16_PTR0+1
    lda #200
    ldx #0                      ; zero entries
    jsr pal_load

    vera_addr 1, VRAM_PALETTE + (210 * 2), VERA_INC_1
    stz chk_err
    chkv $AB                   ; entry 210 must have survived
    chkv $0C
    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.junk dc.b $FF, $FF
.name dc.b "PAL_LOAD_ZERO", $00

; =====================================================================
; sprite_flags writes byte 6 whole; sprite_z must then change ONLY the
; Z bits, preserving the collision mask and the flips around them.
; =====================================================================
    SUBROUTINE
test_sprite_zdepth
    jsr sprite_init_all

    ldx #7
    lda #($F0 | SPRITE_Z_BEHIND | SPRITE_HFLIP)
    jsr sprite_flags

    ldx #7
    lda #SPRITE_Z_FRONT
    jsr sprite_z

    vera_addr 1, VRAM_SPRITE_ATTR + (7 * 8) + 6, VERA_INC_1
    stz chk_err
    chkv ($F0 | SPRITE_Z_FRONT | SPRITE_HFLIP)
    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SPRITE_ZDEPTH", $00

; =====================================================================
; sprite_size packs height(7:6) | width(5:4) | palette offset(3:0),
; and a palette offset above 15 must be masked, not allowed to corrupt
; the size bits.
; =====================================================================
    SUBROUTINE
test_sprite_size_pal
    jsr sprite_init_all

    lda #5
    sta X16_P0                  ; palette offset
    ldx #2                      ; sprite
    lda #SPRITE_SIZE_32         ; width  -> bits 5:4 = $20
    ldy #SPRITE_SIZE_16         ; height -> bits 7:6 = $40
    jsr sprite_size

    vera_addr 1, VRAM_SPRITE_ATTR + (2 * 8) + 7, VERA_INC_1
    stz chk_err
    chkv ($40 | $20 | 5)

    lda #$15                    ; out-of-range offset: low nibble only
    sta X16_P0
    ldx #2
    lda #SPRITE_SIZE_32
    ldy #SPRITE_SIZE_16
    jsr sprite_size

    vera_addr 1, VRAM_SPRITE_ATTR + (2 * 8) + 7, VERA_INC_1
    chkv ($40 | $20 | 5)       ; still $65 -- $15 must not set bit 4

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SPRITE_SIZE_PAL", $00

; =====================================================================
; sprites_on / sprites_off toggle exactly the sprite-enable bit of
; DC_VIDEO. Save and restore the register so the display is unchanged.
; =====================================================================
    SUBROUTINE
test_sprite_enable
    vera_dcsel 0
    lda VERA_DC_VIDEO
    sta .saved

    jsr sprites_on
    lda VERA_DC_VIDEO
    and #VERA_VIDEO_SPRITES_EN
    beq .fail

    jsr sprites_off
    lda VERA_DC_VIDEO
    and #VERA_VIDEO_SPRITES_EN
    bne .fail

    lda .saved
    sta VERA_DC_VIDEO
    lda #0
    bra .report
.fail
    lda .saved
    sta VERA_DC_VIDEO
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.saved dc.b 0
.name  dc.b "SPRITE_ENABLE", $00

; =====================================================================
; layer_on / layer_off, exercised on layer 0 (idle in text mode) so
; nothing visible changes. Layer 1's bit must be left alone.
; =====================================================================
    SUBROUTINE
test_layer_enable
    vera_dcsel 0
    lda VERA_DC_VIDEO
    sta .saved

    lda #0
    jsr layer_on
    lda VERA_DC_VIDEO
    and #VERA_VIDEO_LAYER0_EN
    beq .fail
    lda VERA_DC_VIDEO
    and #VERA_VIDEO_LAYER1_EN   ; the text layer must still be on
    beq .fail

    lda #0
    jsr layer_off
    lda VERA_DC_VIDEO
    and #VERA_VIDEO_LAYER0_EN
    bne .fail

    lda .saved
    sta VERA_DC_VIDEO
    lda #0
    bra .report
.fail
    lda .saved
    sta VERA_DC_VIDEO
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.saved dc.b 0
.name  dc.b "LAYER_ENABLE", $00

; =====================================================================
; layer_scroll_x/y: 12-bit value, high byte masked to 4 bits, and the
; layer index must reach the right register pair. Layer 0 is idle, so
; scrolling it is invisible.
; =====================================================================
    SUBROUTINE
test_layer_scroll
    stz chk_err

    lda #$23
    sta X16_P0
    lda #$FF                    ; only $0F of this may land
    sta X16_P1
    ldx #0
    jsr layer_scroll_x

    lda VERA_L0_HSCROLL_L
    eor #$23
    ora chk_err
    sta chk_err
    lda VERA_L0_HSCROLL_H
    eor #$0F
    ora chk_err
    sta chk_err

    lda #$56
    sta X16_P0
    lda #$04
    sta X16_P1
    ldx #0
    jsr layer_scroll_y

    lda VERA_L0_VSCROLL_L
    eor #$56
    ora chk_err
    sta chk_err
    lda VERA_L0_VSCROLL_H
    eor #$04
    ora chk_err
    sta chk_err

    ; layer 1 must not have been touched by any of that
    lda VERA_L1_HSCROLL_L
    ora VERA_L1_HSCROLL_H
    ora chk_err
    sta chk_err

    ; put layer 0's scroll back to zero
    stz X16_P0
    stz X16_P1
    ldx #0
    jsr layer_scroll_x
    stz X16_P0
    stz X16_P1
    ldx #0
    jsr layer_scroll_y

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "LAYER_SCROLL", $00

; =====================================================================
; gfx_clear must reach the WHOLE 320x240 bitmap. 76800 bytes is $12C00,
; which does not fit a 16-bit fill count -- pass it naively and the
; low 16 bits ($2C00) clear only the top 35 rows. Check the far corner
; and the seam, and that the byte after the bitmap survives.
; =====================================================================
    SUBROUTINE
test_gfx_clear_full
    vpoke VRAM_BITMAP + 40000, $00     ; past the truncated count
    vpoke VRAM_BITMAP + 76799, $00     ; the very last pixel
    vpoke VRAM_BITMAP + 76800, $77     ; first byte past the bitmap

    lda #$A5
    jsr gfx_clear

    stz chk_err
    vera_addr 1, VRAM_BITMAP, VERA_INC_1
    chkv $A5                   ; first pixel
    vera_addr 1, VRAM_BITMAP + 40000, VERA_INC_1
    chkv $A5                   ; middle of the screen
    vera_addr 1, VRAM_BITMAP + 76799, VERA_INC_1
    chkv $A5                   ; last pixel
    chkv $77                   ; ...and not one byte more

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "GFX_CLEAR_FULL", $00

; =====================================================================
; gfx_hline with a 16-bit length. 300 pixels from (10,30) spans offsets
; 9610..9909; both ends drawn, both neighbours clear.
; =====================================================================
    SUBROUTINE
test_gfx_hline_long
    vera_addr 0, VRAM_BITMAP + 9600, VERA_INC_1
    lda #$00
    ldx #<400
    ldy #>400
    jsr vera_fill

    lda #<10
    sta X16_P0
    lda #>10
    sta X16_P1
    lda #30
    sta X16_P2
    lda #$66
    sta X16_P3
    lda #<300
    sta X16_P4
    lda #>300
    sta X16_P5
    jsr gfx_hline

    stz chk_err
    vera_addr 1, VRAM_BITMAP + 9609, VERA_INC_1
    chkv $00                   ; before the span
    chkv $66                   ; first pixel
    vera_addr 1, VRAM_BITMAP + 9909, VERA_INC_1
    chkv $66                   ; last pixel (10 + 300 - 1 = 309)
    chkv $00                   ; after the span

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "GFX_HLINE_LONG", $00

; =====================================================================
; gfx_rect: a 3x2 block at (10,20). Interior filled, all four sides'
; neighbours untouched.
; =====================================================================
    SUBROUTINE
test_gfx_rect
    vera_addr 0, VRAM_BITMAP + 6080, VERA_INC_1
    lda #$00
    ldx #<1280                  ; rows 19..22
    ldy #>1280
    jsr vera_fill

    lda #<10
    sta X16_P0
    lda #>10
    sta X16_P1
    lda #20
    sta X16_P2
    lda #$3C
    sta X16_P3
    lda #<3
    sta X16_P4
    lda #>3
    sta X16_P5
    lda #2
    sta X16_P6
    jsr gfx_rect

    stz chk_err
    vera_addr 1, VRAM_BITMAP + 6409, VERA_INC_1   ; (9,20)
    chkv $00
    chkv $3C                   ; (10,20)
    chkv $3C                   ; (11,20)
    chkv $3C                   ; (12,20)
    chkv $00                   ; (13,20)
    vera_addr 1, VRAM_BITMAP + 6730, VERA_INC_1   ; (10,21)
    chkv $3C
    vera_addr 1, VRAM_BITMAP + 6732, VERA_INC_1   ; (12,21)
    chkv $3C
    vera_addr 1, VRAM_BITMAP + 7050, VERA_INC_1   ; (10,22): below
    chkv $00
    vera_addr 1, VRAM_BITMAP + 6090, VERA_INC_1   ; (10,19): above
    chkv $00

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "GFX_RECT", $00

; =====================================================================
; gfx_frame: a 4x3 outline at (30,10). Edges drawn, interior hollow.
; =====================================================================
    SUBROUTINE
test_gfx_frame
    vera_addr 0, VRAM_BITMAP + 3200, VERA_INC_1
    lda #$00
    ldx #<960                   ; rows 10..12
    ldy #>960
    jsr vera_fill

    lda #<30
    sta X16_P0
    lda #>30
    sta X16_P1
    lda #10
    sta X16_P2
    lda #$44
    sta X16_P3
    lda #<4
    sta X16_P4
    lda #>4
    sta X16_P5
    lda #3
    sta X16_P6
    jsr gfx_frame

    stz chk_err
    vera_addr 1, VRAM_BITMAP + 3230, VERA_INC_1   ; top edge, (30..33,10)
    chkv $44
    chkv $44
    chkv $44
    chkv $44
    chkv $00                   ; (34,10) is outside
    vera_addr 1, VRAM_BITMAP + 3550, VERA_INC_1   ; middle row
    chkv $44                   ; (30,11) left edge
    chkv $00                   ; (31,11) hollow
    chkv $00                   ; (32,11) hollow
    chkv $44                   ; (33,11) right edge
    vera_addr 1, VRAM_BITMAP + 3870, VERA_INC_1   ; bottom edge
    chkv $44
    chkv $44
    chkv $44
    chkv $44

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "GFX_FRAME", $00

; =====================================================================
; gfx_line beyond the pure diagonal: a vertical drop (dx = 0) and a
; right-to-left horizontal (sx = -1).
; =====================================================================
    SUBROUTINE
test_gfx_line_steep
    vera_addr 0, VRAM_BITMAP, VERA_INC_1
    lda #$00
    ldx #<1300
    ldy #>1300
    jsr vera_fill

    ; vertical: (2,0) -> (2,3)
    lda #2
    sta X16_P0
    stz X16_P1
    stz X16_P2
    lda #2
    sta X16_P3
    stz X16_P4
    lda #3
    sta X16_P5
    lda #$D1
    sta X16_P6
    jsr gfx_line

    ; right-to-left: (5,3) -> (1,3)
    lda #5
    sta X16_P0
    stz X16_P1
    lda #3
    sta X16_P2
    lda #1
    sta X16_P3
    stz X16_P4
    lda #3
    sta X16_P5
    lda #$D1
    sta X16_P6
    jsr gfx_line

    stz chk_err
    vera_addr 1, VRAM_BITMAP + 2, VERA_INC_1      ; (2,0)
    chkv $D1
    chkv $00                   ; (3,0) stays clear
    vera_addr 1, VRAM_BITMAP + 322, VERA_INC_1    ; (2,1)
    chkv $D1
    vera_addr 1, VRAM_BITMAP + 642, VERA_INC_1    ; (2,2)
    chkv $D1
    vera_addr 1, VRAM_BITMAP + 960, VERA_INC_1    ; row 3, from (0,3)
    chkv $00                   ; (0,3) clear
    chkv $D1                   ; (1,3)
    chkv $D1                   ; (2,3)
    chkv $D1                   ; (3,3)
    chkv $D1                   ; (4,3)
    chkv $D1                   ; (5,3)
    chkv $00                   ; (6,3) clear

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "GFX_LINE_STEEP", $00

; =====================================================================
; umul16 at the corners: $FFFF^2 = $FFFE0001 exercises every carry, and
; multiplying by zero must produce a clean zero in all four bytes.
; =====================================================================
    SUBROUTINE
test_umul16_edge
    stz chk_err

    lda #$FF
    sta X16_P0
    sta X16_P1
    sta X16_P2
    sta X16_P3
    jsr umul16
    lda X16_P4
    eor #$01
    ora chk_err
    sta chk_err
    lda X16_P5
    eor #$00
    ora chk_err
    sta chk_err
    lda X16_P6
    eor #$FE
    ora chk_err
    sta chk_err
    lda X16_P7
    eor #$FF
    ora chk_err
    sta chk_err

    stz X16_P0                  ; 0 * $1234 = 0
    stz X16_P1
    lda #$34
    sta X16_P2
    lda #$12
    sta X16_P3
    jsr umul16
    lda X16_P4
    ora X16_P5
    ora X16_P6
    ora X16_P7
    ora chk_err
    sta chk_err

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "UMUL16_EDGE", $00

; =====================================================================
; mul88 keeps the fraction: 0.5 * 0.5 = 0.25 lives entirely below the
; binary point, and the sign pass must not lose it.
; =====================================================================
    SUBROUTINE
test_mul88_frac
    stz chk_err

    lda #$80                    ; 0.5
    sta X16_P0
    stz X16_P1
    lda #$80                    ; 0.5
    sta X16_P2
    stz X16_P3
    jsr mul88
    lda X16_P0
    eor #$40                    ; 0.25
    ora chk_err
    sta chk_err
    lda X16_P1
    ora chk_err
    sta chk_err

    lda #$80                    ; -0.5 * 0.5 = -0.25 = $FFC0
    sta X16_P0
    lda #$FF
    sta X16_P1
    lda #$80
    sta X16_P2
    stz X16_P3
    jsr mul88
    lda X16_P0
    eor #$C0
    ora chk_err
    sta chk_err
    lda X16_P1
    eor #$FF
    ora chk_err
    sta chk_err

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "MUL88_FRAC", $00

; =====================================================================
; collide8's edge sums are 9-bit: boxes reaching past x = 255 must
; still collide, and edges that merely touch on the Y axis must not.
; =====================================================================
    SUBROUTINE
test_collide8_9bit
    lda #250
    sta X16_P0       ; A spans x 250..259 -- past 255
    lda #0  
    sta X16_P1
    lda #10 
    sta X16_P2
    lda #10 
    sta X16_P3
    lda #252
    sta X16_P4       ; B spans x 252..261
    lda #5  
    sta X16_P5
    lda #10 
    sta X16_P6
    lda #10 
    sta X16_P7
    jsr collide8
    bcc .fail                   ; they overlap on both axes

    lda #250
    sta X16_P0       ; same boxes, B moved to touch on Y:
    lda #0  
    sta X16_P1       ; A spans y 0..9, B starts at y 10
    lda #10 
    sta X16_P2
    lda #10 
    sta X16_P3
    lda #252
    sta X16_P4
    lda #10 
    sta X16_P5
    lda #10 
    sta X16_P6
    lda #10 
    sta X16_P7
    jsr collide8
    bcs .fail                   ; touching is not overlapping

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "COLLIDE8_9BIT", $00

; =====================================================================
; bit_put routes on X: nonzero sets the masked bits, zero clears them.
; =====================================================================
    SUBROUTINE
test_bit_put
    lda #<.cell
    sta X16_PTR0
    lda #>.cell
    sta X16_PTR0+1
    stz .cell

    lda #%00001000
    ldx #1
    jsr bit_put
    lda .cell
    cmp #%00001000
    bne .fail

    lda #%00001000
    ldx #0
    jsr bit_put
    lda .cell
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.cell dc.b 0
.name dc.b "BIT_PUT", $00

; =====================================================================
; i16 conversions and shift carries. $FF is 255 zero-extended but -1
; sign-extended; the bit shifted out must land in the carry.
; =====================================================================
    SUBROUTINE
test_i16_convert
    stz chk_err

    lda #$FF
    jsr i16_from_u8
    chk16 i16_a, 255

    lda #$FF
    jsr i16_from_s8
    chk16 i16_a, -1

    lda #$7F
    jsr i16_from_s8
    chk16 i16_a, 127

    i16_const i16_a, $8000     ; shl: top bit out into carry
    jsr i16_shl
    chk_carry 1
    chk16 i16_a, 0

    i16_const i16_a, $4000     ; ...and only the top bit
    jsr i16_shl
    chk_carry 0
    chk16 i16_a, $8000

    i16_const i16_a, 1         ; shr: bottom bit out into carry
    jsr i16_shr
    chk_carry 1
    chk16 i16_a, 0

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "I16_CONVERT", $00

; =====================================================================
; i16_mul is shared between signed and unsigned because two's
; complement makes the low 16 bits identical -- prove it holds.
; =====================================================================
    SUBROUTINE
test_i16_mul_neg
    stz chk_err

    i16_const i16_a, -300
    i16_const i16_b, 3
    jsr i16_mul
    chk16 i16_a, -900

    i16_const i16_a, 5
    i16_const i16_b, -1
    jsr i16_mul
    chk16 i16_a, -5

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "I16_MUL_NEG", $00

; =====================================================================
; 32-bit shifts: carry out of shl, and asr versus shr on the sign bit.
; =====================================================================
    SUBROUTINE
test_i32_shift
    stz chk_err

    i32_const i32_a, $80000001
    jsr i32_shl
    chk_carry 1
    chk32 i32_a, 2

    i32_const i32_a, $80000000
    jsr i32_asr
    chk32 i32_a, $C0000000     ; sign fill

    i32_const i32_a, $80000000
    jsr i32_shr
    chk32 i32_a, $40000000     ; zero fill

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "I32_SHIFT", $00

; =====================================================================
; i32 conversions: $8000 is 32768 zero-extended but -32768 sign-
; extended, and i32_to_s16 hands back the low word in A/X.
; =====================================================================
    SUBROUTINE
test_i32_convert
    stz chk_err

    lda #<$8000
    ldx #>$8000
    jsr i32_from_u16
    chk32 i32_a, $00008000

    lda #<$8000
    ldx #>$8000
    jsr i32_from_s16
    chk32 i32_a, $FFFF8000

    i32_const i32_a, $12345678
    jsr i32_to_s16
    eor #$78                    ; A = low byte
    ora chk_err
    sta chk_err
    txa
    eor #$56                    ; X = high byte
    ora chk_err
    sta chk_err

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "I32_CONVERT", $00

; =====================================================================
; u16_to_hex must zero-pad: $000A is "000A", never "A".
; =====================================================================
    SUBROUTINE
test_number_hex_low
    lda #<$000A
    sta X16_P0
    lda #>$000A
    sta X16_P1
    jsr u16_to_hex
    cpy #4
    bne .fail
    lda #<.expect
    ldx #>.expect
    jsr cmp_num_buf
    bcs .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.expect dc.b "000A", $00
.name   dc.b "NUMBER_HEX_LOW", $00

; =====================================================================
; dec_to_u16 boundaries: the largest value, plain zero, and an empty
; string (length 0), which parses successfully as 0.
; =====================================================================
    SUBROUTINE
test_number_parse_edge
    lda #<.max
    sta X16_P0
    lda #>.max
    sta X16_P1
    lda #5
    sta X16_P2
    jsr dec_to_u16
    bcs .fail
    lda X16_P4
    cmp #<65535
    bne .fail
    lda X16_P5
    cmp #>65535
    bne .fail

    lda #<.zero
    sta X16_P0
    lda #>.zero
    sta X16_P1
    lda #1
    sta X16_P2
    jsr dec_to_u16
    bcs .fail
    lda X16_P4
    ora X16_P5
    bne .fail

    lda #<.zero                 ; length 0: nothing to reject, value 0
    sta X16_P0
    lda #>.zero
    sta X16_P1
    stz X16_P2
    jsr dec_to_u16
    bcs .fail
    lda X16_P4
    ora X16_P5
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.max  dc.b "65535"
.zero dc.b "0"
.name dc.b "NUMBER_PARSE_EDGE", $00

; =====================================================================
; f_from_u8 reaches values above the s16 low byte, f_neg flips the
; sign, and f_cmp orders FAC against memory all three ways.
; =====================================================================
    SUBROUTINE
test_f_neg_cmp
    lda #200
    jsr f_from_u8
    jsr f_to_s16
    cmp #200
    bne .fail
    cpx #0
    bne .fail

    lda #<5
    ldx #>5
    jsr f_from_s16
    jsr f_neg
    jsr f_to_s16
    cmp #<-5
    bne .fail
    cpx #>-5
    bne .fail

    lda #<5                     ; park 5.0 in memory
    ldx #>5
    jsr f_from_s16
    lda #<.five
    ldy #>.five
    jsr f_store

    lda #<3
    ldx #>3
    jsr f_from_s16
    lda #<.five
    ldy #>.five
    jsr f_cmp                   ; 3 < 5
    cmp #$FF
    bne .fail

    lda #<5
    ldx #>5
    jsr f_from_s16
    lda #<.five
    ldy #>.five
    jsr f_cmp                   ; 5 = 5
    bne .fail

    lda #<7
    ldx #>7
    jsr f_from_s16
    lda #<.five
    ldy #>.five
    jsr f_cmp                   ; 7 > 5
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
.five ds FP_SIZE, 0
.name dc.b "F_NEG_CMP", $00

; =====================================================================
; f_pow computes FAC ^ mem: 2 ^ 10 = 1024. Verified as a string --
; the power goes through exp(ln x), so the bits may sit a hair under
; 1024.0 where f_to_s16 would floor to 1023; fout's 9-digit rounding
; is exactly what "1024" means here (numbers.asm prints it this way).
; =====================================================================
    SUBROUTINE
test_f_pow
    lda #<10
    ldx #>10
    jsr f_from_s16
    lda #<.ten
    ldy #>.ten
    jsr f_store

    lda #<2
    ldx #>2
    jsr f_from_s16
    lda #<.ten
    ldy #>.ten
    jsr f_pow                   ; FAC = 2 ^ 10
    jsr f_to_str_trim
    sta T_ZP
    stx T_ZP+1
    ldy #0
.cmp
    lda (T_ZP),y
    cmp .expect,y
    bne .fail
    iny
    cpy #5                      ; "1024" and its terminator
    bne .cmp

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.ten    ds FP_SIZE, 0
.expect dc.b "1024", $00
.name   dc.b "F_POW", $00

; =====================================================================
; ln(1) = 0 and e^0 = 1 exactly -- the two anchor points every
; implementation must hit whatever its series does elsewhere.
; =====================================================================
    SUBROUTINE
test_f_ln_exp
    lda #<1
    ldx #>1
    jsr f_from_s16
    jsr f_ln
    jsr f_sgn                   ; sign of 0 is 0
    bne .fail

    jsr f_zero
    jsr f_exp                   ; e^0
    jsr f_to_str_trim
    sta T_ZP
    stx T_ZP+1
    ldy #0
    lda (T_ZP),y
    cmp #'1
    bne .fail
    iny
    lda (T_ZP),y                ; exactly "1", nothing after
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "F_LN_EXP", $00

; =====================================================================
; f_int truncates toward NEGATIVE infinity, BASIC's INT: -2.5 floors
; to -3, not -2.
; =====================================================================
    SUBROUTINE
test_f_int_floor
    lda #<.str
    ldy #>.str
    ldx #4
    jsr f_from_str              ; FAC = -2.5
    jsr f_int
    jsr f_to_s16
    cmp #<-3
    bne .fail
    cpx #>-3
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.str  dc.b "-2.5"
.name dc.b "F_INT_FLOOR", $00

; =====================================================================
; psg_note_off zeroes the volume but must keep the panning bits and
; leave the other three voice registers alone.
; =====================================================================
    SUBROUTINE
test_psg_note_off
    ldx #4
    lda #<$0567
    sta X16_P0
    lda #>$0567
    sta X16_P1
    jsr psg_set_freq

    ldx #4
    lda #PSG_WAVE_SAWTOOTH
    ldy #10
    jsr psg_set_wave

    ldx #4
    lda #63
    ldy #PSG_PAN_BOTH
    jsr psg_set_vol

    ldx #4
    jsr psg_note_off

    vera_addr 1, VRAM_PSG + (4 * 4), VERA_INC_1
    stz chk_err
    chkv $67                   ; frequency survives
    chkv $05
    chkv PSG_PAN_BOTH          ; volume 0, pan intact
    chkv (PSG_WAVE_SAWTOOTH | 10)

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "PSG_NOTE_OFF", $00

; =====================================================================
; The PCM FIFO flags: empty after a reset, no longer empty (and not
; full) after one byte, and empty again after another reset.
; =====================================================================
    SUBROUTINE
test_pcm_fifo
    lda #0
    jsr pcm_rate                ; rate 0: nothing drains the FIFO
    lda #$08                    ; 8-bit mono, volume 8
    jsr pcm_ctrl
    jsr pcm_reset

    jsr pcm_empty
    bcc .fail                   ; must start empty

    lda #$55
    jsr pcm_put
    jsr pcm_empty
    bcs .fail                   ; one byte queued: not empty
    jsr pcm_full
    bcs .fail                   ; ...and nowhere near full

    jsr pcm_reset
    jsr pcm_empty
    bcc .fail                   ; the reset must drain it

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "PCM_FIFO", $00

; =====================================================================
; key_get is non-blocking: with nothing queued it returns 0, and
; key_peek agrees with X = 0 and Z set.
; =====================================================================
    SUBROUTINE
test_key_empty
    ldx #16                     ; drain anything already buffered
.drain
    phx
    jsr key_get
    plx
    cmp #0
    beq .empty
    dex
    bne .drain
    bra .fail                   ; the buffer never emptied
.empty
    jsr key_peek
    bne .fail                   ; Z must be set when empty
    cpx #0
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "KEY_EMPTY", $00

; =====================================================================
; Loading a file that does not exist must come back with carry set,
; not hang or pretend.
; =====================================================================
    SUBROUTINE
test_fs_missing
    lda #<.fname
    sta X16_P0
    lda #>.fname
    sta X16_P1
    lda #.fname_len
    sta X16_P2
    lda #8
    sta X16_P3
    lda #FS_SA_ADDR
    sta X16_P4
    lda #<.dst
    sta X16_P5
    lda #>.dst
    sta X16_P6
    jsr fs_load
    bcc .fail                   ; it "loaded" a missing file

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.fname     dc.b "NOFILE.XYZ"
.fname_len = 10
.dst       ds 2, 0
.name      dc.b "FS_MISSING", $00

; =====================================================================
; fs_vload pulls a file straight into VRAM. TESTDATA.BIN was written by
; FS_ROUNDTRIP earlier in this run; its 8 payload bytes must appear at
; the VRAM address (the two-byte PRG header is consumed, not stored).
; =====================================================================
    SUBROUTINE
test_fs_vload
    vera_addr 0, TESTVRAM + $600, VERA_INC_1
    lda #$00                    ; scrub the landing zone
    ldx #12
    ldy #0
    jsr vera_fill

    lda #<.fname
    sta X16_P0
    lda #>.fname
    sta X16_P1
    lda #.fname_len
    sta X16_P2
    lda #8
    sta X16_P3
    stz X16_P4                  ; VRAM bank 0
    lda #<(TESTVRAM + $600)
    sta X16_P5
    lda #>(TESTVRAM + $600)
    sta X16_P6
    jsr fs_vload
    bcs .fail

    vera_addr 1, TESTVRAM + $600, VERA_INC_1
    stz chk_err
    chkv $DE                   ; FS_ROUNDTRIP's payload
    chkv $AD
    chkv $BE
    chkv $EF
    chkv $CA
    chkv $FE
    chkv $BA
    chkv $BE

    lda chk_err
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.fname     dc.b "TESTDATA.BIN"
.fname_len = 12
.name      dc.b "FS_VLOAD", $00

; =====================================================================
; bank_set/get and bank_poke: the byte lands in the right bank at the
; right offset, and the caller's bank survives both poke and peek.
; =====================================================================
    SUBROUTINE
test_bank_poke
    lda RAM_BANK
    sta .saved

    lda #7
    jsr bank_set
    jsr bank_get
    cmp #7
    bne .fail

    lda #123                    ; poke $C9 into bank 9, offset 123
    sta X16_P0
    stz X16_P1
    ldx #9
    lda #$C9
    jsr bank_poke

    lda RAM_BANK                ; caller's bank untouched
    cmp #7
    bne .fail

    lda #123
    sta X16_P0
    stz X16_P1
    lda #9
    jsr bank_peek
    cmp #$C9
    bne .fail

    lda RAM_BANK
    cmp #7
    bne .fail

    lda .saved
    sta RAM_BANK
    lda #0
    bra .report
.fail
    lda .saved
    sta RAM_BANK
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.saved dc.b 0
.name  dc.b "BANK_POKE", $00

; =====================================================================
; mem_to_bank with a byte count of 0 copies nothing.
; =====================================================================
    SUBROUTINE
test_bank_zero_count
    lda RAM_BANK
    sta .saved

    lda #50                     ; sentinel at bank 4, offset 50
    sta X16_P0
    stz X16_P1
    ldx #4
    lda #$77
    jsr bank_poke

    lda #<.junk
    sta X16_P0
    lda #>.junk
    sta X16_P1
    lda #4
    sta X16_P2                  ; destination bank
    lda #50
    sta X16_P3
    stz X16_P4                  ; destination offset
    stz X16_P5                  ; count = 0
    stz X16_P6
    jsr mem_to_bank

    lda #50
    sta X16_P0
    stz X16_P1
    lda #4
    jsr bank_peek
    cmp #$77                    ; the sentinel must have survived
    bne .fail

    lda .saved
    sta RAM_BANK
    lda #0
    bra .report
.fail
    lda .saved
    sta RAM_BANK
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.junk  dc.b $FF
.saved dc.b 0
.name  dc.b "BANK_ZERO_COUNT", $00

; =====================================================================
; screen_set_mode / screen_get_mode round trip, and an unsupported
; mode must be refused with carry set, leaving the mode unchanged.
; =====================================================================
    SUBROUTINE
test_screen_mode_rt
    jsr screen_get_mode
    sta .saved

    lda #$03                    ; 40x30 text
    jsr screen_set_mode
    bcs .fail
    jsr screen_get_mode
    cmp #$03
    bne .fail

    lda #$42                    ; not a mode
    jsr screen_set_mode
    bcc .fail
    jsr screen_get_mode         ; and nothing changed
    cmp #$03
    bne .fail

    lda .saved
    jsr screen_set_mode
    bcs .fail
    lda #0
    bra .report
.fail
    lda .saved                  ; put the screen back even on the way out
    jsr screen_set_mode
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.saved dc.b 0
.name  dc.b "SCREEN_MODE_RT", $00

; =====================================================================
; screen_locate / screen_get_cursor round trip.
; =====================================================================
    SUBROUTINE
test_screen_cursor
    ldx #7                      ; row
    ldy #13                     ; column
    jsr screen_locate
    jsr screen_get_cursor
    cpx #7
    bne .fail
    cpy #13
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SCREEN_CURSOR", $00

; =====================================================================
; screen_puts must land its characters in the tilemap. 'H and 'I
; are screen codes $08/$09 in the default charset; verified at the
; cell addresses for row 20 of the 128-wide map.
; =====================================================================
    SUBROUTINE
test_screen_puts_vram
    ldx #20                     ; row
    ldy #4                      ; column
    jsr screen_locate

    lda #<.text
    ldx #>.text
    jsr screen_puts

    vera_addr 1, VRAM_TEXT + (20 * 128 + 4) * 2, VERA_INC_2
    stz chk_err
    chkv $08                   ; 'H (stepping by 2 skips the attributes)
    chkv $09                   ; 'I

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.text dc.b "HI", $00
.name dc.b "SCREEN_PUTS", $00

; =====================================================================
; ============ KERNAL block ops, IRQ sources, FX line/poly, ==========
; ============ PCM streaming, bank allocator (2026-07)      ==========
; =====================================================================

; =====================================================================
; mem_fill fills RAM, and -- because $9F00-$9FFF targets are not
; incremented -- streams into VRAM through a data port.
; =====================================================================
    SUBROUTINE
test_mem_fill
    ldx #41                     ; poison a 42-byte window
.poison
    stz .buf,x
    dex
    bpl .poison

    lda #<(.buf+1)
    sta X16_P0
    lda #>(.buf+1)
    sta X16_P1
    lda #40
    sta X16_P2
    stz X16_P3
    lda #$E1
    jsr mem_fill

    lda .buf                    ; the byte before must survive
    bne .fail
    lda .buf+41                 ; ...and the byte after
    bne .fail
    ldx #40
.check
    lda .buf,x
    cmp #$E1
    bne .fail
    dex
    bne .check

    ; VERA: aim port 0, then fill "address" VERA_DATA0
    vera_addr 0, TESTVRAM + $900, VERA_INC_1
    lda #<VERA_DATA0
    sta X16_P0
    lda #>VERA_DATA0
    sta X16_P1
    lda #8
    sta X16_P2
    stz X16_P3
    lda #$37
    jsr mem_fill

    vera_addr 1, TESTVRAM + $900, VERA_INC_1
    lda #$37
    ldx #8
    jsr t_vcmp_const
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.buf  ds 42, 0
.name dc.b "MEM_FILL", $00

; =====================================================================
; mem_copy: RAM to RAM, RAM into VRAM through DATA0, and VRAM back out.
; =====================================================================
    SUBROUTINE
test_mem_copy
    lda #<.src                  ; plain RAM copy
    sta X16_P0
    lda #>.src
    sta X16_P1
    lda #<.dst
    sta X16_P2
    lda #>.dst
    sta X16_P3
    lda #8
    sta X16_P4
    stz X16_P5
    jsr mem_copy
    ldx #7
.ram
    lda .dst,x
    cmp .src,x
    bne .fail
    dex
    bpl .ram

    ; upload: RAM -> VRAM via the non-incrementing DATA0 target
    vera_addr 0, TESTVRAM + $920, VERA_INC_1
    lda #<.src
    sta X16_P0
    lda #>.src
    sta X16_P1
    lda #<VERA_DATA0
    sta X16_P2
    lda #>VERA_DATA0
    sta X16_P3
    lda #8
    sta X16_P4
    stz X16_P5
    jsr mem_copy

    ; download: VRAM -> RAM via the non-incrementing DATA0 source
    vera_addr 0, TESTVRAM + $920, VERA_INC_1
    lda #<VERA_DATA0
    sta X16_P0
    lda #>VERA_DATA0
    sta X16_P1
    lda #<.dst2
    sta X16_P2
    lda #>.dst2
    sta X16_P3
    lda #8
    sta X16_P4
    stz X16_P5
    jsr mem_copy
    ldx #7
.vram
    lda .dst2,x
    cmp .src,x
    bne .fail
    dex
    bpl .vram

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.src  dc.b $91, $82, $73, $64, $55, $46, $37, $28
.dst  ds 8, 0
.dst2 ds 8, 0
.name dc.b "MEM_COPY", $00

; =====================================================================
; mem_crc computes CRC-16/IBM-3740; the check value of "123456789" is
; $29B1, and an empty block is the $FFFF initialiser.
; =====================================================================
    SUBROUTINE
test_mem_crc
    lda #<.check
    sta X16_P0
    lda #>.check
    sta X16_P1
    lda #9
    sta X16_P2
    stz X16_P3
    jsr mem_crc
    cmp #$B1
    bne .fail
    cpx #$29
    bne .fail

    stz X16_P2                  ; empty block
    stz X16_P3
    jsr mem_crc
    cmp #$FF
    bne .fail
    cpx #$FF
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.check dc.b "123456789"
.name  dc.b "MEM_CRC", $00

; =====================================================================
; mem_decompress unpacks a real LZSA2 block (`lzsa -r -f2`): 31
; compressed bytes back into 96, into RAM and straight into VRAM.
; =====================================================================
    SUBROUTINE
test_mem_decompress
    lda #$77                    ; guard byte one past the output
    sta .out+96

    lda #<.packed
    sta X16_P0
    lda #>.packed
    sta X16_P1
    lda #<.out
    sta X16_P2
    lda #>.out
    sta X16_P3
    jsr mem_decompress
    cmp #<(.out+96)             ; A/X = one past the last byte
    bne .fail_far
    cpx #>(.out+96)
    bne .fail_far
    lda .out+96
    cmp #$77
    bne .fail_far

    lda #<.out                  ; the payload is the 24-byte phrase x4
    sta T_ZP
    lda #>.out
    sta T_ZP+1
    ldx #4
.rep
    ldy #0
.cmp
    lda (T_ZP),y
    cmp .expect,y
    bne .fail_far
    iny
    cpy #24
    bne .cmp
    clc
    lda T_ZP
    adc #24
    sta T_ZP
    bcc .norm
    inc T_ZP+1
.norm
    dex
    bne .rep
    bra .vram

.fail_far
    jmp .fail

.vram
    ; and the flagship trick: decompress directly into VRAM
    vera_addr 0, TESTVRAM + $A00, VERA_INC_1
    lda #<.packed
    sta X16_P0
    lda #>.packed
    sta X16_P1
    lda #<VERA_DATA0
    sta X16_P2
    lda #>VERA_DATA0
    sta X16_P3
    jsr mem_decompress

    vera_addr 1, TESTVRAM + $A00, VERA_INC_1
    ldx #4
.vrep
    ldy #0
.vcmp
    lda VERA_DATA1
    cmp .expect,y
    bne .fail
    iny
    cpy #24
    bne .vcmp
    dex
    bne .vrep

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.expect dc.b "X16LIB-DECOMPRESS-TEST!!"
.packed                         ; lzsa -r -f2 of that phrase repeated 4x
    dc.b $3f, $f4, $06, $58, $31, $36, $4c, $49, $42, $2d, $44, $45
    dc.b $43, $4f, $4d, $50, $52, $45, $53, $53, $2d, $54, $45, $53
    dc.b $54, $21, $21, $ff, $30, $e7, $e8
.out    ds 97, 0
.name   dc.b "MEM_DECOMPRESS", $00

; =====================================================================
; bank_copy_far moves banked RAM to banked RAM, rolling both sides
; across their bank boundaries, and restores the caller's bank.
; =====================================================================
    SUBROUTINE
test_bank_copy_far
    lda RAM_BANK
    sta .saved
    lda #7
    sta RAM_BANK

    lda #<8190                  ; source pattern straddling bank 20/21
    sta X16_P0
    lda #>8190
    sta X16_P1
    ldx #20
    lda #$A1
    jsr bank_poke
    lda #<8191
    sta X16_P0
    lda #>8191
    sta X16_P1
    ldx #20
    lda #$B2
    jsr bank_poke
    stz X16_P0
    stz X16_P1
    ldx #21
    lda #$C3
    jsr bank_poke
    lda #1
    sta X16_P0
    stz X16_P1
    ldx #21
    lda #$D4
    jsr bank_poke

    lda #20                     ; copy 4 bytes bank20:8190 -> bank22:8190
    sta X16_P0                  ; (crosses a bank edge on BOTH sides)
    lda #<8190
    sta X16_P1
    lda #>8190
    sta X16_P2
    lda #22
    sta X16_P3
    lda #<8190
    sta X16_P4
    lda #>8190
    sta X16_P5
    lda #4
    sta X16_P6
    stz X16_P7
    jsr bank_copy_far

    lda RAM_BANK                ; caller's bank survived
    cmp #7
    bne .fail

    lda #<8190
    sta X16_P0
    lda #>8190
    sta X16_P1
    lda #22
    jsr bank_peek
    cmp #$A1
    bne .fail
    lda #<8191
    sta X16_P0
    lda #>8191
    sta X16_P1
    lda #22
    jsr bank_peek
    cmp #$B2
    bne .fail
    stz X16_P0
    stz X16_P1
    lda #23
    jsr bank_peek
    cmp #$C3
    bne .fail
    lda #1
    sta X16_P0
    stz X16_P1
    lda #23
    jsr bank_peek
    cmp #$D4
    bne .fail

    lda .saved
    sta RAM_BANK
    lda #0
    bra .report
.fail
    lda .saved
    sta RAM_BANK
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.saved dc.b 0
.name  dc.b "BANK_COPY_FAR", $00

; =====================================================================
; The bank allocator: lowest-first allocation, exhaustion, free and
; reserve semantics.
; =====================================================================
    SUBROUTINE
test_bank_alloc
    lda #10
    ldx #12
    jsr bank_alloc_init

    jsr bank_alloc
    bcs .fail
    cmp #10
    bne .fail
    jsr bank_alloc
    bcs .fail
    cmp #11
    bne .fail
    jsr bank_alloc
    bcs .fail
    cmp #12
    bne .fail
    jsr bank_alloc
    bcc .fail                   ; the pool is empty now

    lda #11
    jsr bank_free
    jsr bank_alloc
    bcs .fail
    cmp #11                     ; the freed bank comes back
    bne .fail

    lda #11
    jsr bank_free
    lda #11
    jsr bank_reserve            ; claiming a free bank succeeds
    bcs .fail
    lda #11
    jsr bank_reserve            ; claiming it again does not
    bcc .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "BANK_ALLOC", $00

; =====================================================================
; irq_line_install must raise IEN's LINE bit and route scanline bit 8
; into IEN bit 7; remove must take both away. Pure register checks, so
; fully testable headless.
; =====================================================================
    SUBROUTINE
test_irq_line_regs
    lda #<300                   ; line 300: bit 8 set
    sta X16_P0
    lda #>300
    sta X16_P1
    lda #<.handler
    ldx #>.handler
    jsr irq_line_install

    lda VERA_IEN
    and #VERA_IRQ_LINE
    beq .fail
    lda VERA_IEN
    and #$80                    ; scanline bit 8
    beq .fail

    lda #100                    ; reprogram to line 100: bit 8 clear
    sta X16_P0
    stz X16_P1
    lda #<.handler
    ldx #>.handler
    jsr irq_line_install
    lda VERA_IEN
    and #$80
    bne .fail

    jsr irq_line_remove
    lda VERA_IEN
    and #VERA_IRQ_LINE
    bne .fail

    jsr irq_remove
    lda #0
    bra .report
.fail
    jsr irq_line_remove
    jsr irq_remove
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.handler
    rts
.name dc.b "IRQ_LINE_REGS", $00

; =====================================================================
; The line interrupt must actually fire at its scanline -- where
; scanlines exist at all. Headless testbench renders no video, so use
; the same jiffy-clock oracle as VSYNC_COUNTER: no jiffies = no
; interrupts here = SKIP; jiffies but no line IRQ = FAIL.
; =====================================================================
    SUBROUTINE
test_irq_line_fires
    stz .fired
    jsr RDTIM
    sta .jiffy0

    lda #<240                   ; mid-screen
    sta X16_P0
    lda #>240
    sta X16_P1
    lda #<.handler
    ldx #>.handler
    jsr irq_line_install

    ldy #0
.outer
    ldx #0
.inner
    lda .fired
    bne .ok
    dex
    bne .inner
    dey
    bne .outer

    jsr RDTIM
    sec
    sbc .jiffy0
    beq .skip                   ; no interrupts at all on this machine
    jsr irq_line_remove
    jsr irq_remove
    lda #1
    bra .report
.skip
    jsr irq_line_remove
    jsr irq_remove
    lda #<.name
    ldx #>.name
    jmp t_skip
.ok
    jsr irq_line_remove
    jsr irq_remove
    lda #0
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.handler
    inc .fired
    rts
.fired  dc.b 0
.jiffy0 dc.b 0
.name   dc.b "IRQ_LINE_FIRES", $00

; =====================================================================
; Sprite collision plumbing: install/remove toggle IEN's SPRCOL bit,
; and sprite_collisions reads-and-clears the accumulated group mask.
; (The mask is injected directly -- making VERA report a real
; collision needs rendered frames, which the headless run lacks.)
; =====================================================================
    SUBROUTINE
test_sprcol_regs
    lda #0                      ; poll-only: no callback
    tax
    jsr irq_sprcol_install
    lda VERA_IEN
    and #VERA_IRQ_SPRCOL
    beq .fail

    ; The Z result must be derived from the mask, not smuggled back in
    ; by plp -- so enter each call with the OPPOSITE flag state.
    lda #$30                    ; groups 4 and 5 collided, twice over
    sta irq_sprcol_mask
    lda #0                      ; hostile: Z set on entry...
    jsr sprite_collisions
    beq .fail                   ; ...a $30 mask must clear it
    cmp #$30
    bne .fail
    lda #1                      ; hostile: Z clear on entry...
    jsr sprite_collisions       ; (the read above cleared the mask)
    bne .fail                   ; ...an empty mask must set it

    jsr irq_sprcol_remove
    lda VERA_IEN
    and #VERA_IRQ_SPRCOL
    bne .fail

    jsr irq_remove
    lda #0
    bra .report
.fail
    jsr irq_sprcol_remove
    jsr irq_remove
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SPRCOL_REGS", $00

; =====================================================================
; fx_line, against pixels the emulator verifiably produces: an
; axis-aligned run, an exact diagonal, an anti-diagonal (both
; decrement flags), and the canonical Bresenham of a 3-in-7 slant.
; =====================================================================
    SUBROUTINE
test_fx_line
    jsr vera_has_fx
    bcs .go
    lda #<.name
    ldx #>.name
    jmp t_skip
.go
    vera_addr 0, VRAM_BITMAP, VERA_INC_1
    lda #$00
    ldx #<2560                  ; clear rows 0..7
    ldy #>2560
    jsr vera_fill

    stz X16_P0                  ; horizontal (0,0)-(7,0)
    stz X16_P1
    stz X16_P2
    lda #7
    sta X16_P3
    stz X16_P4
    stz X16_P5
    lda #$C1
    sta X16_P6
    jsr fx_line

    lda #20                     ; diagonal (20,0)-(27,7)
    sta X16_P0
    stz X16_P1
    stz X16_P2
    lda #27
    sta X16_P3
    stz X16_P4
    lda #7
    sta X16_P5
    lda #$C2
    sta X16_P6
    jsr fx_line

    lda #60                     ; anti-diagonal (60,0)-(53,7)
    sta X16_P0
    stz X16_P1
    stz X16_P2
    lda #53
    sta X16_P3
    stz X16_P4
    lda #7
    sta X16_P5
    lda #$C3
    sta X16_P6
    jsr fx_line

    lda #40                     ; slant (40,0)-(47,3)
    sta X16_P0
    stz X16_P1
    stz X16_P2
    lda #47
    sta X16_P3
    stz X16_P4
    lda #3
    sta X16_P5
    lda #$C4
    sta X16_P6
    jsr fx_line

    stz chk_err
    vera_addr 1, VRAM_BITMAP + 0, VERA_INC_1      ; horizontal row
    chkv $C1
    chkv $C1
    chkv $C1
    chkv $C1
    chkv $C1
    chkv $C1
    chkv $C1
    chkv $C1
    chkv $00                   ; exactly 8 pixels
    vera_addr 1, VRAM_BITMAP + 320, VERA_INC_1    ; nothing on row 1
    chkv $00

    vera_addr 1, VRAM_BITMAP + 20, VERA_INC_1     ; diagonal endpoints
    chkv $C2
    chkv $00
    vera_addr 1, VRAM_BITMAP + 3*320 + 23, VERA_INC_1
    chkv $C2
    vera_addr 1, VRAM_BITMAP + 7*320 + 27, VERA_INC_1
    chkv $C2

    vera_addr 1, VRAM_BITMAP + 60, VERA_INC_1     ; anti-diagonal
    chkv $C3
    vera_addr 1, VRAM_BITMAP + 1*320 + 59, VERA_INC_1
    chkv $C3
    vera_addr 1, VRAM_BITMAP + 7*320 + 53, VERA_INC_1
    chkv $C3

    ; the slant's full Bresenham: two pixels per row, descending
    vera_addr 1, VRAM_BITMAP + 40, VERA_INC_1
    chkv $C4
    chkv $C4
    chkv $00
    vera_addr 1, VRAM_BITMAP + 1*320 + 42, VERA_INC_1
    chkv $C4
    chkv $C4
    chkv $00
    vera_addr 1, VRAM_BITMAP + 2*320 + 44, VERA_INC_1
    chkv $C4
    chkv $C4
    chkv $00
    vera_addr 1, VRAM_BITMAP + 3*320 + 46, VERA_INC_1
    chkv $C4
    chkv $C4
    chkv $00

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "FX_LINE", $00

; =====================================================================
; fx_triangle: a flat-top staircase whose every row width is exactly
; predictable, and a general (sorted-on-entry-not-required) triangle
; pinned at its apex, its widest row, and its half-open bottom.
; =====================================================================
    SUBROUTINE
test_fx_triangle
    jsr vera_has_fx
    bcs .go
    lda #<.name
    ldx #>.name
    jmp t_skip
.go
    vera_addr 0, VRAM_BITMAP, VERA_INC_1
    lda #$00
    ldx #<9600                  ; clear rows 0..29
    ldy #>9600
    jsr vera_fill

    i16_const tri_x0, 10       ; right triangle: (10,5) (30,5) (10,25)
    lda #5
    sta tri_y0
    i16_const tri_x1, 30
    lda #5
    sta tri_y1
    i16_const tri_x2, 10
    lda #25
    sta tri_y2
    lda #$AA
    sta tri_color
    jsr fx_triangle

    stz chk_err
    vera_addr 1, VRAM_BITMAP + 5*320 + 9, VERA_INC_1
    chkv $00                   ; left of the triangle
    chkv $AA                   ; (10,5): top row runs 10..29
    vera_addr 1, VRAM_BITMAP + 5*320 + 29, VERA_INC_1
    chkv $AA
    chkv $00                   ; (30,5) is outside
    vera_addr 1, VRAM_BITMAP + 15*320 + 19, VERA_INC_1
    chkv $AA                   ; row 15 runs 10..19
    chkv $00
    vera_addr 1, VRAM_BITMAP + 24*320 + 10, VERA_INC_1
    chkv $AA                   ; the last drawn row is one pixel
    chkv $00
    vera_addr 1, VRAM_BITMAP + 25*320 + 10, VERA_INC_1
    chkv $00                   ; half-open: row y2 stays empty

    ; general triangle, vertices deliberately out of order
    vera_addr 0, VRAM_BITMAP, VERA_INC_1
    lda #$00
    ldx #<9600
    ldy #>9600
    jsr vera_fill

    i16_const tri_x0, 45       ; the BOTTOM vertex first
    lda #20
    sta tri_y0
    i16_const tri_x1, 40       ; the top
    lda #0
    sta tri_y1
    i16_const tri_x2, 60       ; the middle
    lda #10
    sta tri_y2
    lda #$AB
    sta tri_color
    jsr fx_triangle

    vera_addr 1, VRAM_BITMAP + 0*320 + 40, VERA_INC_1
    chkv $AB                   ; apex
    chkv $00
    vera_addr 1, VRAM_BITMAP + 9*320 + 41, VERA_INC_1
    chkv $00                   ; row 9 runs 42..58
    chkv $AB
    vera_addr 1, VRAM_BITMAP + 9*320 + 58, VERA_INC_1
    chkv $AB
    chkv $00
    vera_addr 1, VRAM_BITMAP + 13*320 + 43, VERA_INC_1
    chkv $AB                   ; row 13 runs 43..54
    vera_addr 1, VRAM_BITMAP + 13*320 + 54, VERA_INC_1
    chkv $AB
    chkv $00
    vera_addr 1, VRAM_BITMAP + 19*320 + 45, VERA_INC_1
    chkv $AB                   ; the last row narrows to one pixel
    vera_addr 1, VRAM_BITMAP + 20*320 + 45, VERA_INC_1
    chkv $00                   ; half-open bottom

    lda chk_err
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "FX_TRIANGLE", $00

; =====================================================================
; The PCM streamer's bookkeeping, headless-safe with the DAC stopped
; (rate 0): priming fills the FIFO to the brim, AFLOW is armed only
; while data remains, and a buffer that fits entirely leaves AFLOW off.
; =====================================================================
    SUBROUTINE
test_pcm_stream
    lda #0
    jsr pcm_rate
    lda #$0F                    ; 8-bit mono, full volume
    jsr pcm_ctrl
    jsr pcm_reset

    lda #<$2000                 ; any readable RAM does as sample data
    sta X16_P0
    lda #>$2000
    sta X16_P1
    lda #<5120                  ; more than the 4 KB FIFO
    sta X16_P2
    lda #>5120
    sta X16_P3
    lda #0                      ; rate 0: prime but do not play
    jsr pcm_stream_start

    jsr pcm_full
    bcc .fail                   ; the FIFO was primed to the brim
    jsr pcm_stream_active
    beq .fail                   ; 1 KB still waiting
    lda VERA_IEN
    and #VERA_IRQ_AFLOW
    beq .fail                   ; ...so the refill IRQ is armed

    jsr pcm_stream_stop
    lda VERA_IEN
    and #VERA_IRQ_AFLOW
    bne .fail
    jsr pcm_stream_active
    bne .fail

    jsr pcm_reset               ; now a buffer that fits outright
    lda #<$2000
    sta X16_P0
    lda #>$2000
    sta X16_P1
    lda #64
    sta X16_P2
    stz X16_P3
    lda #0
    jsr pcm_stream_start

    jsr pcm_stream_active
    bne .fail                   ; everything was handed over at start
    lda VERA_IEN
    and #VERA_IRQ_AFLOW
    bne .fail                   ; ...so no refill IRQ is needed
    jsr pcm_empty
    bcs .fail                   ; but the 64 bytes are queued

    jsr pcm_reset
    jsr irq_remove
    lda #0
    bra .report
.fail
    jsr pcm_stream_stop
    jsr pcm_reset
    jsr irq_remove
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "PCM_STREAM", $00

; =====================================================================
; irq_remove while a PCM stream is still refilling must take AFLOW out
; of IEN. AFLOW has no ISR acknowledge -- it clears only when the FIFO
; refills -- so once CINV is back on the KERNAL, an armed AFLOW keeps
; the IRQ line asserted and the machine livelocks. (Proven windowed:
; without AFLOW in irq_remove's mask this hangs the emulator; here it
; is pinned at register level so the headless run guards it too.)
; =====================================================================
    SUBROUTINE
test_irq_remove_aflow
    lda #0
    jsr pcm_rate
    lda #$0F
    jsr pcm_ctrl
    jsr pcm_reset

    lda #<$2000                 ; any readable RAM does as sample data
    sta X16_P0
    lda #>$2000
    sta X16_P1
    lda #<5120                  ; bigger than the FIFO: AFLOW gets armed
    sta X16_P2
    lda #>5120
    sta X16_P3
    lda #0                      ; rate 0: prime but do not play
    jsr pcm_stream_start

    lda VERA_IEN
    and #VERA_IRQ_AFLOW
    beq .fail                   ; precondition: the stream armed AFLOW

    jsr irq_remove              ; unhook mid-stream, like a rude caller

    lda VERA_IEN
    and #VERA_IRQ_AFLOW
    bne .fail                   ; AFLOW must be gone with the hook
    jsr pcm_stream_active
    bne .fail                   ; and the stream must know it is dead

    jsr pcm_reset
    lda #0
    bra .report
.fail
    jsr pcm_stream_stop
    jsr pcm_reset
    jsr irq_remove
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "IRQ_REMOVE_AFLOW", $00

; =====================================================================
; ============ Prog8-parity features (2026-07): vreg saving, ==========
; ============ math, clipping, circles, text, envelopes,     ==========
; ============ fx copy/transparency, DOS, buffers, ADPCM     ==========
; =====================================================================

; =====================================================================
; irq_save_regs / irq_restore_regs must round-trip r0-r15 and the
; library's parameter block -- the state an IRQ callback that calls
; library routines would otherwise corrupt.
; =====================================================================
    SUBROUTINE
test_irq_save_regs
    ldx #31                     ; pattern into r0-r15
.fill_r
    txa
    eor #$5A
    sta r0L,x
    dex
    bpl .fill_r
    ldx #15                     ; ...and into X16_P0..T7
.fill_p
    txa
    eor #$C3
    sta X16_P0,x
    dex
    bpl .fill_p

    jsr irq_save_regs

    ldx #31                     ; trash everything
    lda #$EE
.trash_r
    sta r0L,x
    dex
    bpl .trash_r
    ldx #15
.trash_p
    sta X16_P0,x
    dex
    bpl .trash_p

    jsr irq_restore_regs

    ldx #31
.check_r
    txa
    eor #$5A
    cmp r0L,x
    bne .fail
    dex
    bpl .check_r
    ldx #15
.check_p
    txa
    eor #$C3
    cmp X16_P0,x
    bne .fail
    dex
    bpl .check_p

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "IRQ_SAVE_REGS", $00

; =====================================================================
; The PRNG: deterministic from a seed, actually changes, and a zero
; seed is nudged off xorshift's fixed point.
; =====================================================================
    SUBROUTINE
test_math_rnd
    lda #$34
    ldx #$12
    jsr rnd_seed
    jsr rnd16
    sta .first
    stx .first+1

    jsr rnd16                   ; must differ from the first draw
    cmp .first
    bne .differs
    cpx .first+1
    beq .fail
.differs
    lda #$34                    ; same seed: same sequence
    ldx #$12
    jsr rnd_seed
    jsr rnd16
    cmp .first
    bne .fail
    cpx .first+1
    bne .fail

    lda #0                      ; the all-zero seed must not stick
    tax
    jsr rnd_seed
    jsr rnd16
    ora rnd_state+1
    beq .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.first dc.w 0
.name  dc.b "MATH_RND", $00

; =====================================================================
; The sine tables at their anchor points, and the signed/unsigned pair.
; =====================================================================
    SUBROUTINE
test_math_sin
    lda #0
    jsr sin8
    bne .fail                   ; sin(0) = 0
    lda #64
    jsr sin8
    cmp #127
    bne .fail                   ; sin(90) = 127
    lda #128
    jsr sin8
    bne .fail
    lda #192
    jsr sin8
    cmp #<-127
    bne .fail
    lda #0
    jsr cos8
    cmp #127
    bne .fail
    lda #64
    jsr sin8u
    cmp #255
    bne .fail
    lda #192
    jsr sin8u
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
.name dc.b "MATH_SIN", $00

; =====================================================================
; atan2 at the four cardinals, the four diagonals, and one odd vector
; where a small tolerance is allowed.
; =====================================================================
    SUBROUTINE
test_math_atan2
    lda #10
    ldx #0
    jsr atan2
    bne .fail                   ; east = 0
    lda #0
    ldx #10
    jsr atan2
    cmp #64                     ; down = 64
    bne .fail
    lda #<-10
    ldx #0
    jsr atan2
    cmp #128
    bne .fail
    lda #0
    ldx #<-10
    jsr atan2
    cmp #192
    bne .fail
    lda #10
    ldx #10
    jsr atan2
    cmp #32
    bne .fail
    lda #<-10
    ldx #10
    jsr atan2
    cmp #96
    bne .fail
    lda #10
    ldx #<-10
    jsr atan2
    cmp #224
    bne .fail

    lda #7                      ; atan2(7,3): ideally 16.5 -- allow 15..18
    ldx #3
    jsr atan2
    cmp #15
    bcc .fail
    cmp #19
    bcs .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "MATH_ATAN2", $00

; =====================================================================
; lerp8: exact at both ends, the documented value in the middle, and
; downhill interpolation.
; =====================================================================
    SUBROUTINE
test_math_lerp
    lda #10
    sta X16_P0
    lda #20
    sta X16_P1
    lda #0
    jsr lerp8
    cmp #10
    bne .fail
    lda #255
    jsr lerp8
    cmp #20
    bne .fail
    lda #128                    ; 10 + (10 * 129) / 256 = 15
    jsr lerp8
    cmp #15
    bne .fail

    lda #20                     ; downhill: b < a
    sta X16_P0
    lda #10
    sta X16_P1
    lda #255
    jsr lerp8
    cmp #10
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "MATH_LERP", $00

; =====================================================================
; Cohen-Sutherland: inside untouched, outside rejected, and edge
; crossings landing exactly on the boundary.
; =====================================================================
    MAC cset16
    lda #<({2})
    sta {1}
    lda #>({2})
    sta {1} + 1
    ENDM

    SUBROUTINE
test_clip_line
    ; fully inside: accepted, coordinates untouched
    cset16 clipl_x0, 5
    cset16 clipl_y0, 5
    cset16 clipl_x1, 50
    cset16 clipl_y1, 40
    jsr clip_line
    bcs .fail_far
    lda X16_P0
    cmp #5
    bne .fail_far
    lda X16_P3
    cmp #50
    bne .fail_far

    ; fully off the right: rejected
    cset16 clipl_x0, 400
    cset16 clipl_y0, 10
    cset16 clipl_x1, 500
    cset16 clipl_y1, 20
    jsr clip_line
    bcc .fail_far
    bra .cross

.fail_far
    jmp .fail

.cross
    ; crossing the right edge: (300,100)-(340,120) clips to x=319.
    ; The OUTSIDE endpoint is the one moved: y = 120 - 420/40 with the
    ; division truncating toward zero, so 110 (the exact crossing is
    ; 109.5).
    cset16 clipl_x0, 300
    cset16 clipl_y0, 100
    cset16 clipl_x1, 340
    cset16 clipl_y1, 120
    jsr clip_line
    bcs .fail
    lda clipl_x1
    cmp #<319
    bne .fail
    lda clipl_x1+1
    cmp #>319
    bne .fail
    lda clipl_y1
    cmp #110
    bne .fail

    ; entering from above: (10,-10)-(30,10) clips to (20,0)
    cset16 clipl_x0, 10
    cset16 clipl_y0, -10
    cset16 clipl_x1, 30
    cset16 clipl_y1, 10
    jsr clip_line
    bcs .fail
    lda clipl_x0
    cmp #20
    bne .fail
    lda clipl_y0
    bne .fail
    lda clipl_y0+1
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "CLIP_LINE", $00

; =====================================================================
; Bitmap text. Screen code $A0 (reverse space) is a solid 8x8 block --
; exactly predictable. Then gfx_text's ASCII conversion and pen
; advance are proven by drawing "H" and comparing the cell byte-for-
; byte against gfx_char of screen code 8.
; =====================================================================
    SUBROUTINE
test_gfx_text
    vera_addr 0, VRAM_BITMAP + 20*320, VERA_INC_1
    lda #$00
    ldx #<3200                  ; clear rows 20..29
    ldy #>3200
    jsr vera_fill

    i16_const X16_P0, 10       ; the solid block
    lda #20
    sta X16_P2
    lda #$E1
    sta X16_P3
    lda #$A0
    jsr gfx_char

    stz chk_err
    vera_addr 1, VRAM_BITMAP + 20*320 + 9, VERA_INC_1
    chkv $00                   ; left neighbour clear
    chkv $E1                   ; (10,20)
    vera_addr 1, VRAM_BITMAP + 20*320 + 17, VERA_INC_1
    chkv $E1                   ; (17,20)
    chkv $00                   ; (18,20) clear
    vera_addr 1, VRAM_BITMAP + 27*320 + 10, VERA_INC_1
    chkv $E1                   ; (10,27)
    vera_addr 1, VRAM_BITMAP + 28*320 + 10, VERA_INC_1
    chkv $00                   ; row 28 untouched

    ; gfx_char(8) at (60,20) vs gfx_text "H" at (80,20)
    i16_const X16_P0, 60
    lda #20
    sta X16_P2
    lda #8                      ; screen code of 'H
    jsr gfx_char
    i16_const X16_P0, 80
    lda #<.h
    ldx #>.h
    jsr gfx_text
    lda X16_P0                  ; the pen advanced one cell
    cmp #88
    bne .fail

    ldx #0                      ; compare the two 8x8 cells row by row
.rows
    txa
    pha
    ; read cell A row into .rowbuf
    stz X16_T0
    txa
    clc
    adc #20                     ; y = 20 + row
    sta X16_P2
    jsr .row_addr60
    ldy #0
.grab
    lda VERA_DATA1
    sta .rowbuf,y
    iny
    cpy #8
    bne .grab
    jsr .row_addr80
    ldy #0
.cmp
    lda VERA_DATA1
    cmp .rowbuf,y
    bne .fail_pop
    iny
    cpy #8
    bne .cmp
    pla
    tax
    inx
    cpx #8
    bne .rows

    lda #0
    bra .report
.fail_pop
    pla
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result

; point port 1 at (60, X16_P2) / (80, X16_P2)
.row_addr60
    lda #60
    bra .row_addr
.row_addr80
    lda #80
.row_addr
    sta X16_T2
    ; addr = P2*320 + T2
    lda X16_P2
    stz X16_T1
    asl
    rol X16_T1
    asl
    rol X16_T1
    asl
    rol X16_T1
    asl
    rol X16_T1
    asl
    rol X16_T1
    asl
    rol X16_T1
    sta X16_T0
    clc
    lda X16_T1
    adc X16_P2
    sta X16_T1
    clc
    lda X16_T0
    adc X16_T2
    sta X16_T0
    lda X16_T1
    adc #0
    sta X16_T1
    vera_addrsel 1
    lda X16_T0
    sta VERA_ADDR_L
    lda X16_T1
    sta VERA_ADDR_M
    lda #(VERA_INC_1 << 4)
    sta VERA_ADDR_H
    rts

.h      dc.b "H", $00
.rowbuf ds 8, 0
.name   dc.b "GFX_TEXT", $00

; =====================================================================
; The PSG envelope: attack ramps to the peak, sustain holds it, the
; release fades to silence and disarms -- all observed through the
; voice's VRAM shadow, pan bits intact.
; =====================================================================
    SUBROUTINE
test_psg_env
    ldx #2                      ; voice 2: pan both, volume 0
    lda #0
    ldy #PSG_PAN_BOTH
    jsr psg_set_vol

    lda #2                      ; peak 40, attack 8, sustain 3, release 10
    ldy #40
    sty X16_P0
    ldy #8
    sty X16_P1
    ldy #3
    sty X16_P2
    ldy #10
    sty X16_P3
    jsr psg_env_start

    jsr psg_env_tick            ; one tick: volume 8
    jsr .vol2
    cmp #(PSG_PAN_BOTH | 8)
    bne .fail

    jsr psg_env_tick            ; four more: at the 40 peak
    jsr psg_env_tick
    jsr psg_env_tick
    jsr psg_env_tick
    jsr .vol2
    cmp #(PSG_PAN_BOTH | 40)
    bne .fail

    jsr psg_env_tick            ; three sustain ticks: unchanged
    jsr psg_env_tick
    jsr psg_env_tick
    jsr .vol2
    cmp #(PSG_PAN_BOTH | 40)
    bne .fail

    jsr psg_env_tick            ; release: 30, 20, 10, 0
    jsr psg_env_tick
    jsr psg_env_tick
    jsr psg_env_tick
    jsr .vol2
    cmp #PSG_PAN_BOTH           ; silent, pan preserved
    bne .fail
    lda env_stage+2
    bne .fail                   ; ...and disarmed

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result

.vol2                           ; A = voice 2's volume/pan shadow byte
    vera_addr 1, VRAM_PSG + (2*4) + 2, VERA_INC_1
    lda VERA_DATA1
    rts
.name dc.b "PSG_ENV", $00

; =====================================================================
; fx_copy moves 13 bytes (three quads and a 1-byte tail) and stops.
; =====================================================================
    SUBROUTINE
test_fx_copy
    jsr vera_has_fx
    bcs .go
    lda #<.name
    ldx #>.name
    jmp t_skip
.go
    vera_addr 0, TESTVRAM + $B00, VERA_INC_1
    ldx #0
.src
    txa
    eor #$A7
    sta VERA_DATA0
    inx
    cpx #16
    bne .src

    vera_addr 0, TESTVRAM + $B40, VERA_INC_1   ; scrub the target
    lda #$00
    ldx #16
    ldy #0
    jsr vera_fill

    lda #<(TESTVRAM + $B00)
    sta X16_P0
    lda #>(TESTVRAM + $B00)
    sta X16_P1
    lda #((TESTVRAM + $B00) >> 16)
    sta X16_P2
    lda #<(TESTVRAM + $B40)                     ; 4-byte aligned
    sta X16_P3
    lda #>(TESTVRAM + $B40)
    sta X16_P4
    lda #((TESTVRAM + $B40) >> 16)
    sta X16_P5
    lda #13
    sta X16_P6
    stz X16_P7
    jsr fx_copy

    vera_addr 1, TESTVRAM + $B40, VERA_INC_1
    ldx #0
.check
    txa
    eor #$A7
    cmp VERA_DATA1
    bne .fail
    inx
    cpx #13
    bne .check
    lda VERA_DATA1              ; the 14th byte stayed clear
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "FX_COPY", $00

; =====================================================================
; Transparent writes: while enabled, writing zero leaves the target
; byte alone; nonzero still lands; disabling restores normal writes.
; =====================================================================
    SUBROUTINE
test_fx_transp
    jsr vera_has_fx
    bcs .go
    lda #<.name
    ldx #>.name
    jmp t_skip
.go
    vpoke TESTVRAM + $B80, $AA

    jsr fx_transp_on
    vera_addr 0, TESTVRAM + $B80, VERA_INC_0
    stz VERA_DATA0              ; a zero write must bounce off
    vera_addr 1, TESTVRAM + $B80, VERA_INC_0
    lda VERA_DATA1
    cmp #$AA
    bne .fail

    vera_addr 0, TESTVRAM + $B80, VERA_INC_0
    lda #$BB                    ; nonzero still writes
    sta VERA_DATA0
    vera_addr 1, TESTVRAM + $B80, VERA_INC_0
    lda VERA_DATA1
    cmp #$BB
    bne .fail

    jsr fx_transp_off
    vera_addr 0, TESTVRAM + $B80, VERA_INC_0
    stz VERA_DATA0              ; and now zero writes again
    vera_addr 1, TESTVRAM + $B80, VERA_INC_0
    lda VERA_DATA1
    bne .fail

    lda #0
    bra .report
.fail
    jsr fx_transp_off
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "FX_TRANSP", $00

; =====================================================================
; The ring buffer is FIFO across an index wrap; the stack is LIFO;
; both report empty/full through the carry.
; =====================================================================
    SUBROUTINE
test_buffers
    jsr rb_init
    jsr rb_get
    bcc .fail                   ; empty reads carry set

    ; push/pop 300 pairs so head and tail wrap the 8-bit index
    stz .i
.wrap
    lda .i
    jsr rb_put
    bcs .fail
    lda .i
    eor #$FF
    jsr rb_put
    bcs .fail
    jsr rb_get
    bcs .fail
    cmp .i
    bne .fail
    jsr rb_get
    bcs .fail
    eor #$FF
    cmp .i
    bne .fail
    inc .i
    bne .wrap                   ; 256 rounds = 512 puts: plenty of wrap
    jsr rb_count
    bne .fail                   ; balanced: empty again

    jsr stk_init
    lda #1
    jsr stk_push
    lda #2
    jsr stk_push
    lda #3
    jsr stk_push
    jsr stk_depth
    cmp #3
    bne .fail
    jsr stk_pop
    cmp #3
    bne .fail
    jsr stk_pop
    cmp #2
    bne .fail
    jsr stk_pop
    cmp #1
    bne .fail
    jsr stk_pop
    bcc .fail                   ; empty

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.i    dc.b 0
.name dc.b "BUFFERS", $00

; =====================================================================
; IMA ADPCM against an independent reference: these 8 bytes were
; decoded by CPython's audioop (nibble-swapped, since audioop eats the
; high nibble first while IMA WAV -- and this decoder -- take the low
; one). 16 samples plus the exact final decoder state must match.
; =====================================================================
    SUBROUTINE
test_adpcm
    jsr adpcm_init
    lda #<.packed
    sta X16_P0
    lda #>.packed
    sta X16_P1
    lda #<.out
    sta X16_P2
    lda #>.out
    sta X16_P3
    lda #8
    sta X16_P4
    stz X16_P5
    jsr adpcm_block

    ldx #0
.check
    lda .out,x
    cmp .expect,x
    bne .fail
    inx
    cpx #32
    bne .check

    lda adpcm_pred              ; final predictor -164 = $FF5C
    cmp #$5C
    bne .fail
    lda adpcm_pred+1
    cmp #$FF
    bne .fail
    lda adpcm_index             ; final step index 29
    cmp #29
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.packed dc.b $17, $28, $93, $4C, $E5, $0A, $71, $BF
.expect                         ; audioop's 16 little-endian samples
    dc.b $0b, $00, $11, $00, $10, $00, $17, $00
    dc.b $21, $00, $1e, $00, $13, $00, $20, $00
    dc.b $32, $00, $11, $00, $fb, $ff, $ff, $ff
    dc.b $09, $00, $3d, $00, $cd, $ff, $5c, $ff
.out    ds 32, 0
.name   dc.b "ADPCM", $00

; =====================================================================
; The DOS command channel: a syntax error is reported as one, the
; status clears, and mkdir/rename/delete/rmdir all round-trip on the
; hostfs device.
; =====================================================================
    SUBROUTINE
test_dos
    lda #<.badcmd               ; nonsense command: an error class code
    ldx #>.badcmd
    ldy #2
    jsr dos_cmd
    bcc .fail_far               ; must be >= 20
    jsr dos_status              ; reading it cleared it
    bcs .fail_far

    lda #<.dirname              ; make a directory...
    ldx #>.dirname
    ldy #4
    jsr dos_mkdir
    bcs .fail_far
    bra .files

.fail_far
    jmp .fail

.files
    ; save a file, rename it, delete it under its new name
    lda #<.fname
    sta X16_P0
    lda #>.fname
    sta X16_P1
    lda #11
    sta X16_P2
    lda #8
    sta X16_P3
    lda #<.fname                ; any 8 bytes will do as content
    sta X16_P5
    lda #>.fname
    sta X16_P6
    lda #<(.fname + 8)
    sta X16_T6
    lda #>(.fname + 8)
    sta X16_T7
    jsr fs_save
    bcs .fail

    lda #<.fname                ; old name in the parameter block
    sta X16_P0
    lda #>.fname
    sta X16_P1
    lda #11
    sta X16_P2
    lda #<.fname2               ; new name in A/X/Y
    ldx #>.fname2
    ldy #11
    jsr dos_rename
    bcs .fail

    lda #<.fname2
    ldx #>.fname2
    ldy #11
    jsr dos_delete
    bcs .fail

    lda #<.dirname              ; leave the fsroot as we found it
    ldx #>.dirname
    ldy #4
    jsr dos_rmdir
    bcs .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.badcmd  dc.b "X9"
.dirname dc.b "TDIR"
.fname   dc.b "TESTDOS.BIN"
.fname2  dc.b "TESTREN.BIN"
.name    dc.b "DOS", $00

; =====================================================================
; BMX round trip: draw a 16x4 stamp and four palette entries, save,
; wreck both, load, and expect pixels, palette, header fields and the
; surrounding VRAM all back exactly. Then a junk file must be refused
; with the format error, and a compressed header with the packed one.
; =====================================================================
    SUBROUTINE
test_bmx
    ; four distinctive palette entries at 40..43
    ldx #40
    lda #$21
    ldy #$03
    jsr pal_set
    ldx #41
    lda #$54
    ldy #$06
    jsr pal_set
    ldx #42
    lda #$87
    ldy #$09
    jsr pal_set
    ldx #43
    lda #$BA
    ldy #$0C
    jsr pal_set

    ; a 16x4 stamp at TESTVRAM+$C00, rows 320 apart, plus guard bytes
    vera_addr 0, TESTVRAM + $BFF, VERA_INC_1
    lda #$77                    ; guard byte just before the stamp
    sta VERA_DATA0
    stz .row
.paint
    lda .row
    stz X16_T4
    asl
    rol X16_T4
    ; row base = $C00 + row*320: with row <= 3, 320*row = row*256+row*64
    ; keep it simple: compute inline
    lda .row
    jsr .row_port0
    ldx #0
.paint_px
    txa
    asl
    asl
    ora .row
    eor #$40
    sta VERA_DATA0
    inx
    cpx #16
    bne .paint_px
    lda #$66                    ; guard byte right after each row
    sta VERA_DATA0
    inc .row
    lda .row
    cmp #4
    bne .paint

    ; describe and save it
    cset16 bmx_width, 16
    cset16 bmx_height, 4
    lda #8
    sta bmx_bpp
    lda #40
    sta bmx_palstart
    cset16 bmx_palcount, 4
    lda #6
    sta bmx_border
    cset16 bmx_stride, 320
    jsr .name_params
    jsr bmx_save
    bcs .fail_far

    ; wreck the pixels, the guards stay
    stz .row
.wreck
    lda .row
    jsr .row_port0
    lda #$EE
    ldx #16
    ldy #0
    jsr vera_fill
    inc .row
    lda .row
    cmp #4
    bne .wreck
    ldx #40                     ; and the palette
    lda #$00
    ldy #$00
    jsr pal_set
    ldx #43
    lda #$00
    ldy #$00
    jsr pal_set
    cset16 bmx_width, 0        ; and the header fields
    stz bmx_palstart

    jsr .name_params            ; load it back
    jsr bmx_load
    bcs .fail_far

    lda bmx_width               ; header round-tripped
    cmp #16
    bne .fail_far
    lda bmx_height
    cmp #4
    bne .fail_far
    lda bmx_palstart
    cmp #40
    bne .fail_far
    lda bmx_border
    cmp #6
    bne .fail_far
    bra .verify

.fail_far
    jmp .fail

.verify
    stz chk_err
    stz .row
.vrows
    lda .row
    jsr .row_port1
    ldx #0
.vpx
    txa
    asl
    asl
    ora .row
    eor #$40
    cmp VERA_DATA1
    bne .fail_mid
    inx
    cpx #16
    bne .vpx
    lda VERA_DATA1              ; the guard byte after the row survived
    cmp #$66
    bne .fail_mid
    inc .row
    lda .row
    cmp #4
    bne .vrows
    vera_addr 1, TESTVRAM + $BFF, VERA_INC_1
    lda VERA_DATA1              ; ...and the one before the stamp
    cmp #$77
    beq .guards_ok
.fail_mid
    jmp .fail
.guards_ok

    vera_addr 1, VRAM_PALETTE + (40*2), VERA_INC_1
    chkv $21                   ; the palette came back
    chkv $03
    chkv $54
    chkv $06
    vera_addr 1, VRAM_PALETTE + (43*2), VERA_INC_1
    chkv $BA
    chkv $0C
    lda chk_err
    bne .fail

    ; a junk file is refused as not-BMX
    lda #<.fname2
    sta X16_P0
    lda #>.fname2
    sta X16_P1
    lda #9
    sta X16_P2
    lda #8
    sta X16_P3
    lda #<.junk
    sta X16_P5
    lda #>.junk
    sta X16_P6
    lda #<(.junk + 16)
    sta X16_T6
    lda #>(.junk + 16)
    sta X16_T7
    jsr fs_save
    bcs .fail
    lda #<.fname2
    sta X16_P0
    lda #>.fname2
    sta X16_P1
    lda #9
    sta X16_P2
    lda #8
    sta X16_P3
    stz X16_P4
    cset16 X16_P5, TESTVRAM
    jsr bmx_load
    bcc .fail                   ; it "loaded" garbage
    cmp #BMX_ERR_FORMAT
    bne .fail

    ; tidy the fsroot
    lda #<.fname
    ldx #>.fname
    ldy #8
    jsr dos_delete
    lda #<.fname2
    ldx #>.fname2
    ldy #9
    jsr dos_delete

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result

; the shared load/save parameter block for TEST.BMX at the stamp
.name_params
    lda #<.fname
    sta X16_P0
    lda #>.fname
    sta X16_P1
    lda #8
    sta X16_P2
    lda #8
    sta X16_P3
    stz X16_P4                  ; VRAM bank 0
    cset16 X16_P5, TESTVRAM + $C00
    rts

; point port 0 / port 1 at row A of the stamp (base + A*320)
.row_port0
    jsr .row_calc
    vera_addrsel 0
    bra .row_set
.row_port1
    jsr .row_calc
    vera_addrsel 1
.row_set
    lda X16_T0
    sta VERA_ADDR_L
    lda X16_T1
    sta VERA_ADDR_M
    lda #(VERA_INC_1 << 4)
    sta VERA_ADDR_H
    rts
.row_calc
    ; T1:T0 = TESTVRAM + $C00 + A*320  (A <= 3, so *320 = *256 + *64)
    sta X16_T2
    stz X16_T3
    asl                         ; A*64 (A <= 3: fits low byte after <<6)
    asl
    asl
    asl
    asl
    asl
    sta X16_T0
    clc
    lda X16_T2                  ; + A*256
    adc #>(TESTVRAM + $C00)
    sta X16_T1
    lda X16_T0
    clc
    adc #<(TESTVRAM + $C00)
    sta X16_T0
    lda X16_T1
    adc #0
    sta X16_T1
    rts

.row    dc.b 0
.fname  dc.b "TEST.BMX"
.fname2 dc.b "JUNK.BMX9"
.junk   dc.b $DE, $AD, $DE, $AD, $DE, $AD, $DE, $AD
        dc.b $DE, $AD, $DE, $AD, $DE, $AD, $DE, $AD
.name   dc.b "BMX", $00

; =====================================================================
; A file that is not there is an I/O error, not a format error.
;
; This is the case OPEN does not report. CBM DOS answers "62,FILE NOT
; FOUND" on the command channel; the KERNAL leaves carry clear on both
; OPEN and CHKIN and only sets ST once a read has been attempted. So a
; reader that trusts carry alone pulls 16 bytes of junk, fails its magic
; check, and blames the file's contents for the file's absence.
;
; BMX_ERR_FORMAT here would be a passing-looking wrong answer, which is
; why this test insists on the exact code rather than merely on failure.
; =====================================================================
    SUBROUTINE
test_bmx_missing
    lda #<.fname
    sta X16_P0
    lda #>.fname
    sta X16_P1
    lda #.fname_len
    sta X16_P2
    lda #8
    sta X16_P3
    stz X16_P4                  ; VRAM bank 0
    cset16 X16_P5, TESTVRAM
    jsr bmx_load
    bcc .fail                   ; it "loaded" a file that does not exist
    cmp #BMX_ERR_IO
    bne .fail

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result

.fname     dc.b "NOSUCH.BMX"
.fname_len = 10
.name      dc.b "BMX_MISSING", $00

; =====================================================================
; t_write_file -- write exactly the bytes given, and nothing else.
;
; fs_save cannot be used to build a test fixture that starts with a
; magic number: the KERNAL's SAVE prepends a two-byte load address. So
; write the file a byte at a time through CHROUT, the same way bmx_save
; does.
;
;   in:  A = filename length, X/Y = filename lo/hi (SETNAM's order)
;        X16_P0/P1 = data address, X16_P2 = byte count (1-255)
;   out: carry set if the file could not be opened
; =====================================================================
    SUBROUTINE
t_write_file
    jsr SETNAM
    lda #2
    ldx #8
    ldy #1                      ; write
    jsr SETLFS
    jsr OPEN
    bcs .bad
    ldx #2
    jsr CHKOUT
    bcs .bad_close

    stz X16_T0                  ; CHROUT is not documented to preserve Y
.put
    ldy X16_T0
    lda (X16_P0),y
    jsr CHROUT
    inc X16_T0
    lda X16_T0
    cmp X16_P2
    bne .put

    jsr CLRCHN
    lda #2
    jsr CLOSE
    clc
    rts
.bad_close
    jsr CLRCHN
    lda #2
    jsr CLOSE
.bad
    sec
    rts

; =====================================================================
; A file that stops in the middle of the image is an I/O error too.
;
; The header here is entirely valid and promises four rows of four
; pixels; the file carries two. Without a status check the remaining
; CHRINs return junk, bmx_load reports success, and half the image is
; whatever VRAM held before -- a silent wrong answer, which is the worst
; kind.
; =====================================================================
    SUBROUTINE
test_bmx_truncated
    cset16 X16_P0, bmt_file
    lda #bmt_file_len
    sta X16_P2
    lda #bmt_fname_len
    ldx #<bmt_fname
    ldy #>bmt_fname
    jsr t_write_file
    bcs bmt_fail

    lda #<bmt_fname
    sta X16_P0
    lda #>bmt_fname
    sta X16_P1
    lda #bmt_fname_len
    sta X16_P2
    lda #8
    sta X16_P3
    stz X16_P4                  ; VRAM bank 0
    cset16 X16_P5, TESTVRAM
    jsr bmx_load
    bcc bmt_fail_del               ; it "loaded" an image that is not all there
    cmp #BMX_ERR_IO
    bne bmt_fail_del

    jsr bmt_unlink
    lda #0
    bra bmt_report
    SUBROUTINE
bmt_fail_del
    jsr bmt_unlink
    SUBROUTINE
bmt_fail
    lda #1
    SUBROUTINE
bmt_report
    ldx #<bmt_name
    ldy #>bmt_name
    jmp t_result

    SUBROUTINE
bmt_unlink
    lda #<bmt_fname
    ldx #>bmt_fname
    ldy #bmt_fname_len
    jmp dos_delete

    SUBROUTINE
bmt_file
    dc.b "BMX"                 ; magic
    dc.b 1                     ; version
    dc.b 8                     ; bits per pixel
    dc.b 3                     ; VERA colour depth code, log2(bpp)
    dc.w 4                     ; width
    dc.w 4                     ; height
    dc.b 1                     ; one palette entry
    dc.b 0                     ; starting at index 0
    dc.w 18                    ; pixel data offset: 16 + 1*2, no gap
    dc.b 0                     ; not compressed
    dc.b 0                     ; border
    dc.b $0F, $00              ; the palette entry
    dc.b 1, 2, 3, 4            ; row 0
    dc.b 5, 6, 7, 8            ; row 1 -- and here the file simply stops
bmt_file_len  = 26

    SUBROUTINE
bmt_fname     dc.b "TRUNC.BMX"
bmt_fname_len = 9
    SUBROUTINE
bmt_name      dc.b "BMX_TRUNCATED", $00

; =====================================================================
; ...and a file that stops inside the PALETTE, before a single pixel.
;
; This one exists because the per-row check above cannot see it. The
; image is one row tall, so that check never runs: it deliberately
; tolerates EOF after the last row, and the last row is the first. Only
; the status test between the palette and the pixels catches this, which
; is why that test is not redundant.
;
; The header asks for four palette entries -- eight bytes -- and the
; file supplies two.
; =====================================================================
    SUBROUTINE
test_bmx_short_pal
    cset16 X16_P0, bsp_file
    lda #bsp_file_len
    sta X16_P2
    lda #bsp_fname_len
    ldx #<bsp_fname
    ldy #>bsp_fname
    jsr t_write_file
    bcs bsp_fail

    lda #<bsp_fname
    sta X16_P0
    lda #>bsp_fname
    sta X16_P1
    lda #bsp_fname_len
    sta X16_P2
    lda #8
    sta X16_P3
    stz X16_P4
    cset16 X16_P5, TESTVRAM
    jsr bmx_load
    bcc bsp_fail_del               ; it "loaded" a palette that is not there
    cmp #BMX_ERR_IO
    bne bsp_fail_del

    jsr bsp_unlink
    lda #0
    bra bsp_report
    SUBROUTINE
bsp_fail_del
    jsr bsp_unlink
    SUBROUTINE
bsp_fail
    lda #1
    SUBROUTINE
bsp_report
    ldx #<bsp_name
    ldy #>bsp_name
    jmp t_result

    SUBROUTINE
bsp_unlink
    lda #<bsp_fname
    ldx #>bsp_fname
    ldy #bsp_fname_len
    jmp dos_delete

    SUBROUTINE
bsp_file
    dc.b "BMX"
    dc.b 1
    dc.b 8                     ; bits per pixel
    dc.b 3
    dc.w 4                     ; width
    dc.w 1                     ; height: ONE row, so no per-row check runs
    dc.b 4                     ; four palette entries = eight bytes...
    dc.b 0
    dc.w 24                    ; pixel data offset: 16 + 4*2
    dc.b 0
    dc.b 0
    dc.b $0F, $00              ; ...of which the file holds two
bsp_file_len  = 18

    SUBROUTINE
bsp_fname     dc.b "SHORTPAL.BMX"
bsp_fname_len = 12
    SUBROUTINE
bsp_name      dc.b "BMX_SHORT_PAL", $00

; =====================================================================
; ZX0: these 30 bytes are the same 96-byte phrase the LZSA2 test uses,
; packed by salvador 1.4.2 (the modern v2 stream). The decompressor
; must reproduce every byte, return the exact end address, and leave
; the guard byte beyond the output untouched.
; =====================================================================
    SUBROUTINE
test_zx0
    lda #$77
    sta .out+96                 ; guard

    lda #<.packed
    sta X16_P0
    lda #>.packed
    sta X16_P1
    lda #<.out
    sta X16_P2
    lda #>.out
    sta X16_P3
    jsr zx0_decompress
    cmp #<(.out+96)
    bne .fail
    cpx #>(.out+96)
    bne .fail
    lda .out+96
    cmp #$77
    bne .fail

    lda #<.out                  ; the payload: the 24-byte phrase x4
    sta T_ZP
    lda #>.out
    sta T_ZP+1
    ldx #4
.rep
    ldy #0
.cmp
    lda (T_ZP),y
    cmp .expect,y
    bne .fail
    iny
    cpy #24
    bne .cmp
    clc
    lda T_ZP
    adc #24
    sta T_ZP
    bcc .next
    inc T_ZP+1
.next
    dex
    bne .rep

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.expect dc.b "X16LIB-DECOMPRESS-TEST!!"
.packed                         ; salvador payload.bin payload.zx0
    dc.b $15, $b8, $58, $31, $36, $4c, $49, $42, $2d, $44, $45, $43
    dc.b $4f, $4d, $50, $52, $45, $53, $53, $2d, $54, $45, $53, $54
    dc.b $21, $d0, $15, $d5, $55, $60
.out    ds 97, 0
.name   dc.b "ZX0", $00

; =====================================================================
; TSCrunch, against the reference Go encoder's output: the standard
; 96-byte phrase (literals + matches), and an RLE-heavy sample that
; exercises the run, zero-run and long-match token paths.
; =====================================================================
    SUBROUTINE
test_tsc
    lda #$77
    sta .out+96                 ; guard

    lda #<.packed
    sta X16_P0
    lda #>.packed
    sta X16_P1
    lda #<.out
    sta X16_P2
    lda #>.out
    sta X16_P3
    jsr tsc_decompress
    cmp #<(.out+96)
    bne .fail_far
    cpx #>(.out+96)
    bne .fail_far
    lda .out+96
    cmp #$77
    bne .fail_far

    lda #<.out                  ; the payload phrase, four times
    sta T_ZP
    lda #>.out
    sta T_ZP+1
    ldx #4
.rep
    ldy #0
.cmp
    lda (T_ZP),y
    cmp .expect,y
    bne .fail_far
    iny
    cpy #24
    bne .cmp
    clc
    lda T_ZP
    adc #24
    sta T_ZP
    bcc .next
    inc T_ZP+1
.next
    dex
    bne .rep
    bra .rle

.fail_far
    jmp .fail

.rle
    ; the 196-byte RLE torture: zeros, text, a $55 run, zeros, text
    lda #<.rpacked
    sta X16_P0
    lda #>.rpacked
    sta X16_P1
    lda #<.rout
    sta X16_P2
    lda #>.rout
    sta X16_P3
    jsr tsc_decompress
    cmp #<(.rout+196)
    bne .fail
    cpx #>(.rout+196)
    bne .fail

    ldx #0                      ; 40 zeros
.z1
    lda .rout,x
    bne .fail
    inx
    cpx #40
    bne .z1
    ldy #0                      ; "RLE-EDGE"
.t1
    lda .rout+40,y
    cmp .redge,y
    bne .fail
    iny
    cpy #8
    bne .t1
    ldx #0                      ; 90 x $55
.fives
    lda .rout+48,x
    cmp #$55
    bne .fail
    inx
    cpx #90
    bne .fives
    ldx #0                      ; 50 zeros
.z2
    lda .rout+138,x
    bne .fail
    inx
    cpx #50
    bne .z2
    ldy #0                      ; "RLE-EDGE" again (a far match)
.t2
    lda .rout+188,y
    cmp .redge,y
    bne .fail
    iny
    cpy #8
    bne .t2

    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.expect dc.b "X16LIB-DECOMPRESS-TEST!!"
.redge  dc.b "RLE-EDGE"
.packed                         ; tscrunch payload.bin payload.tsc
    dc.b $3f, $19, $58, $31, $36, $4c, $49, $42, $2d, $44, $45, $43
    dc.b $4f, $4d, $50, $52, $45, $53, $53, $2d, $54, $45, $53, $54
    dc.b $21, $21, $58, $fe, $18, $cc, $e8, $7f, $20
.rpacked                        ; tscrunch rle.bin rle.tsc
    dc.b $31, $cf, $00, $08, $52, $4c, $45, $2d, $45, $44, $47, $45
    dc.b $ff, $55, $b3, $55, $81, $9e, $94, $20
.out    ds 97, 0
.rout   ds 196, 0
.name   dc.b "TSC", $00

; =====================================================================
; The FX affine sampler: a 2x2-tile map of two 8bpp tiles, sampled by
; a horizontal ray (crossing a tile boundary and wrapping), a vertical
; ray, fx_affine_span into VRAM, and clip mode returning tile 0.
; =====================================================================
    SUBROUTINE
test_fx_affine
    jsr vera_has_fx
    bcs .go
    lda #<.name
    ldx #>.name
    jmp t_skip
.go
    ; tile data at $04800: tile 0 = $40+i, tile 1 = $80+i (i = 0..63)
    vera_addr 0, TESTVRAM + $800, VERA_INC_1
    ldx #0
.tile0
    txa
    ora #$40
    sta VERA_DATA0
    inx
    cpx #64
    bne .tile0
    ldx #0
.tile1
    txa
    ora #$80
    sta VERA_DATA0
    inx
    cpx #64
    bne .tile1

    ; map at $05000, 2x2: [0,1 / 1,0]
    vera_addr 0, TESTVRAM + $1000, VERA_INC_1
    stz VERA_DATA0
    lda #1
    sta VERA_DATA0
    sta VERA_DATA0
    stz VERA_DATA0

    lda #<(TESTVRAM + $800)     ; describe the texture (wrap mode)
    sta X16_P0
    lda #>(TESTVRAM + $800)
    sta X16_P1
    lda #((TESTVRAM + $800) >> 16)
    sta X16_P2
    lda #<(TESTVRAM + $1000)
    sta X16_P3
    lda #>(TESTVRAM + $1000)
    sta X16_P4
    lda #((TESTVRAM + $1000) >> 16)
    sta X16_P5
    stz X16_P6                  ; 2x2 tiles
    stz X16_P7                  ; wrap
    jsr fx_affine_on

    ; ray A: from (0,0), one texel right per read
    stz X16_P0
    stz X16_P1
    stz X16_P2
    stz X16_P3
    cset16 X16_P4, 512
    cset16 X16_P6, 0
    jsr fx_affine_ray

    stz chk_err
    ldx #0                      ; x 0..7: tile 0 row 0 = $40+x
.rowa0
    txa
    ora #$40
    cmp VERA_DATA1
    bne .afail
    inx
    cpx #8
    bne .rowa0
    ldx #0                      ; x 8..15: tile 1 row 0 = $80+x
.rowa1
    txa
    ora #$80
    cmp VERA_DATA1
    bne .afail
    inx
    cpx #8
    bne .rowa1
    lda VERA_DATA1              ; x 16 wraps back to tile 0's $40
    cmp #$40
    bne .afail
    bra .ray_b
.afail
    jmp .fail

.ray_b
    ; ray B: from (2,0), one texel DOWN per read
    cset16 X16_P0, 2
    stz X16_P2
    stz X16_P3
    cset16 X16_P4, 0
    cset16 X16_P6, 512
    jsr fx_affine_ray
    ldx #0                      ; y 0..7: tile 0 column 2 = $40+y*8+2
.colb0
    txa
    asl
    asl
    asl
    ora #$42
    cmp VERA_DATA1
    bne .afail
    inx
    cpx #8
    bne .colb0
    ldx #0                      ; y 8..15: map(0,1) = tile 1
.colb1
    txa
    asl
    asl
    asl
    ora #$82
    cmp VERA_DATA1
    bne .afail
    inx
    cpx #8
    bne .colb1

    ; fx_affine_span: rerun ray A into VRAM and verify the copy
    stz X16_P0
    stz X16_P1
    stz X16_P2
    stz X16_P3
    cset16 X16_P4, 512
    cset16 X16_P6, 0
    jsr fx_affine_ray
    vera_addr 0, TESTVRAM + $D00, VERA_INC_1
    cset16 X16_P0, 16
    jsr fx_affine_span
    jsr fx_off

    vera_addr 1, TESTVRAM + $D00, VERA_INC_1
    chkv $40
    chkv $41
    vera_addr 1, TESTVRAM + $D00 + 8, VERA_INC_1
    chkv $80
    vera_addr 1, TESTVRAM + $D00 + 15, VERA_INC_1
    chkv $87
    lda chk_err
    bne .fail

    ; clip mode: sampling outside the map answers from tile 0
    lda #<(TESTVRAM + $800)
    sta X16_P0
    lda #>(TESTVRAM + $800)
    sta X16_P1
    lda #((TESTVRAM + $800) >> 16)
    sta X16_P2
    lda #<(TESTVRAM + $1000)
    sta X16_P3
    lda #>(TESTVRAM + $1000)
    sta X16_P4
    lda #((TESTVRAM + $1000) >> 16)
    sta X16_P5
    stz X16_P6
    lda #1                      ; clip on
    sta X16_P7
    jsr fx_affine_on

    cset16 X16_P0, 20          ; (20,3): tile x=2, outside a 2x2 map
    cset16 X16_P2, 3
    cset16 X16_P4, 512
    cset16 X16_P6, 0
    jsr fx_affine_ray
    lda VERA_DATA1              ; tile 0 at (20&7, 3) = $40+3*8+4 = $5C
    cmp #$5C
    bne .fail
    jsr fx_off

    lda #0
    bra .report
.fail
    jsr fx_off
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "FX_AFFINE", $00

; =====================================================================
; Banked-RAM streaming: priming 5000 bytes from bank 30 offset 8000
; must consume exactly the 4 KB FIFO, leave the stream's own cursor in
; bank 31, keep 904 bytes pending -- and hand the CALLER's RAM_BANK
; back untouched.
; =====================================================================
    SUBROUTINE
test_pcm_stream_bank
    lda RAM_BANK
    sta .saved
    lda #7
    sta RAM_BANK                ; a bank the streamer must not disturb

    lda #0
    jsr pcm_rate
    lda #$0F
    jsr pcm_ctrl
    jsr pcm_reset
    stz pcm_str_loop

    lda #<8000                  ; offset 8000 in bank 30: the prime
    sta X16_P0                  ; crosses into bank 31 partway
    lda #>8000
    sta X16_P1
    lda #<5000
    sta X16_P2
    lda #>5000
    sta X16_P3
    stz X16_P4                  ; 24-bit count, high byte 0
    lda #30
    sta X16_P5
    lda #0                      ; rate 0: prime but do not play
    jsr pcm_stream_start_bank

    lda RAM_BANK                ; the caller's bank survived priming
    cmp #7
    bne .fail
    jsr pcm_full
    bcc .fail                   ; the FIFO was filled to the brim
    lda pcm_str_bank            ; 8000 + 4095 = 12095: into bank 31
    cmp #31                     ; (the FIFO's full flag asserts at 4095
    bne .fail                   ; -- the ring keeps one slot back)
    lda pcm_str_rem             ; 5000 - 4095 = 905 = $0389 pending
    cmp #<905
    bne .fail
    lda pcm_str_rem+1
    cmp #>905
    bne .fail
    lda pcm_str_rem+2
    bne .fail
    jsr pcm_stream_active
    beq .fail
    lda VERA_IEN
    and #VERA_IRQ_AFLOW
    beq .fail

    jsr pcm_stream_stop
    jsr pcm_reset
    jsr irq_remove
    lda .saved
    sta RAM_BANK
    lda #0
    bra .report
.fail
    jsr pcm_stream_stop
    jsr pcm_reset
    jsr irq_remove
    lda .saved
    sta RAM_BANK
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.saved dc.b 0
.name  dc.b "PCM_STREAM_BANK", $00

; =====================================================================
; Loop mode: a 100-byte sample with pcm_str_loop set must wrap through
; the buffer 40 times while priming (40*100 + 95 = the FIFO's 4095),
; stay active, and keep AFLOW armed -- endless music from a tiny
; buffer.
; =====================================================================
    SUBROUTINE
test_pcm_stream_loop
    lda #0
    jsr pcm_rate
    lda #$0F
    jsr pcm_ctrl
    jsr pcm_reset

    lda #1
    sta pcm_str_loop
    lda #<$2000                 ; any readable RAM does as sample data
    sta X16_P0
    lda #>$2000
    sta X16_P1
    lda #100
    sta X16_P2
    stz X16_P3
    lda #0                      ; rate 0: prime but do not play
    jsr pcm_stream_start

    jsr pcm_full
    bcc .fail                   ; primed to the brim across 40 wraps
    jsr pcm_stream_active
    beq .fail                   ; a looping stream never runs dry
    lda VERA_IEN
    and #VERA_IRQ_AFLOW
    beq .fail
    lda pcm_str_rem             ; 4095 = 40 laps + 95: 5 bytes left in
    cmp #5                      ; the current lap
    bne .fail
    lda pcm_str_rem+1
    ora pcm_str_rem+2
    bne .fail

    jsr pcm_stream_stop
    lda pcm_str_loop            ; the flag is caller-owned: it survives
    cmp #1
    bne .fail

    stz pcm_str_loop
    jsr pcm_reset
    jsr irq_remove
    lda #0
    bra .report
.fail
    jsr pcm_stream_stop
    stz pcm_str_loop
    jsr pcm_reset
    jsr irq_remove
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "PCM_STREAM_LOOP", $00

; ---------------------------------------------------------------------
    include "test_dasm/testlib.asm"

; GFX_READ8: what pset wrote comes back
    SUBROUTINE
test_gfx_read8
    lda #50
    sta X16_P0
    stz X16_P1
    lda #60
    sta X16_P2
    lda #7
    sta X16_P3
    jsr gfx_pset
    lda #50
    sta X16_P0
    stz X16_P1
    lda #60
    sta X16_P2
    jsr gfx_read
    ldy #1
    cmp #7
    bne .report
    ldy #0
.report
    tya
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "GFX_READ8", 0

; GFX_PAT8: an $F0-row pattern paints fg left, bg right of each cell
    SUBROUTINE
test_gfx_pat8
    lda #<.pat
    ldx #>.pat
    sta X16_P0                  ; (pattern_set wants A/X = the pattern)
    lda #1
    sta X16_P4                  ; bg
    lda #2
    sta X16_P5                  ; fg
    lda #<.pat
    ldx #>.pat
    jsr gfx_pattern_set
    lda #64
    sta X16_P0
    stz X16_P1
    lda #100
    sta X16_P2
    lda #16
    sta X16_P4
    stz X16_P5
    lda #2
    sta X16_P6
    jsr gfx_pattern_rect
    ldy #1
    lda #64                     ; column 64&7 = 0: bit 7 of $F0 = fg
    ldx #100
    jsr rd8
    cmp #2
    bne .report
    lda #68                     ; column 68&7 = 4: bit 3 of $F0 = bg
    ldx #100
    jsr rd8
    cmp #1
    bne .report
    lda #79                     ; column 79&7 = 7 on row 101: bg again
    ldx #101
    jsr rd8
    cmp #1
    bne .report
    ldy #0
.report
    tya
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "GFX_PAT8", 0
.pat dc.b $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0

; GFX_BLIT8: copy lands, and a masked zero leaves the screen alone
    SUBROUTINE
test_gfx_blit8
    lda #82                     ; a witness where the source has a hole
    sta X16_P0
    stz X16_P1
    lda #120
    sta X16_P2
    lda #9
    sta X16_P3
    jsr gfx_pset
    lda #80
    sta X16_P0
    stz X16_P1
    lda #120
    sta X16_P2
    lda #4
    sta X16_P4
    lda #1
    sta X16_P5
    lda #<.src
    sta X16_P6
    lda #>.src
    sta X16_P7
    jsr gfx_blitm               ; masked: the $00 must skip the witness
    ldy #1
    lda #80
    ldx #120
    jsr rd8
    cmp #5
    bne .report
    lda #82                     ; the hole: the witness survives
    ldx #120
    jsr rd8
    cmp #9
    bne .report
    lda #80                     ; now a plain copy overwrites everything
    sta X16_P0
    stz X16_P1
    lda #120
    sta X16_P2
    lda #4
    sta X16_P4
    lda #1
    sta X16_P5
    lda #<.src
    sta X16_P6
    lda #>.src
    sta X16_P7
    lda #0
    jsr gfx_blit
    lda #82
    ldx #120
    jsr rd8
    bne .report                 ; the $00 copies over the witness now
    ldy #0
.report
    tya
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "GFX_BLIT8", 0
.src dc.b 5, 6, 0, 8

    SUBROUTINE
rd8                             ; read (A, X) at 8bpp
    sta X16_P0
    stz X16_P1
    stx X16_P2
    phy
    jsr gfx_read
    ply
    ora #0                      ; ply set the flags from Y; re-set from A
    rts

    include "x16_code.asm"
