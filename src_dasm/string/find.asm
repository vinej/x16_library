;ACME
; =====================================================================
; x16lib :: string/find.asm -- searching within a string
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Locate a character (forward or backward), find the first line ending,
; test membership, or match a wildcard pattern. The string is passed in
; A (low) / X (high); the character to look for is in Y. The find
; routines answer in A -- the index when they hit, 255 when they miss --
; and set the carry to say the same thing, so a caller can read whichever
; suits it.
;
;       lda #<path : ldx #>path
;       ldy #'/
;       jsr str_rfind                 ; A = index of the last '/, or 255
; =====================================================================

; (zone: file scope in dasm)

; ---------------------------------------------------------------------
; str_find -- first index of a character, scanning left to right.
;   in:  A = low, X = high, Y = character
;   out: A = the index, or 255 when the character is not there
;        (the carry says the same thing: set when found)
; ---------------------------------------------------------------------
    SUBROUTINE
str_find
    sta X16_T0
    stx X16_T1
    sty X16_T2
    ldy #0
.loop
    lda (X16_T0),y
    beq .notfound
    cmp X16_T2
    beq .found
    iny
    bne .loop
.notfound
    lda #255
    clc
    rts
.found
    tya
    sec
    rts

; ---------------------------------------------------------------------
; str_contains -- carry set if the character occurs in the string.
;   in: A = low, X = high, Y = character
; ---------------------------------------------------------------------
    SUBROUTINE
str_contains
    jmp str_find

; ---------------------------------------------------------------------
; str_find_eol -- first index of a CR (13) or LF (10).
;   in:  A = low, X = high
;   out: A = the index, or 255 when the character is not there
;        (the carry says the same thing: set when found)
; ---------------------------------------------------------------------
    SUBROUTINE
str_find_eol
    sta X16_T0
    stx X16_T1
    ldy #0
.loop
    lda (X16_T0),y
    beq .notfound
    cmp #13
    beq .found
    cmp #10
    beq .found
    iny
    bne .loop
.notfound
    lda #255
    clc
    rts
.found
    tya
    sec
    rts

; ---------------------------------------------------------------------
; str_rfind -- first index of a character, scanning right to left.
;   in:  A = low, X = high, Y = character
;   out: A = the index, or 255 when the character is not there
;        (the carry says the same thing: set when found)
; ---------------------------------------------------------------------
    SUBROUTINE
str_rfind
    sty X16_T2
    sta X16_T0
    stx X16_T1
    ldy #0
.len
    lda (X16_T0),y
    beq .gotlen
    iny
    bne .len
.gotlen
    cpy #0
    beq .notfound               ; empty string
    dey                         ; start at the last character
.loop
    lda (X16_T0),y
    cmp X16_T2
    beq .found
    dey
    cpy #255                    ; walked past index 0
    bne .loop
.notfound
    lda #255
    clc
    rts
.found
    tya
    sec
    rts

; ---------------------------------------------------------------------
; str_pattern_match -- match a string against a wildcard pattern.
;   in:  A = string low, X = string high, X16_P0/P1 = pattern
;   out: carry set (and A = 1) if it matches, else carry clear (A = 0)
;
; In the pattern, '? matches any single character and '* matches any
; run of characters including none. Case-sensitive. Both string and
; pattern are NUL-terminated and at most 255 long.
;
; This used to recurse once per '*, costing 4 bytes of CPU stack each --
; a legal 255-character pattern with 64 of them overflowed the stack --
; and it re-tried the tail from scratch after every failed position, so a
; pattern like "a*a*a*a*b" against a long run of 'as took exponential
; time. The walk below keeps only the last '* and the point it had
; swallowed up to, which is all the backtracking a single-wildcard
; grammar needs: no recursion, no stack growth, and a bounded number of
; retries per character.
;
; Zone-local labels throughout (no .cheap) because the pattern address is
; self-modified into the loads, and an SMC target mid-routine would split
; a cheap scope under some assemblers.
; ---------------------------------------------------------------------
    SUBROUTINE
find_pm_star
    dc.b 0               ; pattern index of the live '*, $FF none
    SUBROUTINE
find_pm_mark
    dc.b 0               ; how much of the string it has swallowed

    SUBROUTINE
str_pattern_match
    sta X16_T0                  ; strptr = the string
    stx X16_T1
    lda X16_P0                  ; patch the pattern address into both loads
    sta find_pm_pat1+1
    sta find_pm_pat2+1
    lda X16_P1
    sta find_pm_pat1+2
    sta find_pm_pat2+2
    lda #$ff
    sta find_pm_star                ; no '* met yet
    stz find_pm_mark
    ldx #0                      ; X indexes the pattern
    ldy #0                      ; Y indexes the string
    SUBROUTINE
find_pm_next
    lda (X16_T0),y
    beq find_pm_tail                ; string spent: only '* may remain
    SUBROUTINE
find_pm_pat1
    lda $ffff,x                 ; pattern[X]  (address patched above)
    cmp #'*
    beq find_pm_seen
    cmp #'?
    beq find_pm_step                ; '? takes any character but the NUL,
    cmp (X16_T0),y              ; and the NUL was ruled out above
    bne find_pm_back
    SUBROUTINE
find_pm_step
    inx
    iny
    bra find_pm_next
    SUBROUTINE
find_pm_seen
    stx find_pm_star                ; remember where to resume the pattern...
    inx
    sty find_pm_mark                ; ...and what the '* has taken so far
    bra find_pm_next
    SUBROUTINE
find_pm_back
    ldx find_pm_star
    cpx #$ff
    beq find_pm_no                  ; no '* to give ground: it cannot match
    inx                         ; resume just past that '*...
    inc find_pm_mark                ; ...letting it swallow one more character
    ldy find_pm_mark
    bra find_pm_next
    SUBROUTINE
find_pm_tail
    SUBROUTINE
find_pm_pat2
    lda $ffff,x
    beq find_pm_yes
    cmp #'*
    bne find_pm_no
    inx
    bra find_pm_tail
    SUBROUTINE
find_pm_no
    lda #0
    clc
    rts
    SUBROUTINE
find_pm_yes
    lda #1
    sec
    rts

; (end zone)
