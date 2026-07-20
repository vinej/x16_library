;ACME
; =====================================================================
; x16lib :: test/dtest.asm -- util/double.asm, Stage 1
; =====================================================================
;   .\build_acme.ps1 -Test -Source test_acme\dtest.asm
; =====================================================================

    processor 65c02
    include "x16.asm"

X16_USE_DOUBLE = 1

CHK_ZP = $72                     ; the test's own pointers (clear of T_ZP)
CHK2   = $74

    org $0801
    basic_stub

    SUBROUTINE
main
    jsr t_init

    jsr test_from1
    jsr test_from0
    jsr test_fromm2
    jsr test_from2p24
    jsr test_rt_pos
    jsr test_rt_neg
    jsr test_cmp
    jsr test_negabs
    jsr test_add
    jsr test_addexp
    jsr test_sub
    jsr test_cancel
    jsr test_addbig
    jsr test_mul
    jsr test_mulint
    jsr test_mulneg
    jsr test_div
    jsr test_divfrac
    jsr test_divhalf
    jsr test_str_int
    jsr test_str_neg
    jsr test_str_big
    jsr test_str_frac
    jsr test_str_half
    jsr test_str_exp
    jsr test_ts_int
    jsr test_ts_neg
    jsr test_ts_frac
    jsr test_ts_half
    jsr test_ts_big
    jsr test_ts_exp
    jsr test_sqrt4
    jsr test_sqrt9
    jsr test_sqrt144
    jsr test_sqrt1m
    jsr test_sqrtneg
    jsr test_exp0
    jsr test_exp1
    jsr test_ln1
    jsr test_ln2
    jsr test_lnexp
    jsr test_pow0
    jsr test_powhalf
    jsr test_powint
    jsr test_sin0
    jsr test_cos0
    jsr test_sinhalfpi
    jsr test_sin1
    jsr test_tan0
    jsr test_atan0
    jsr test_atan1
    jsr test_atansqrt3
    jsr test_sinh0
    jsr test_cosh0
    jsr test_sinh1
    jsr test_cosh1
    jsr test_tanh1
    jsr test_tanhbig

    jsr t_summary
    rts

; --- 1.0 from d_from_s16 --------------------------------------------
    SUBROUTINE
test_from1
    lda #1
    ldx #0
    jsr d_from_s16
    lda #<c_1
    ldx #>c_1
    jsr chk_ac
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DFROM_1", 0

; --- 0 -> all zero ---------------------------------------------------
    SUBROUTINE
test_from0
    lda #0
    ldx #0
    jsr d_from_s16
    lda #<c_0
    ldx #>c_0
    jsr chk_ac
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DFROM_0", 0

; --- -2.0 ------------------------------------------------------------
    SUBROUTINE
test_fromm2
    lda #<-2
    ldx #>-2
    jsr d_from_s16
    lda #<c_m2
    ldx #>c_m2
    jsr chk_ac
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DFROM_M2", 0

; --- 2^24 from d_from_s32 -------------------------------------------
    SUBROUTINE
test_from2p24
    lda #<16777216
    sta X16_P0
    lda #>16777216
    sta X16_P1
    lda #<(16777216 >> 16)
    sta X16_P2
    lda #<(16777216 >> 24)
    sta X16_P3
    jsr d_from_s32
    lda #<c_2p24
    ldx #>c_2p24
    jsr chk_ac
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DFROM_2P24", 0

; --- round trip a positive int through s32 --------------------------
    SUBROUTINE
test_rt_pos
    lda #<123456789
    sta X16_P0
    lda #>123456789
    sta X16_P1
    lda #<(123456789 >> 16)
    sta X16_P2
    lda #<(123456789 >> 24)
    sta X16_P3
    jsr d_from_s32
    jsr d_to_s32
    lda #<e_123
    ldx #>e_123
    jsr chk_p32
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DRT_POS", 0

; --- round trip a large negative int --------------------------------
    SUBROUTINE
test_rt_neg
    lda #$00
    sta X16_P0        ; -2000000000 = $88CA6C00, loaded as bytes
    lda #$6C
    sta X16_P1        ; (a 32-bit negative literal narrowed with
    lda #$CA
    sta X16_P2        ;  #< does not port cleanly to 64tass)
    lda #$88
    sta X16_P3
    jsr d_from_s32
    jsr d_to_s32
    lda #<e_neg2e9
    ldx #>e_neg2e9
    jsr chk_p32
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DRT_NEG", 0

; --- d_cmp: 3<4, 5==5, 5>2 ------------------------------------------
    SUBROUTINE
test_cmp
    ldy #1                       ; fail-default
    lda #<c_3
    ldy #>c_3
    jsr d_load
    lda #<c_4
    ldy #>c_4
    jsr d_cmp
    cmp #$FF
    bne .report
    lda #<c_5
    ldy #>c_5
    jsr d_load
    lda #<c_5
    ldy #>c_5
    jsr d_cmp
    bne .report                  ; must be 0 (equal)
    lda #<c_5
    ldy #>c_5
    jsr d_load
    lda #<c_2
    ldy #>c_2
    jsr d_cmp
    cmp #1
    bne .report
    ldy #0
.report
    tya
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DCMP", 0

; --- d_neg / d_abs ---------------------------------------------------
    SUBROUTINE
test_negabs
    ldy #1
    lda #3
    ldx #0
    jsr d_from_s16               ; 3.0
    jsr d_neg                    ; -3.0
    lda #<c_m3
    ldx #>c_m3
    jsr chk_ac
    bne .report
    jsr d_abs                    ; 3.0
    lda #<c_3
    ldx #>c_3
    jsr chk_ac
    bne .report
    ldy #0
.report
    tya
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DNEGABS", 0

; --- 1 + 2 = 3 ------------------------------------------------------
    SUBROUTINE
test_add
    lda #1
    ldx #0
    jsr d_from_s16
    lda #<c_2
    ldy #>c_2
    jsr d_add
    lda #<c_3
    ldx #>c_3
    jsr chk_ac
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DADD", 0

; --- 1 + 0.5 = 1.5 (unequal exponents) ------------------------------
    SUBROUTINE
test_addexp
    lda #<c_1
    ldy #>c_1
    jsr d_load
    lda #<c_half
    ldy #>c_half
    jsr d_add
    lda #<c_1p5
    ldx #>c_1p5
    jsr chk_ac
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DADD_EXP", 0

; --- 3 - 4 = -1 -----------------------------------------------------
    SUBROUTINE
test_sub
    lda #3
    ldx #0
    jsr d_from_s16
    lda #<c_4
    ldy #>c_4
    jsr d_sub
    lda #<c_m1
    ldx #>c_m1
    jsr chk_ac
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DSUB", 0

; --- 5 - 5 = +0 (exact cancellation) --------------------------------
    SUBROUTINE
test_cancel
    lda #5
    ldx #0
    jsr d_from_s16
    lda #<c_5
    ldy #>c_5
    jsr d_sub
    lda #<c_0
    ldx #>c_0
    jsr chk_ac
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DCANCEL", 0

; --- 2^24 + 1 = 16777217 (small addend survives) --------------------
    SUBROUTINE
test_addbig
    lda #<16777216
    sta X16_P0
    lda #>16777216
    sta X16_P1
    lda #<(16777216 >> 16)
    sta X16_P2
    lda #<(16777216 >> 24)
    sta X16_P3
    jsr d_from_s32
    lda #<c_1
    ldy #>c_1
    jsr d_add
    jsr d_to_s32
    lda #<e_2p24p1
    ldx #>e_2p24p1
    jsr chk_p32
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DADD_BIG", 0

; --- 2 * 3 = 6 -----------------------------------------------------
    SUBROUTINE
test_mul
    lda #2
    ldx #0
    jsr d_from_s16
    lda #<c_3
    ldy #>c_3
    jsr d_mul
    lda #<c_6
    ldx #>c_6
    jsr chk_ac
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DMUL", 0

; --- 7 * 8 = 56 (via s32) -------------------------------------------
    SUBROUTINE
test_mulint
    lda #7
    ldx #0
    jsr d_from_s16
    lda #<c_8
    ldy #>c_8
    jsr d_mul
    jsr d_to_s32
    lda #<e_56
    ldx #>e_56
    jsr chk_p32
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DMUL_INT", 0

; --- -3 * 4 = -12 ---------------------------------------------------
    SUBROUTINE
test_mulneg
    lda #<-3
    ldx #>-3
    jsr d_from_s16
    lda #<c_4
    ldy #>c_4
    jsr d_mul
    jsr d_to_s32
    lda #<e_m12
    ldx #>e_m12
    jsr chk_p32
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DMUL_NEG", 0

; --- 6 / 2 = 3 ------------------------------------------------------
    SUBROUTINE
test_div
    lda #6
    ldx #0
    jsr d_from_s16
    lda #<c_2
    ldy #>c_2
    jsr d_div
    lda #<c_3
    ldx #>c_3
    jsr chk_ac
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DDIV", 0

; --- 10 / 4 = 2.5 ---------------------------------------------------
    SUBROUTINE
test_divfrac
    lda #10
    ldx #0
    jsr d_from_s16
    lda #<c_4
    ldy #>c_4
    jsr d_div
    lda #<c_2p5
    ldx #>c_2p5
    jsr chk_ac
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DDIV_FRAC", 0

; --- 1 / 2 = 0.5 ----------------------------------------------------
    SUBROUTINE
test_divhalf
    lda #<c_1
    ldy #>c_1
    jsr d_load
    lda #<c_2
    ldy #>c_2
    jsr d_div
    lda #<c_half
    ldx #>c_half
    jsr chk_ac
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DDIV_HALF", 0

; --- parse "3" -> 3 -------------------------------------------------
    SUBROUTINE
test_str_int
    lda #<s_3
    ldy #>s_3
    ldx #1
    jsr d_from_str
    jsr d_to_s32
    lda #<e_3
    ldx #>e_3
    jsr chk_p32
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DSTR_INT", 0

; --- parse "-12" -> -12 ---------------------------------------------
    SUBROUTINE
test_str_neg
    lda #<s_m12
    ldy #>s_m12
    ldx #3
    jsr d_from_str
    jsr d_to_s32
    lda #<e_m12
    ldx #>e_m12
    jsr chk_p32
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DSTR_NEG", 0

; --- parse "1000000" -> 1000000 -------------------------------------
    SUBROUTINE
test_str_big
    lda #<s_1m
    ldy #>s_1m
    ldx #7
    jsr d_from_str
    jsr d_to_s32
    lda #<e_1m
    ldx #>e_1m
    jsr chk_p32
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DSTR_BIG", 0

; --- parse "2.5" == 2.5 ---------------------------------------------
    SUBROUTINE
test_str_frac
    lda #<s_2p5
    ldy #>s_2p5
    ldx #3
    jsr d_from_str
    lda #<c_2p5
    ldy #>c_2p5
    jsr d_cmp                    ; 0 = equal = pass
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DSTR_FRAC", 0

; --- parse "0.5" == 0.5 ---------------------------------------------
    SUBROUTINE
test_str_half
    lda #<s_half
    ldy #>s_half
    ldx #3
    jsr d_from_str
    lda #<c_half
    ldy #>c_half
    jsr d_cmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DSTR_HALF", 0

; --- parse "1.5E1" == 15 --------------------------------------------
    SUBROUTINE
test_str_exp
    lda #<s_15e
    ldy #>s_15e
    ldx #5
    jsr d_from_str
    lda #<c_15
    ldy #>c_15
    jsr d_cmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DSTR_EXP", 0

; --- d_to_str: 3 -> "3" --------------------------------------------
    SUBROUTINE
test_ts_int
    lda #3
    ldx #0
    jsr d_from_s16
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_3
    ldx #>x_3
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DTS_INT", 0

; --- -12 -> "-12" ---------------------------------------------------
    SUBROUTINE
test_ts_neg
    lda #<-12
    ldx #>-12
    jsr d_from_s16
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_m12
    ldx #>x_m12
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DTS_NEG", 0

; --- 2.5 -> "2.5" ---------------------------------------------------
    SUBROUTINE
test_ts_frac
    lda #<c_2p5
    ldy #>c_2p5
    jsr d_load
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_2p5
    ldx #>x_2p5
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DTS_FRAC", 0

; --- 0.5 -> "0.5" ---------------------------------------------------
    SUBROUTINE
test_ts_half
    lda #<c_half
    ldy #>c_half
    jsr d_load
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_half
    ldx #>x_half
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DTS_HALF", 0

; --- 1000000 -> "1000000" -------------------------------------------
    SUBROUTINE
test_ts_big
    lda #<1000000
    sta X16_P0
    lda #>1000000
    sta X16_P1
    lda #<(1000000 >> 16)
    sta X16_P2
    lda #<(1000000 >> 24)
    sta X16_P3
    jsr d_from_s32
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_1m
    ldx #>x_1m
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DTS_BIG", 0

; --- round trip: "1.5E1" parsed then printed -> "15" ----------------
    SUBROUTINE
test_ts_exp
    lda #<s_15e
    ldy #>s_15e
    ldx #5
    jsr d_from_str
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_15
    ldx #>x_15
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DTS_RT", 0

; --- sqrt(4) -> "2" ------------------------------------------------
    SUBROUTINE
test_sqrt4
    lda #4
    ldx #0
    jsr d_from_s16
    jsr d_sqrt
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_2
    ldx #>x_2
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DSQRT4", 0

; --- sqrt(9) -> "3" (perfect square must land exact) ----------------
    SUBROUTINE
test_sqrt9
    lda #9
    ldx #0
    jsr d_from_s16
    jsr d_sqrt
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_3
    ldx #>x_3
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DSQRT9", 0

; --- sqrt(144) -> "12" ----------------------------------------------
    SUBROUTINE
test_sqrt144
    lda #144
    ldx #0
    jsr d_from_s16
    jsr d_sqrt
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_12
    ldx #>x_12
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DSQRT144", 0

; --- sqrt(1000000) -> "1000" ----------------------------------------
    SUBROUTINE
test_sqrt1m
    lda #<1000000
    sta X16_P0
    lda #>1000000
    sta X16_P1
    lda #<(1000000 >> 16)
    sta X16_P2
    lda #<(1000000 >> 24)
    sta X16_P3
    jsr d_from_s32
    jsr d_sqrt
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_1000
    ldx #>x_1000
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DSQRT_1M", 0

; --- sqrt(-4) -> "NAN" ----------------------------------------------
    SUBROUTINE
test_sqrtneg
    lda #<-4
    ldx #>-4
    jsr d_from_s16
    jsr d_sqrt
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_nan
    ldx #>x_nan
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DSQRT_NEG", 0

; --- exp(0) -> "1" -------------------------------------------------
    SUBROUTINE
test_exp0
    lda #0
    ldx #0
    jsr d_from_s16
    jsr d_exp
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_1s
    ldx #>x_1s
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DEXP0", 0

; --- exp(1) = e, first 13 chars "2.71828182845" -------------------
    SUBROUTINE
test_exp1
    lda #1
    ldx #0
    jsr d_from_s16
    jsr d_exp
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #13
    sta strncmp_n
    lda #<x_e
    ldx #>x_e
    jsr strncmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DEXP1", 0

; --- ln(1) -> "0" -------------------------------------------------
    SUBROUTINE
test_ln1
    lda #1
    ldx #0
    jsr d_from_s16
    jsr d_ln
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_0s
    ldx #>x_0s
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DLN1", 0

; --- ln(2), first 14 chars "0.693147180559" -----------------------
    SUBROUTINE
test_ln2
    lda #2
    ldx #0
    jsr d_from_s16
    jsr d_ln
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #14
    sta strncmp_n
    lda #<x_ln2
    ldx #>x_ln2
    jsr strncmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DLN2", 0

; --- ln(exp(1)) round-trips to within 2^-30 of 1 ------------------
    SUBROUTINE
test_lnexp
    lda #1
    ldx #0
    jsr d_from_s16
    jsr d_exp
    jsr d_ln
    lda #<c_1
    ldy #>c_1
    jsr d_sub                    ; result - 1
    jsr d_abs
    lda #<c_eps
    ldy #>c_eps
    jsr d_cmp                    ; |result-1| < eps ?  ($FF = less)
    ldy #1
    cmp #$FF
    bne .report
    ldy #0
.report
    tya
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DLN_EXP", 0

; --- 5^0 = "1" -----------------------------------------------------
    SUBROUTINE
test_pow0
    lda #5
    ldx #0
    jsr d_from_s16
    lda #<c_0
    ldy #>c_0
    jsr d_pow
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_1s
    ldx #>x_1s
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DPOW0", 0

; --- 2^0.5 = sqrt(2), first 12 chars "1.4142135623" ---------------
    SUBROUTINE
test_powhalf
    lda #2
    ldx #0
    jsr d_from_s16
    lda #<c_half
    ldy #>c_half
    jsr d_pow
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #12
    sta strncmp_n
    lda #<x_sqrt2
    ldx #>x_sqrt2
    jsr strncmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DPOW_HALF", 0

; --- 2^10 within 2^-30 of 1024 -------------------------------------
    SUBROUTINE
test_powint
    lda #2
    ldx #0
    jsr d_from_s16
    lda #<c_ten
    ldy #>c_ten
    jsr d_pow
    lda #<c_1024
    ldy #>c_1024
    jsr d_sub
    jsr d_abs
    lda #<c_eps
    ldy #>c_eps
    jsr d_cmp
    ldy #1
    cmp #$FF
    bne .report
    ldy #0
.report
    tya
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DPOW_INT", 0

; --- sin(0) -> "0", cos(0) -> "1", tan(0) -> "0" ------------------
    SUBROUTINE
test_sin0
    lda #0
    ldx #0
    jsr d_from_s16
    jsr d_sin
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_0s
    ldx #>x_0s
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DSIN0", 0

    SUBROUTINE
test_cos0
    lda #0
    ldx #0
    jsr d_from_s16
    jsr d_cos
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_1s
    ldx #>x_1s
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DCOS0", 0

; --- sin(pi/2) -> "1" ----------------------------------------------
    SUBROUTINE
test_sinhalfpi
    lda #<c_pih
    ldy #>c_pih
    jsr d_load
    jsr d_sin
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_1s
    ldx #>x_1s
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DSIN_HPI", 0

; --- sin(1), first 13 chars "0.84147098480" ----------------------
    SUBROUTINE
test_sin1
    lda #1
    ldx #0
    jsr d_from_s16
    jsr d_sin
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #13
    sta strncmp_n
    lda #<x_sin1
    ldx #>x_sin1
    jsr strncmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DSIN1", 0

    SUBROUTINE
test_tan0
    lda #0
    ldx #0
    jsr d_from_s16
    jsr d_tan
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_0s
    ldx #>x_0s
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DTAN0", 0

; --- atan(0) -> "0" -----------------------------------------------
    SUBROUTINE
test_atan0
    lda #0
    ldx #0
    jsr d_from_s16
    jsr d_atan
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_0s
    ldx #>x_0s
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DATAN0", 0

; --- atan(1) within 2^-30 of pi/4 ---------------------------------
    SUBROUTINE
test_atan1
    lda #1
    ldx #0
    jsr d_from_s16
    jsr d_atan
    lda #<c_pi4
    ldy #>c_pi4
    jsr d_sub
    jsr d_abs
    lda #<c_eps
    ldy #>c_eps
    jsr d_cmp
    ldy #1
    cmp #$FF
    bne .report
    ldy #0
.report
    tya
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DATAN1", 0

; --- atan(sqrt3) = pi/3, first 14 chars "1.047197551196" ---------
    SUBROUTINE
test_atansqrt3
    lda #<c_sqrt3
    ldy #>c_sqrt3
    jsr d_load
    jsr d_atan
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #14
    sta strncmp_n
    lda #<x_pi3
    ldx #>x_pi3
    jsr strncmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DATAN_S3", 0

; --- sinh(0) -> "0", cosh(0) -> "1" ------------------------------
    SUBROUTINE
test_sinh0
    lda #0
    ldx #0
    jsr d_from_s16
    jsr d_sinh
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_0s
    ldx #>x_0s
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DSINH0", 0

    SUBROUTINE
test_cosh0
    lda #0
    ldx #0
    jsr d_from_s16
    jsr d_cosh
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_1s
    ldx #>x_1s
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DCOSH0", 0

; --- sinh(1), first 12 chars "1.1752011936" ----------------------
    SUBROUTINE
test_sinh1
    lda #1
    ldx #0
    jsr d_from_s16
    jsr d_sinh
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #12
    sta strncmp_n
    lda #<x_sinh1
    ldx #>x_sinh1
    jsr strncmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DSINH1", 0

; --- cosh(1), first 12 chars "1.5430806348" ----------------------
    SUBROUTINE
test_cosh1
    lda #1
    ldx #0
    jsr d_from_s16
    jsr d_cosh
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #12
    sta strncmp_n
    lda #<x_cosh1
    ldx #>x_cosh1
    jsr strncmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DCOSH1", 0

; --- tanh(1), first 12 chars "0.7615941559" ----------------------
    SUBROUTINE
test_tanh1
    lda #1
    ldx #0
    jsr d_from_s16
    jsr d_tanh
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #12
    sta strncmp_n
    lda #<x_tanh1
    ldx #>x_tanh1
    jsr strncmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DTANH1", 0

; --- tanh(30) saturates to "1" ------------------------------------
    SUBROUTINE
test_tanhbig
    lda #<c_30
    ldy #>c_30
    jsr d_load
    jsr d_tanh
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_1s
    ldx #>x_1s
    jsr strcmp
    ldx #<.n
    ldy #>.n
    jmp t_result
.n dc.b "DTANH_BIG", 0

; NUL-terminated string compare of the first strncmp_n bytes.
    SUBROUTINE
strncmp
    sta CHK2
    stx CHK2+1
    ldy #0
.l
    cpy strncmp_n
    beq .ok
    lda (CHK_ZP),y
    cmp (CHK2),y
    bne .bad
    iny
    bne .l
.ok
    lda #0
    rts
.bad
    lda #1
    rts

; NUL-terminated string compare: expected in A/X, actual at CHK_ZP.
; A = 0 if equal.
    SUBROUTINE
strcmp
    sta CHK2
    stx CHK2+1
    ldy #0
.l
    lda (CHK_ZP),y
    cmp (CHK2),y
    bne .bad
    lda (CHK_ZP),y
    beq .ok
    iny
    bne .l
.ok
    lda #0
    rts
.bad
    lda #1
    rts

; --- helpers ---------------------------------------------------------
; A=lo, X=hi of 8 expected bytes; A=0 if d_ac matches
    SUBROUTINE
chk_ac
    sta CHK_ZP
    stx CHK_ZP+1
    ldy #7
.l
    lda d_ac,y
    cmp (CHK_ZP),y
    bne .bad
    dey
    bpl .l
    lda #0
    rts
.bad
    lda #1
    rts

; A=lo, X=hi of 4 expected bytes; A=0 if X16_P0..P3 matches
    SUBROUTINE
chk_p32
    sta CHK_ZP
    stx CHK_ZP+1
    ldy #3
.l
    lda X16_P0,y
    cmp (CHK_ZP),y
    bne .bad
    dey
    bpl .l
    lda #0
    rts
.bad
    lda #1
    rts

; --- constants -------------------------------------------------------
    SUBROUTINE
c_0    dc.b $00,$00,$00,$00,$00,$00,$00,$00   ; 0.0
    SUBROUTINE
c_1    dc.b $00,$00,$00,$00,$00,$00,$F0,$3F   ; 1.0
    SUBROUTINE
c_2    dc.b $00,$00,$00,$00,$00,$00,$00,$40   ; 2.0
    SUBROUTINE
c_3    dc.b $00,$00,$00,$00,$00,$00,$08,$40   ; 3.0
    SUBROUTINE
c_4    dc.b $00,$00,$00,$00,$00,$00,$10,$40   ; 4.0
    SUBROUTINE
c_5    dc.b $00,$00,$00,$00,$00,$00,$14,$40   ; 5.0
    SUBROUTINE
c_m2   dc.b $00,$00,$00,$00,$00,$00,$00,$C0   ; -2.0
    SUBROUTINE
c_m3   dc.b $00,$00,$00,$00,$00,$00,$08,$C0   ; -3.0
    SUBROUTINE
c_2p24 dc.b $00,$00,$00,$00,$00,$00,$70,$41   ; 16777216.0
    SUBROUTINE
c_half dc.b $00,$00,$00,$00,$00,$00,$E0,$3F   ; 0.5
    SUBROUTINE
c_1p5  dc.b $00,$00,$00,$00,$00,$00,$F8,$3F   ; 1.5
    SUBROUTINE
c_m1   dc.b $00,$00,$00,$00,$00,$00,$F0,$BF   ; -1.0
    SUBROUTINE
c_6    dc.b $00,$00,$00,$00,$00,$00,$18,$40   ; 6.0
    SUBROUTINE
c_8    dc.b $00,$00,$00,$00,$00,$00,$20,$40   ; 8.0
    SUBROUTINE
c_2p5  dc.b $00,$00,$00,$00,$00,$00,$04,$40   ; 2.5
    SUBROUTINE
c_15   dc.b $00,$00,$00,$00,$00,$00,$2E,$40   ; 15.0

    SUBROUTINE
e_123     dc.b $15,$CD,$5B,$07               ; 123456789
    SUBROUTINE
e_neg2e9  dc.b $00,$6C,$CA,$88               ; -2000000000
    SUBROUTINE
e_2p24p1  dc.b $01,$00,$00,$01               ; 16777217
    SUBROUTINE
e_56      dc.b $38,$00,$00,$00               ; 56
    SUBROUTINE
e_m12     dc.b $F4,$FF,$FF,$FF               ; -12
    SUBROUTINE
e_3       dc.b $03,$00,$00,$00               ; 3
    SUBROUTINE
e_1m      dc.b $40,$42,$0F,$00               ; 1000000

    SUBROUTINE
s_3    dc.b "3"
    SUBROUTINE
s_m12  dc.b "-12"
    SUBROUTINE
s_1m   dc.b "1000000"
    SUBROUTINE
s_2p5  dc.b "2.5"
    SUBROUTINE
s_half dc.b "0.5"
    SUBROUTINE
s_15e  dc.b "1.5E1"

    SUBROUTINE
x_3    dc.b "3", 0
    SUBROUTINE
x_m12  dc.b "-12", 0
    SUBROUTINE
x_2p5  dc.b "2.5", 0
    SUBROUTINE
x_half dc.b "0.5", 0
    SUBROUTINE
x_1m   dc.b "1000000", 0
    SUBROUTINE
x_15   dc.b "15", 0
    SUBROUTINE
x_2    dc.b "2", 0
    SUBROUTINE
x_4    dc.b "4", 0
    SUBROUTINE
x_12   dc.b "12", 0
    SUBROUTINE
x_1000 dc.b "1000", 0
    SUBROUTINE
x_nan  dc.b "NAN", 0
    SUBROUTINE
x_1s   dc.b "1", 0
    SUBROUTINE
x_0s   dc.b "0", 0
    SUBROUTINE
x_e    dc.b "2.71828182845"
    SUBROUTINE
x_ln2  dc.b "0.693147180559"
    SUBROUTINE
x_sqrt2 dc.b "1.4142135623"
    SUBROUTINE
x_sin1 dc.b "0.84147098480"
    SUBROUTINE
x_pi3  dc.b "1.047197551196"
    SUBROUTINE
x_sinh1 dc.b "1.1752011936"
    SUBROUTINE
x_cosh1 dc.b "1.5430806348"
    SUBROUTINE
x_tanh1 dc.b "0.7615941559"
    SUBROUTINE
c_30   dc.b $00,$00,$00,$00,$00,$00,$3E,$40   ; 30.0
    SUBROUTINE
c_pi4  dc.b $18,$2D,$44,$54,$FB,$21,$E9,$3F   ; pi/4
    SUBROUTINE
c_sqrt3 dc.b $AA,$4C,$58,$E8,$7A,$B6,$FB,$3F   ; sqrt(3)
    SUBROUTINE
c_pih  dc.b $18,$2D,$44,$54,$FB,$21,$F9,$3F   ; pi/2
    SUBROUTINE
c_ten  dc.b $00,$00,$00,$00,$00,$00,$24,$40   ; 10.0
    SUBROUTINE
c_1024 dc.b $00,$00,$00,$00,$00,$00,$90,$40   ; 1024.0
    SUBROUTINE
c_eps  dc.b $00,$00,$00,$00,$00,$00,$10,$3E   ; 2^-30 ~ 9.3e-10

    SUBROUTINE
strncmp_n dc.b 0

    include "test_dasm/testlib.asm"
    include "x16_code.asm"
