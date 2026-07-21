//ACME
// =====================================================================
// x16lib :: string/case.asm -- upper/lower case conversion
// =====================================================================
// This file EMITS CODE. Source it exactly once (x16_code.asm does).
//
// Whole-string (in place) and single-character case folding, in both
// encodings. PETSCII and ISO place the letters at different codes, so the
// two encodings genuinely swap: PETSCII "lower" is numerically ISO "upper"
// and vice versa -- that is not a bug, it is the charset. The whole-string
// routines return the string length in Y. The compare routines fold both
// sides before comparing and return -1/0/1 like str_compare.
//
//       lda #<name : ldx #>name : jsr str_upper     ; NAME, in place
//       lda mychar : jsr str_lowerchar              ; A = folded char
// =====================================================================

// (zone: file scope in KickAssembler)

// ---------------------------------------------------------------------
// str_lowerchar / str_lowerchar_iso -- fold one character to lower case
// str_upperchar / str_upperchar_iso -- ...to upper case.  in/out: A
// ---------------------------------------------------------------------
str_lowerchar:
    and #$7f
    cmp #97
    bcc str_lowerchar__done
    cmp #123
    bcs str_lowerchar__done
    and #%11011111
str_lowerchar__done:
    rts

str_lowerchar_iso:
    cmp #65
    bcc str_lowerchar_iso__done
    cmp #91
    bcs str_lowerchar_iso__done
    ora #$20
str_lowerchar_iso__done:
    rts

str_upperchar:
    cmp #65
    bcc str_upperchar__done
    cmp #91
    bcs str_upperchar__done
    ora #%00100000
str_upperchar__done:
    rts

str_upperchar_iso:
    cmp #97
    bcc str_upperchar_iso__done
    cmp #123
    bcs str_upperchar_iso__done
    and #%11011111
str_upperchar_iso__done:
    rts

// ---------------------------------------------------------------------
// str_lower / str_lower_iso -- fold a whole string to lower case in place.
// str_upper / str_upper_iso -- ...to upper case.
//   in: A = low, X = high.  out: Y = length
// ---------------------------------------------------------------------
str_lower:
    sta X16_T0
    stx X16_T1
    ldy #0
str_lower__loop:
    lda (X16_T0),y
    beq str_lower__done
    jsr str_lowerchar
    sta (X16_T0),y
    iny
    bne str_lower__loop
str_lower__done:
    rts

str_lower_iso:
    sta X16_T0
    stx X16_T1
    ldy #0
str_lower_iso__loop:
    lda (X16_T0),y
    beq str_lower_iso__done
    jsr str_lowerchar_iso
    sta (X16_T0),y
    iny
    bne str_lower_iso__loop
str_lower_iso__done:
    rts

str_upper:
    sta X16_T0
    stx X16_T1
    ldy #0
str_upper__loop:
    lda (X16_T0),y
    beq str_upper__done
    jsr str_upperchar
    sta (X16_T0),y
    iny
    bne str_upper__loop
str_upper__done:
    rts

str_upper_iso:
    sta X16_T0
    stx X16_T1
    ldy #0
str_upper_iso__loop:
    lda (X16_T0),y
    beq str_upper_iso__done
    jsr str_upperchar_iso
    sta (X16_T0),y
    iny
    bne str_upper_iso__loop
str_upper_iso__done:
    rts

// ---------------------------------------------------------------------
// str_compare_nocase / str_compare_nocase_iso -- case-insensitive compare.
//   in:  A = string1 low, X = string1 high, X16_P0/P1 = string2
//   out: A = $FF (-1) if string1 < string2, 0 if equal, 1 if greater
// ---------------------------------------------------------------------
str_compare_nocase:
    sta X16_T0
    stx X16_T1
    ldy #0
str_compare_nocase__loop:
    lda (X16_T0),y
    beq str_compare_nocase__s1end
    jsr str_lowerchar
    sta X16_T2
    lda (X16_P0),y
    jsr str_lowerchar
    cmp X16_T2
    bne str_compare_nocase__diff
    iny
    bne str_compare_nocase__loop
    lda #0
    rts
str_compare_nocase__diff:
    bcc str_compare_nocase__greater                // folded s2 < folded s1 -> string1 sorts after
    lda #$FF
    rts
str_compare_nocase__greater:
    lda #1
    rts
str_compare_nocase__s1end:
    lda (X16_P0),y
    beq str_compare_nocase__same
    lda #$FF
    rts
str_compare_nocase__same:
    lda #0
    rts

str_compare_nocase_iso:
    sta X16_T0
    stx X16_T1
    ldy #0
str_compare_nocase_iso__loop:
    lda (X16_T0),y
    beq str_compare_nocase_iso__s1end
    jsr str_lowerchar_iso
    sta X16_T2
    lda (X16_P0),y
    jsr str_lowerchar_iso
    cmp X16_T2
    bne str_compare_nocase_iso__diff
    iny
    bne str_compare_nocase_iso__loop
    lda #0
    rts
str_compare_nocase_iso__diff:
    bcc str_compare_nocase_iso__greater
    lda #$FF
    rts
str_compare_nocase_iso__greater:
    lda #1
    rts
str_compare_nocase_iso__s1end:
    lda (X16_P0),y
    beq str_compare_nocase_iso__same
    lda #$FF
    rts
str_compare_nocase_iso__same:
    lda #0
    rts

// (end zone)
