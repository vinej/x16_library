;ACME
; =====================================================================
; x16lib :: util/sort.asm -- in-place sorting of memory blocks
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Sorts a contiguous block of fixed-size elements in place, ascending.
; There is no "array type" -- you pass a base address and an element
; count, which is exactly what a high-level array is underneath.
;
;   sort_u8  / sort_s8   -- byte elements, unsigned / signed
;   sort_u16 / sort_s16  -- word elements, unsigned / signed
;   sort_ptr             -- 2-byte elements ordered by a caller comparator
;
; One insertion-sort engine drives them all through a comparator vector;
; the typed entries just pick the element size and the comparator. O(n^2)
; but tiny and stable -- right for the modest arrays a 6502 sorts.
;
; Comparator ABI (used by sort_ptr, and internally):
;   in:  X16_PTR2 (P4/P5) = address of element A
;        X16_PTR3 (P6/P7) = address of element B
;   out: carry SET if A must sort AFTER B (A > B), clear otherwise.
;   May use A/X/Y; must not disturb the srt_* state.
; =====================================================================

; (zone: file scope in dasm)

    SUBROUTINE
srt_base  dc.w 0              ; base address of the array
    SUBROUTINE
srt_count dc.w 0              ; element count
    SUBROUTINE
srt_size  dc.b 0              ; element size in bytes (1 or 2)
    SUBROUTINE
srt_cmp   dc.w 0              ; comparator routine vector
    SUBROUTINE
srt_i     dc.w 0              ; outer index
    SUBROUTINE
srt_j     dc.w 0              ; inner index
    SUBROUTINE
srt_key   ds 2, 0           ; the element being inserted

; ---------------------------------------------------------------------
; public entry points -- in: X16_P0/P1 = base, X16_P2/P3 = count
; ---------------------------------------------------------------------
    SUBROUTINE
sort_u8
    ldx #1
    lda #<sort_cmp_u8
    ldy #>sort_cmp_u8
    bra sort_setup
    SUBROUTINE
sort_s8
    ldx #1
    lda #<sort_cmp_s8
    ldy #>sort_cmp_s8
    bra sort_setup
    SUBROUTINE
sort_u16
    ldx #2
    lda #<sort_cmp_u16
    ldy #>sort_cmp_u16
    bra sort_setup
    SUBROUTINE
sort_s16
    ldx #2
    lda #<sort_cmp_s16
    ldy #>sort_cmp_s16
    bra sort_setup

; sort_ptr -- element size 2, comparator address in X16_P4/P5
    SUBROUTINE
sort_ptr
    lda X16_P4
    ldy X16_P5
    ldx #2
    ; fall through to sort_setup

    SUBROUTINE
sort_setup
    stx srt_size
    sta srt_cmp
    sty srt_cmp+1
    lda X16_P0
    sta srt_base
    lda X16_P1
    sta srt_base+1
    lda X16_P2
    sta srt_count
    lda X16_P3
    sta srt_count+1

    ; nothing to do for fewer than two elements
    lda srt_count+1
    bne sort_start
    lda srt_count
    cmp #2
    bcs sort_start
    SUBROUTINE
sort_done
    rts
    SUBROUTINE
sort_start
    lda #1                     ; i = 1
    sta srt_i
    stz srt_i+1

    SUBROUTINE
sort_outer
    ; while i < count
    lda srt_i+1
    cmp srt_count+1
    bcc sort_body
    bne sort_done
    lda srt_i
    cmp srt_count
    bcs sort_done
    SUBROUTINE
sort_body
    ; key = arr[i]
    lda srt_i
    sta X16_T0
    lda srt_i+1
    sta X16_T1
    jsr sort_addr2                 ; P4/P5 = &arr[i]
    jsr sort_load_key

    ; j = i - 1  (i >= 1 so this does not underflow)
    lda srt_i
    sec
    sbc #1
    sta srt_j
    lda srt_i+1
    sbc #0
    sta srt_j+1

    SUBROUTINE
sort_inner
    ; P4/P5 = &arr[j],  P6/P7 = &srt_key,  compare
    lda srt_j
    sta X16_T0
    lda srt_j+1
    sta X16_T1
    jsr sort_addr2                 ; P4/P5 = &arr[j]
    lda #<srt_key
    sta X16_P6
    lda #>srt_key
    sta X16_P7
    jsr sort_callcmp               ; carry set if arr[j] > key
    bcc sort_place_jp1

    ; arr[j+1] = arr[j]
    lda srt_j                  ; T0/T1 = j+1
    clc
    adc #1
    sta X16_T0
    lda srt_j+1
    adc #0
    sta X16_T1
    jsr sort_addr3                 ; P6/P7 = &arr[j+1]  (dest; P4/P5 still &arr[j])
    jsr sort_copy_elem

    ; if j == 0, key belongs at arr[0]
    lda srt_j
    ora srt_j+1
    beq sort_place_0

    lda srt_j                  ; j--
    sec
    sbc #1
    sta srt_j
    lda srt_j+1
    sbc #0
    sta srt_j+1
    bra sort_inner

    SUBROUTINE
sort_place_0
    stz X16_T0                 ; &arr[0]
    stz X16_T1
    jsr sort_addr3
    jsr sort_store_key
    bra sort_next_i

    SUBROUTINE
sort_place_jp1
    lda srt_j                  ; &arr[j+1]
    clc
    adc #1
    sta X16_T0
    lda srt_j+1
    adc #0
    sta X16_T1
    jsr sort_addr3
    jsr sort_store_key

    SUBROUTINE
sort_next_i
    inc srt_i
    bne .loop
    inc srt_i+1
.loop
    jmp sort_outer

; --- address arithmetic ----------------------------------------------
; sort_addr2 / sort_addr3 : X16_T0/T1 = index -> P4/P5 (resp. P6/P7) = base+index*size
    SUBROUTINE
sort_addr2
    ldx srt_size
    cpx #2
    beq .two
    clc
    lda srt_base
    adc X16_T0
    sta X16_P4
    lda srt_base+1
    adc X16_T1
    sta X16_P5
    rts
.two
    lda X16_T0
    asl
    sta X16_T2
    lda X16_T1
    rol
    sta X16_T3
    clc
    lda srt_base
    adc X16_T2
    sta X16_P4
    lda srt_base+1
    adc X16_T3
    sta X16_P5
    rts

    SUBROUTINE
sort_addr3
    ldx srt_size
    cpx #2
    beq .two3
    clc
    lda srt_base
    adc X16_T0
    sta X16_P6
    lda srt_base+1
    adc X16_T1
    sta X16_P7
    rts
.two3
    lda X16_T0
    asl
    sta X16_T2
    lda X16_T1
    rol
    sta X16_T3
    clc
    lda srt_base
    adc X16_T2
    sta X16_P6
    lda srt_base+1
    adc X16_T3
    sta X16_P7
    rts

; --- element moves ---------------------------------------------------
    SUBROUTINE
sort_load_key
    ldy #0
    lda (X16_P4),y
    sta srt_key
    ldx srt_size
    cpx #2
    bne .done
    iny
    lda (X16_P4),y
    sta srt_key+1
.done
    rts

    SUBROUTINE
sort_store_key
    ldy #0
    lda srt_key
    sta (X16_P6),y
    ldx srt_size
    cpx #2
    bne .done2
    iny
    lda srt_key+1
    sta (X16_P6),y
.done2
    rts

    SUBROUTINE
sort_copy_elem
    ldy #0
    lda (X16_P4),y
    sta (X16_P6),y
    ldx srt_size
    cpx #2
    bne .done3
    iny
    lda (X16_P4),y
    sta (X16_P6),y
.done3
    rts

    SUBROUTINE
sort_callcmp
    jmp (srt_cmp)

; --- built-in comparators (A at P4/P5, B at P6/P7; C set iff A > B) ----
; Each is self-contained (no far branches to shared exits).
    SUBROUTINE
sort_cmp_u8
    ldy #0
    lda (X16_P4),y
    cmp (X16_P6),y             ; C = (A >= B)
    bne .ret                  ; not equal -> C is already (A > B)
    clc                       ; equal -> not greater
.ret
    rts

    SUBROUTINE
sort_cmp_s8
    ldy #0
    lda (X16_P4),y
    cmp (X16_P6),y
    beq .eq
    lda (X16_P4),y
    sec
    sbc (X16_P6),y
    bvc .nov
    eor #$80
.nov
    bmi .lt                   ; N set -> A < B
    sec                       ; A > B
    rts
.lt
.eq
    clc
    rts

    SUBROUTINE
sort_cmp_u16
    ldy #1
    lda (X16_P4),y            ; high bytes
    cmp (X16_P6),y
    bne .ne                   ; high differs -> C decides
    dey
    lda (X16_P4),y            ; low bytes
    cmp (X16_P6),y
    bne .ne
    clc                       ; fully equal
    rts
.ne
    rts                       ; C = (A > B), since not equal

    SUBROUTINE
sort_cmp_s16
    ldy #1
    lda (X16_P4),y
    cmp (X16_P6),y
    bne .hidiff
    dey
    lda (X16_P4),y
    cmp (X16_P6),y            ; hi equal: low bytes decide (same sign)
    bne .lodiff
    clc                       ; fully equal
    rts
.lodiff
    rts                       ; C = (A > B)
.hidiff
    lda (X16_P4),y            ; y=1, signed compare of high bytes
    sec
    sbc (X16_P6),y
    bvc .nov2
    eor #$80
.nov2
    bmi .lt2                  ; A < B
    sec                       ; A > B
    rts
.lt2
    clc
    rts

; (end zone)
