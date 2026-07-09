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
; screen_color must actually change what CHROUT puts in VRAM, not just
; poke a KERNAL variable.  Verify through the tilemap attribute byte.
; =====================================================================
test_color_reaches_vram
    jsr screen_cls
    lda #1                      ; foreground white
    ldx #6                      ; background blue
    jsr screen_color

    ldx #0                      ; row 0
    ldy #0                      ; column 0
    jsr screen_locate
    lda #'X'
    jsr CHROUT

    ; Cell (0,0) is two bytes: screen code, then attribute.
    +vera_addr 1, VRAM_TEXT, VERA_INC_1
    lda VERA_DATA1
    sta @gotchar
    lda VERA_DATA1
    sta @gotattr

    lda @gotattr
    cmp #$61                    ; fg 1 | bg 6 << 4
    bne @fail
    lda @gotchar
    beq @fail                   ; nothing was drawn

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
