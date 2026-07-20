;ACME
; =====================================================================
; x16lib example :: m_numbers.asm  (the macro edition of numbers.asm)
; =====================================================================
; The same tour of the number libraries as numbers.asm. The original
; hand-rolls its own +fset / +fget / +say helpers out of lda/ldx/jsr;
; here they are one-liners built on the optional friendly macro layer
; (core/sugar.asm) -- +xm_f_from_s16, +xm_f_store, +xm_f_load,
; +xm_screen_puts -- and the float expressions in the body call
; +xm_f_div / +xm_f_pow / +xm_f_from_str / +xm_f_cmp directly.
;
; The argument-free accumulator ops (i16_divmod, i16_sqrt, f_sqrt, f_sin,
; f_int, ...) have no macro -- a wrapper would add nothing -- so they are
; still plain jsr. That is the whole point: macros for the calls that
; take arguments, direct calls for the ones that do not.
;
;   run.bat m_numbers        (also runs headless: no VSYNC)
; =====================================================================

!cpu 65c02
!source "x16.asm"

X16_USE_SCREEN = 1
X16_USE_INT16  = 1
X16_USE_INT32  = 1
X16_USE_FIXED  = 1
X16_USE_FLOAT  = 1

!source "core/sugar.asm"        ; the +xm_* macros (gated by the above)

; --- local shorthands, now built on the xm_ layer --------------------
!macro say .addr {
    +xm_screen_puts .addr
}
!macro nl {
    +xm_screen_chrout 13
}
; a float from a signed 16-bit literal, stored at .addr
!macro fset .addr, .value {
    +xm_f_from_s16 .value
    +xm_f_store .addr
}
; load the float at .addr into FAC
!macro fget .addr {
    +xm_f_load .addr
}
; print FAC, then a newline
!macro fshow {
    jsr f_to_str_trim           ; FAC -> string (no argument: direct)
    jsr screen_puts             ; the pointer is f_to_str_trim's, not a const
    +nl
}

* = $0801
    +basic_stub

; =====================================================================
main
    +xm_screen_cls
    jsr show_int16
    jsr show_int32
    jsr show_fixed
    jsr show_float
    +nl
    +say msg_done
    rts

; =====================================================================
; 16-bit integers -- util/int16.asm  (operands via +i16_const; ops direct)
; =====================================================================
show_int16
    +say hdr_i16

    +say lbl_udiv               ; 1000 / 7 = 142 remainder 6
    +i16_const i16_a, 1000
    +i16_const i16_b, 7
    jsr i16_divmod
    jsr i16_to_dec
    jsr screen_puts
    +say lbl_rem
    lda i16_r
    sta i16_a
    lda i16_r+1
    sta i16_a+1
    jsr i16_to_dec
    jsr screen_puts
    +nl

    +say lbl_sdiv               ; -7 / 2 = -3 remainder -1 (toward zero)
    +i16_const i16_a, -7
    +i16_const i16_b, 2
    jsr i16_divmod_s
    jsr i16_to_dec_s
    jsr screen_puts
    +say lbl_rem
    lda i16_r
    sta i16_a
    lda i16_r+1
    sta i16_a+1
    jsr i16_to_dec_s
    jsr screen_puts
    +nl

    +say lbl_mul16              ; 300 * 300 = 90000 -> low 16 bits = 24464
    +i16_const i16_a, 300
    +i16_const i16_b, 300
    jsr i16_mul
    jsr i16_to_dec
    jsr screen_puts
    +say lbl_wraps
    +nl

    +say lbl_sqrt16            ; floor(sqrt(65535)) = 255, no float
    +i16_const i16_a, 65535
    jsr i16_sqrt
    sta i16_a
    stz i16_a+1
    jsr i16_to_dec
    jsr screen_puts
    +nl

    +say lbl_same              ; $FFFF: -1 signed, 65535 unsigned
    +i16_const i16_a, $FFFF
    jsr i16_to_dec
    jsr screen_puts
    +say lbl_or
    +i16_const i16_a, $FFFF
    jsr i16_to_dec_s
    jsr screen_puts
    +nl

    +say lbl_cmp
    +i16_const i16_a, $FFFF
    +i16_const i16_b, 1
    jsr i16_cmpu
    jsr show_ordering
    +say lbl_cmp_s
    +i16_const i16_a, $FFFF
    +i16_const i16_b, 1
    jsr i16_cmps
    jsr show_ordering
    +nl
    +nl
    rts

; A = $FF, 0 or 1 from a cmp routine.  Print "<", "=" or ">".
show_ordering
    cmp #0
    beq @equal
    bmi @less
    lda #'>'
    bra @out
@less
    lda #'<'
    bra @out
@equal
    lda #'='
@out
    jmp screen_chrout

; =====================================================================
; 32-bit integers -- util/int32.asm
; =====================================================================
show_int32
    +say hdr_i32

    +say lbl_udiv32            ; 1000000 / 7 = 142857 remainder 1
    +i32_const i32_a, 1000000
    +i32_const i32_b, 7
    jsr i32_divmod
    jsr i32_to_dec
    jsr screen_puts
    +say lbl_rem
    lda i32_r
    sta i32_a
    lda i32_r+1
    sta i32_a+1
    lda i32_r+2
    sta i32_a+2
    lda i32_r+3
    sta i32_a+3
    jsr i32_to_dec
    jsr screen_puts
    +nl

    +say lbl_mul32            ; 100000 * 37 = 3700000
    +i32_const i32_a, 100000
    +i32_const i32_b, 37
    jsr i32_mul
    jsr i32_to_dec
    jsr screen_puts
    +nl

    +say lbl_max32           ; the whole unsigned range
    +i32_const i32_a, 4294967295
    jsr i32_to_dec
    jsr screen_puts
    +nl

    +say lbl_abs32           ; |-5| = 5 across four bytes
    +i32_const i32_a, -5
    jsr i32_abs
    jsr i32_to_dec
    jsr screen_puts
    +nl
    +nl
    rts

; =====================================================================
; 8.8 fixed point -- util/fixed.asm
; =====================================================================
show_fixed
    +say hdr_fix

    +say lbl_mul88           ; 1.5 * 2.0 = 3.0, as 384 * 512 >> 8 = 768
    +xm_mul88 384, 512
    lda X16_P0
    sta i16_a
    lda X16_P1
    sta i16_a+1
    jsr i16_to_dec_s
    jsr screen_puts
    +say lbl_is_three
    +nl

    +say lbl_mul88n          ; -1.5 * 2.0 = -3.0
    +xm_mul88 -384, 512
    lda X16_P0
    sta i16_a
    lda X16_P1
    sta i16_a+1
    jsr i16_to_dec_s
    jsr screen_puts
    +nl
    +nl
    rts

; =====================================================================
; Floating point -- util/float.asm
; =====================================================================
show_float
    +say hdr_flt

    +say lbl_fdiv             ; 10 / 4 = 2.5
    +fset ftmp, 4
    +fset ftmp2, 10
    +fget ftmp2
    +xm_f_div ftmp
    +fshow

    +say lbl_fsub             ; 10 - 3 = 7
    +fset ftmp, 3
    +fset ftmp2, 10
    +fget ftmp2
    +xm_f_sub ftmp
    +fshow

    +say lbl_frdiv            ; the reciprocal form: 4 / 100 = .04
    +fset ftmp, 4
    +fset ftmp2, 100
    +fget ftmp2
    +xm_f_rdiv ftmp
    +fshow

    +say lbl_fsqrt            ; sqrt(2)  (no argument: direct)
    +fset ftmp, 2
    +fget ftmp
    jsr f_sqrt
    +fshow

    +say lbl_fpow             ; 2 ^ 10 = 1024
    +fset ftmp, 10
    +fset ftmp2, 2
    +fget ftmp2
    +xm_f_pow ftmp
    +fshow

    +say lbl_fsin             ; sin(1)  (direct)
    +fset ftmp, 1
    +fget ftmp
    jsr f_sin
    +fshow

    +say lbl_fexp             ; e^1  (direct)
    +fset ftmp, 1
    +fget ftmp
    jsr f_exp
    +fshow

    +say lbl_fln              ; ln(10)  (direct)
    +fset ftmp, 10
    +fget ftmp
    jsr f_ln
    +fshow

    +say lbl_fparse           ; VAL("3.14159") * 2
    +fset ftmp, 2
    +xm_f_from_str str_pi, 7
    +xm_f_mul ftmp
    +fshow

    +say lbl_fint             ; int(-2.5) = -3  (floor; f_int direct)
    +xm_f_from_str str_neg, 4
    jsr f_int
    +fshow

    +say lbl_fcmp             ; 1.5 vs 2.5
    +fset ftmp, 3
    +fset ftmp2, 2
    +fget ftmp
    +xm_f_div ftmp2           ; FAC = 1.5
    +xm_f_store ftmp3
    +fset ftmp, 5
    +fget ftmp
    +xm_f_div ftmp2           ; FAC = 2.5
    +xm_f_cmp ftmp3           ; compare 2.5 with 1.5
    jsr show_ordering
    +nl
    rts

; =====================================================================
ftmp   !fill FP_SIZE, 0
ftmp2  !fill FP_SIZE, 0
ftmp3  !fill FP_SIZE, 0

str_pi  !text "3.14159"
str_neg !text "-2.5"

hdr_i16 !text "-- 16-BIT INTEGERS --", 13, $00
hdr_i32 !text "-- 32-BIT INTEGERS --", 13, $00
hdr_fix !text "-- 8.8 FIXED POINT --", 13, $00
hdr_flt !text "-- FLOATING POINT --", 13, $00

lbl_udiv    !text "1000 / 7            = ", $00
lbl_rem     !text " REM ", $00
lbl_sdiv    !text "-7 / 2 (SIGNED)     = ", $00
lbl_mul16   !text "300 * 300           = ", $00
lbl_wraps   !text "  (WRAPS: 90000 MOD 65536)", $00
lbl_sqrt16  !text "SQRT(65535)         = ", $00
lbl_same    !text "$FFFF UNSIGNED      = ", $00
lbl_or      !text "   SIGNED = ", $00
lbl_cmp     !text "CMP $FFFF,1 UNSIGNED: ", $00
lbl_cmp_s   !text "   SIGNED: ", $00

lbl_udiv32  !text "1000000 / 7         = ", $00
lbl_mul32   !text "100000 * 37         = ", $00
lbl_max32   !text "LARGEST UNSIGNED    = ", $00
lbl_abs32   !text "ABS(-5)             = ", $00

lbl_mul88   !text "384 * 512 >> 8      = ", $00
lbl_is_three !text "  (1.5 * 2.0 = 3.0)", $00
lbl_mul88n  !text "-384 * 512 >> 8     = ", $00

lbl_fdiv    !text "10 / 4              = ", $00
lbl_fsub    !text "10 - 3              = ", $00
lbl_frdiv   !text "F_RDIV: 4 / 100     = ", $00
lbl_fsqrt   !text "SQRT(2)             = ", $00
lbl_fpow    !text "2 ^ 10              = ", $00
lbl_fsin    !text "SIN(1)              = ", $00
lbl_fexp    !text "EXP(1)              = ", $00
lbl_fln     !text "LN(10)              = ", $00
lbl_fparse  !text "VAL(\"3.14159\") * 2  = ", $00
lbl_fint    !text "INT(-2.5)  (FLOOR)  = ", $00
lbl_fcmp    !text "CMP 2.5 WITH 1.5    : ", $00

msg_done !text "DONE.", 13, $00

; ---------------------------------------------------------------------
!source "x16_code.asm"
