;ACME
; =====================================================================
; x16lib :: string/find.asm -- searching within a string
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Locate a character (forward or backward), find the first line ending,
; test membership, or match a wildcard pattern. The string is passed in
; A (low) / X (high); the character to look for is in Y. The find
; routines return the carry set and the index in A when they hit, or the
; carry clear and A = 255 when they miss.
;
;       lda #<path : ldx #>path
;       ldy #'/'
;       jsr str_rfind                 ; index of the last '/', carry set
; =====================================================================

!zone x16_find {

; ---------------------------------------------------------------------
; str_find -- first index of a character, scanning left to right.
;   in:  A = low, X = high, Y = character
;   out: carry set + A = index if found; carry clear + A = 255 if not
; ---------------------------------------------------------------------
str_find
    sta X16_T0
    stx X16_T1
    sty X16_T2
    ldy #0
@loop
    lda (X16_T0),y
    beq @notfound
    cmp X16_T2
    beq @found
    iny
    bne @loop
@notfound
    lda #255
    clc
    rts
@found
    tya
    sec
    rts

; ---------------------------------------------------------------------
; str_contains -- carry set if the character occurs in the string.
;   in: A = low, X = high, Y = character
; ---------------------------------------------------------------------
str_contains
    jmp str_find

; ---------------------------------------------------------------------
; str_find_eol -- first index of a CR (13) or LF (10).
;   in:  A = low, X = high
;   out: carry set + A = index if found; carry clear + A = 255 if not
; ---------------------------------------------------------------------
str_find_eol
    sta X16_T0
    stx X16_T1
    ldy #0
@loop
    lda (X16_T0),y
    beq @notfound
    cmp #13
    beq @found
    cmp #10
    beq @found
    iny
    bne @loop
@notfound
    lda #255
    clc
    rts
@found
    tya
    sec
    rts

; ---------------------------------------------------------------------
; str_rfind -- first index of a character, scanning right to left.
;   in:  A = low, X = high, Y = character
;   out: carry set + A = index if found; carry clear + A = 255 if not
; ---------------------------------------------------------------------
str_rfind
    sty X16_T2
    sta X16_T0
    stx X16_T1
    ldy #0
@len
    lda (X16_T0),y
    beq @gotlen
    iny
    bne @len
@gotlen
    cpy #0
    beq @notfound               ; empty string
    dey                         ; start at the last character
@loop
    lda (X16_T0),y
    cmp X16_T2
    beq @found
    dey
    cpy #255                    ; walked past index 0
    bne @loop
@notfound
    lda #255
    clc
    rts
@found
    tya
    sec
    rts

; ---------------------------------------------------------------------
; str_pattern_match -- match a string against a wildcard pattern.
;   in:  A = string low, X = string high, X16_P0/P1 = pattern
;   out: carry set (and A = 1) if it matches, else carry clear (A = 0)
;
; In the pattern, '?' matches any single character and '*' matches any
; run of characters including none. Case-sensitive. Both string and
; pattern are NUL-terminated and at most 255 long. Each '*' costs 4 bytes
; of CPU stack. Algorithm from 6502.org/source/strings/patmatch.htm.
;
; The whole matcher is written with zone-local labels (no @cheap) because
; it self-modifies (the pattern address is patched into two loads) and
; recurses -- an SMC target mid-routine would otherwise split a cheap
; scope under some assemblers.
; ---------------------------------------------------------------------
str_pattern_match
    sta X16_T0                  ; strptr = the string
    stx X16_T1
    lda X16_P0                  ; patch the pattern address into both loads
    sta .pm_pat1+1
    sta .pm_pat2+1
    lda X16_P1
    sta .pm_pat1+2
    sta .pm_pat2+2
    jsr .pm_match               ; carry = the match result
    lda #0
    bcc @done                   ; keep the carry; set A = 1 on a match
    lda #1
@done
    rts

.pm_match
    ldx #0                      ; X indexes the pattern
    ldy #$ff                    ; Y indexes the string (iny brings it to 0)
.pm_next
.pm_pat1
    lda $ffff,x                 ; pattern[X]  (address patched above)
    cmp #'*'
    beq .pm_star
    iny
    cmp #'?'
    bne .pm_reg
    lda (X16_T0),y              ; '?' matches anything but the terminator
    beq .pm_fail
.pm_reg
    cmp (X16_T0),y
    bne .pm_fail
    inx
    cmp #0                      ; matched the NUL: end of both
    bne .pm_next
    rts                         ; carry set = match
.pm_star
    inx
.pm_pat2
    cmp $ffff,x                 ; a run of '*' is the same as one
    beq .pm_star
.pm_stloop
    txa
    pha
    tya
    pha
    jsr .pm_next                ; try to match the rest here
    pla
    tay
    pla
    tax
    bcs .pm_done                ; it matched: keep the carry set
    iny
    lda (X16_T0),y              ; grow what '*' swallows, unless at the end
    bne .pm_stloop
.pm_fail
    clc
.pm_done
    rts

}   ; !zone x16_find
