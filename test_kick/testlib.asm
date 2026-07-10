//ACME
// =====================================================================
// x16lib :: test/testlib.asm -- tiny on-target assertion harness
// =====================================================================
// Each test prints "PASS <name>" or "FAIL <name>" through CHROUT, and
// the run ends with "DONE <passes>/<total>" in hex. build.ps1 -Test
// greps stdout: any FAIL, or a pass count that disagrees with the total,
// fails the build.
//
// Uses its own scratch so it can never mask a library bug by sharing
// X16_T0..T7 with the code under test.
// =====================================================================

// (zone: file scope in KickAssembler)

// The harness needs a zero-page pointer of its own for (indirect),y.
// Kept well away from the library's X16_ZP block so a test can never
// pass by accidentally sharing scratch with the code it is checking.
#if !T_ZP_SET
.label T_ZP = $70
#endif
.label t_ptr = T_ZP              // 2 bytes: T_ZP, T_ZP+1

t_passes: .byte 0
t_total: .byte 0
t_skips: .byte 0
t_expected: .byte 0

// ---------------------------------------------------------------------
// t_init -- reset counters
// ---------------------------------------------------------------------
t_init:
    stz t_passes
    stz t_total
    stz t_skips
    rts

// ---------------------------------------------------------------------
// t_puts -- print a NUL-terminated string.  in: A = lo, X = hi
// ---------------------------------------------------------------------
t_puts:
    sta t_ptr
    stx t_ptr+1
    // A test may hand us the machine with port 1 selected. KERNAL screen
    // routines assume ADDRSEL = 0 and will corrupt the display (and this
    // harness's own output) otherwise -- see video/screen.asm.
    vera_addrsel(0)
    ldy #0
t_puts__loop:
    lda (t_ptr),y
    beq t_puts__done
    jsr CHROUT
    iny
    bne t_puts__loop
t_puts__done:
    rts

// ---------------------------------------------------------------------
// t_puthex -- print A as two hex digits
// ---------------------------------------------------------------------
t_puthex:
    pha
    lsr
    lsr
    lsr
    lsr
    jsr t_puthex__nibble                 // high nibble
    pla
    and #$0F                    // fall through for the low nibble
t_puthex__nibble:
    cmp #10
    bcs t_puthex__letter
    clc
    adc #'0'
    jmp CHROUT
t_puthex__letter:
    clc
    adc #('A' - 10)
    jmp CHROUT

// ---------------------------------------------------------------------
// t_pass / t_fail -- in: A = name lo, X = name hi
// ---------------------------------------------------------------------
// Each result begins with a CR so the "PASS"/"FAIL" token always starts a
// line, whatever the test under check left on the current one (a test may
// legitimately clear the screen or print into the tilemap). build.ps1
// anchors its regex to the line start, and that anchor is what catches a
// test whose result never got reported.
t_pass:
    inc t_passes
    inc t_total
    pha
    phx
    lda #$0D
    jsr CHROUT
    lda #<t_pass__word
    ldx #>t_pass__word
    jsr t_puts
    plx
    pla
    jsr t_puts
    rts
t_pass__word: .text "PASS "
    .byte $00

t_fail:
    inc t_total
    pha
    phx
    lda #$0D
    jsr CHROUT
    lda #<t_fail__word
    ldx #>t_fail__word
    jsr t_puts
    plx
    pla
    jsr t_puts
    rts
t_fail__word: .text "FAIL "
    .byte $00

// ---------------------------------------------------------------------
// t_skip -- in: A = name lo, X = name hi
//
// For a check the target machine genuinely cannot perform, as opposed to
// one that failed. Counted separately and excluded from the pass/total
// in DONE, so a skip can never be mistaken for a pass. Use it only where
// an independent oracle proved the capability is absent -- never to
// paper over a failure.
// ---------------------------------------------------------------------
t_skip:
    inc t_skips
    pha
    phx
    lda #$0D
    jsr CHROUT
    lda #<t_skip__word
    ldx #>t_skip__word
    jsr t_puts
    plx
    pla
    jsr t_puts
    rts
t_skip__word: .text "SKIP "
    .byte $00

// ---------------------------------------------------------------------
// t_result -- report a test by its outcome.
//   in: A = 0 for pass, non-zero for fail
//       X = name lo, Y = name hi
// ---------------------------------------------------------------------
t_result:
    cmp #0
    bne t_result__failed
    txa                         // A = name lo
    phy
    plx                         // X = name hi
    jmp t_pass
t_result__failed:
    txa
    phy
    plx
    jmp t_fail

// ---------------------------------------------------------------------
// t_summary -- print "DONE <passes>/<total>"
// ---------------------------------------------------------------------
t_summary:
    lda #$0D
    jsr CHROUT
    lda #<t_summary__done
    ldx #>t_summary__done
    jsr t_puts
    lda t_passes
    jsr t_puthex
    lda #'/'
    jsr CHROUT
    lda t_total
    jsr t_puthex

    lda t_skips
    beq t_summary__end
    pha
    lda #<t_summary__skipped
    ldx #>t_summary__skipped
    jsr t_puts
    pla
    jsr t_puthex
t_summary__end:
    lda #$0D
    jmp CHROUT
t_summary__done: .text "DONE "
    .byte $00
t_summary__skipped: .text " SKIP "
    .byte $00

// ---------------------------------------------------------------------
// t_vcmp_const -- compare a run of VRAM bytes against a constant.
//   in:  A = expected byte, X = count (1..255)
//   pre: port 1 already points at the first byte, with its increment
//   out: A = 0 if every byte matched, 1 otherwise
// ---------------------------------------------------------------------
t_vcmp_const:
    sta t_expected
t_vcmp_const__loop:
    lda VERA_DATA1
    cmp t_expected
    bne t_vcmp_const__bad
    dex
    bne t_vcmp_const__loop
    lda #0
    rts
t_vcmp_const__bad:
    lda #1
    rts

// (end zone)
