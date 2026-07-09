;ACME
; =====================================================================
; x16lib example :: numbers.asm
; =====================================================================
; A tour of the number libraries: 16-bit integers, 32-bit integers,
; 8.8 fixed point, and floating point. Every line prints an expression
; and its result, so the output is also a check on the maths.
;
;   run.bat numbers
;
; No VSYNC, no sprites -- this one runs happily headless too:
;   emulator\x16emu.exe -prg build\numbers.prg -run -warp -echo -testbench
; =====================================================================

!cpu 65c02
!source "x16.asm"

X16_USE_SCREEN = 1
X16_USE_INT16  = 1
X16_USE_INT32  = 1
X16_USE_FIXED  = 1
X16_USE_FLOAT  = 1

; ---------------------------------------------------------------------
; +say addr   print a NUL-terminated string
; +nl         newline
; ---------------------------------------------------------------------
!macro say .addr {
    lda #<(.addr)
    ldx #>(.addr)
    jsr screen_puts
}

!macro nl {
    lda #13
    jsr screen_chrout
}

; Build a float from a signed 16-bit literal and store it at .addr.
!macro fset .addr, .value {
    lda #<(.value)
    ldx #>(.value)
    jsr f_from_s16
    lda #<(.addr)
    ldy #>(.addr)
    jsr f_store
}

; Load the float at .addr into FAC.
!macro fget .addr {
    lda #<(.addr)
    ldy #>(.addr)
    jsr f_load
}

; Print FAC, then a newline.
!macro fshow {
    jsr f_to_str_trim
    jsr screen_puts
    +nl
}

* = $0801
    +basic_stub

; =====================================================================
main
    jsr screen_cls

    jsr show_int16
    jsr show_int32
    jsr show_fixed
    jsr show_float

    +nl
    +say msg_done
    rts

; =====================================================================
; 16-bit integers -- util/int16.asm
; =====================================================================
show_int16
    +say hdr_i16

    ; 1000 / 7 = 142 remainder 6
    +say lbl_udiv
    +i16_const i16_a, 1000
    +i16_const i16_b, 7
    jsr i16_divmod
    jsr i16_to_dec
    jsr screen_puts
    +say lbl_rem
    lda i16_r                   ; move the remainder into i16_a to print it
    sta i16_a
    lda i16_r+1
    sta i16_a+1
    jsr i16_to_dec
    jsr screen_puts
    +nl

    ; -7 / 2 = -3 remainder -1. Truncates toward zero; the remainder
    ; takes the sign of the dividend.
    +say lbl_sdiv
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

    ; 300 * 300 = 90000, which does not fit: the low 16 bits are 24464.
    +say lbl_mul16
    +i16_const i16_a, 300
    +i16_const i16_b, 300
    jsr i16_mul
    jsr i16_to_dec
    jsr screen_puts
    +say lbl_wraps
    +nl

    ; floor(sqrt(65535)) = 255, exactly, with no floating point.
    +say lbl_sqrt16
    +i16_const i16_a, 65535
    jsr i16_sqrt
    sta i16_a
    stz i16_a+1
    jsr i16_to_dec
    jsr screen_puts
    +nl

    ; $FFFF is -1 signed but 65535 unsigned. Same bits, both printed.
    +say lbl_same
    +i16_const i16_a, $FFFF
    jsr i16_to_dec
    jsr screen_puts
    +say lbl_or
    +i16_const i16_a, $FFFF
    jsr i16_to_dec_s
    jsr screen_puts
    +nl

    ; ...and the two comparisons disagree about it.
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

    ; 1000000 / 7 = 142857 remainder 1
    +say lbl_udiv32
    +i32_const i32_a, 1000000
    +i32_const i32_b, 7
    jsr i32_divmod
    jsr i32_to_dec
    jsr screen_puts
    +say lbl_rem
    ; i32_to_dec consumed i32_a, so rebuild it from the remainder.
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

    ; 100000 * 37 = 3700000: too wide for 16 bits on either side.
    +say lbl_mul32
    +i32_const i32_a, 100000
    +i32_const i32_b, 37
    jsr i32_mul
    jsr i32_to_dec
    jsr screen_puts
    +nl

    ; The whole unsigned range.
    +say lbl_max32
    +i32_const i32_a, 4294967295
    jsr i32_to_dec
    jsr screen_puts
    +nl

    ; |-5| = 5, in two's complement across four bytes.
    +say lbl_abs32
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

    ; 1.5 * 2.0 = 3.0, held as 384 * 512 >> 8 = 768.
    +say lbl_mul88
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
    sta i16_a
    lda X16_P1
    sta i16_a+1
    jsr i16_to_dec_s
    jsr screen_puts
    +say lbl_is_three
    +nl

    ; -1.5 * 2.0 = -3.0. The sign survives the shift.
    +say lbl_mul88n
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
    sta i16_a
    lda X16_P1
    sta i16_a+1
    jsr i16_to_dec_s
    jsr screen_puts
    +nl
    +nl
    rts

; =====================================================================
; Floating point -- util/float.asm, bound to the ROM's FP library
; =====================================================================
show_float
    +say hdr_flt

    +say lbl_fdiv               ; 10 / 4 = 2.5
    +fset ftmp, 4
    +fset ftmp2, 10
    +fget ftmp2
    lda #<ftmp
    ldy #>ftmp
    jsr f_div
    +fshow

    +say lbl_fsub               ; 10 - 3 = 7, not -7
    +fset ftmp, 3
    +fset ftmp2, 10
    +fget ftmp2
    lda #<ftmp
    ldy #>ftmp
    jsr f_sub
    +fshow

    +say lbl_frdiv              ; the reciprocal form: 4 / 100 = .04
    +fset ftmp, 4
    +fset ftmp2, 100
    +fget ftmp2
    lda #<ftmp
    ldy #>ftmp
    jsr f_rdiv
    +fshow

    +say lbl_fsqrt              ; sqrt(2)
    +fset ftmp, 2
    +fget ftmp
    jsr f_sqrt
    +fshow

    +say lbl_fpow               ; 2 ^ 10 = 1024
    +fset ftmp, 10
    +fset ftmp2, 2
    +fget ftmp2
    lda #<ftmp
    ldy #>ftmp
    jsr f_pow
    +fshow

    +say lbl_fsin               ; sin(1) in radians
    +fset ftmp, 1
    +fget ftmp
    jsr f_sin
    +fshow

    +say lbl_fexp               ; e^1
    +fset ftmp, 1
    +fget ftmp
    jsr f_exp
    +fshow

    +say lbl_fln                ; ln(10)
    +fset ftmp, 10
    +fget ftmp
    jsr f_ln
    +fshow

    ; Parse "3.14159" and double it.
    ;
    ; Set the constant BEFORE parsing: +fset goes through f_from_s16,
    ; which loads FAC -- so doing it afterwards would throw the parsed
    ; value away and quietly square the constant instead.
    +say lbl_fparse
    +fset ftmp, 2
    lda #<str_pi
    ldy #>str_pi
    ldx #7
    jsr f_from_str
    lda #<ftmp
    ldy #>ftmp
    jsr f_mul
    +fshow                      ; 6.28318001: the last digits are the
                                ; float's own rounding, not an error

    +say lbl_fint               ; int(-2.5) floors, so -3 rather than -2
    lda #<str_neg
    ldy #>str_neg
    ldx #4
    jsr f_from_str
    jsr f_int
    +fshow

    +say lbl_fcmp               ; 1.5 vs 2.5
    +fset ftmp, 3
    +fset ftmp2, 2
    +fget ftmp
    lda #<ftmp2
    ldy #>ftmp2
    jsr f_div                   ; FAC = 1.5
    lda #<ftmp3
    ldy #>ftmp3
    jsr f_store
    +fset ftmp, 5
    +fget ftmp
    lda #<ftmp2
    ldy #>ftmp2
    jsr f_div                   ; FAC = 2.5
    lda #<ftmp3
    ldy #>ftmp3
    jsr f_cmp                   ; compare 2.5 with 1.5
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
