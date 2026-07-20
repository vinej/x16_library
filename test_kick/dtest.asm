//ACME
// =====================================================================
// x16lib :: test/dtest.asm -- util/double.asm, Stage 1
// =====================================================================
//   .\build_acme.ps1 -Test -Source test_acme\dtest.asm
// =====================================================================

#import "x16.asm"

#define X16_USE_DOUBLE

.label CHK_ZP = $72                     // the test's own pointers (clear of T_ZP)
.label CHK2 = $74

.pc = $0801 "code"
    basic_stub()

main:
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

// --- 1.0 from d_from_s16 --------------------------------------------
test_from1:
    lda #1
    ldx #0
    jsr d_from_s16
    lda #<c_1
    ldx #>c_1
    jsr chk_ac
    ldx #<test_from1__n
    ldy #>test_from1__n
    jmp t_result
test_from1__n: .text "DFROM_1"
    .byte 0

// --- 0 -> all zero ---------------------------------------------------
test_from0:
    lda #0
    ldx #0
    jsr d_from_s16
    lda #<c_0
    ldx #>c_0
    jsr chk_ac
    ldx #<test_from0__n
    ldy #>test_from0__n
    jmp t_result
test_from0__n: .text "DFROM_0"
    .byte 0

// --- -2.0 ------------------------------------------------------------
test_fromm2:
    lda #<-2
    ldx #>-2
    jsr d_from_s16
    lda #<c_m2
    ldx #>c_m2
    jsr chk_ac
    ldx #<test_fromm2__n
    ldy #>test_fromm2__n
    jmp t_result
test_fromm2__n: .text "DFROM_M2"
    .byte 0

// --- 2((24) >> 16) from d_from_s32 -------------------------------------------
test_from2p24:
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
    ldx #<test_from2p24__n
    ldy #>test_from2p24__n
    jmp t_result
test_from2p24__n: .text "DFROM_2P24"
    .byte 0

// --- round trip a positive int through s32 --------------------------
test_rt_pos:
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
    ldx #<test_rt_pos__n
    ldy #>test_rt_pos__n
    jmp t_result
test_rt_pos__n: .text "DRT_POS"
    .byte 0

// --- round trip a large negative int --------------------------------
test_rt_neg:
    lda #$00
    sta X16_P0        // -2000000000 = $88CA6C00, loaded as bytes
    lda #$6C
    sta X16_P1        // (a 32-bit negative literal narrowed with
    lda #$CA
    sta X16_P2        //  #< does not port cleanly to 64tass)
    lda #$88
    sta X16_P3
    jsr d_from_s32
    jsr d_to_s32
    lda #<e_neg2e9
    ldx #>e_neg2e9
    jsr chk_p32
    ldx #<test_rt_neg__n
    ldy #>test_rt_neg__n
    jmp t_result
test_rt_neg__n: .text "DRT_NEG"
    .byte 0

// --- d_cmp: 3<4, 5==5, 5>2 ------------------------------------------
test_cmp:
    ldy #1                       // fail-default
    lda #<c_3
    ldy #>c_3
    jsr d_load
    lda #<c_4
    ldy #>c_4
    jsr d_cmp
    cmp #$FF
    bne test_cmp__report
    lda #<c_5
    ldy #>c_5
    jsr d_load
    lda #<c_5
    ldy #>c_5
    jsr d_cmp
    bne test_cmp__report                  // must be 0 (equal)
    lda #<c_5
    ldy #>c_5
    jsr d_load
    lda #<c_2
    ldy #>c_2
    jsr d_cmp
    cmp #1
    bne test_cmp__report
    ldy #0
test_cmp__report:
    tya
    ldx #<test_cmp__n
    ldy #>test_cmp__n
    jmp t_result
test_cmp__n: .text "DCMP"
    .byte 0

// --- d_neg / d_abs ---------------------------------------------------
test_negabs:
    ldy #1
    lda #3
    ldx #0
    jsr d_from_s16               // 3.0
    jsr d_neg                    // -3.0
    lda #<c_m3
    ldx #>c_m3
    jsr chk_ac
    bne test_negabs__report
    jsr d_abs                    // 3.0
    lda #<c_3
    ldx #>c_3
    jsr chk_ac
    bne test_negabs__report
    ldy #0
test_negabs__report:
    tya
    ldx #<test_negabs__n
    ldy #>test_negabs__n
    jmp t_result
test_negabs__n: .text "DNEGABS"
    .byte 0

// --- 1 + 2 = 3 ------------------------------------------------------
test_add:
    lda #1
    ldx #0
    jsr d_from_s16
    lda #<c_2
    ldy #>c_2
    jsr d_add
    lda #<c_3
    ldx #>c_3
    jsr chk_ac
    ldx #<test_add__n
    ldy #>test_add__n
    jmp t_result
test_add__n: .text "DADD"
    .byte 0

// --- 1 + 0.5 = 1.5 (unequal exponents) ------------------------------
test_addexp:
    lda #<c_1
    ldy #>c_1
    jsr d_load
    lda #<c_half
    ldy #>c_half
    jsr d_add
    lda #<c_1p5
    ldx #>c_1p5
    jsr chk_ac
    ldx #<test_addexp__n
    ldy #>test_addexp__n
    jmp t_result
test_addexp__n: .text "DADD_EXP"
    .byte 0

// --- 3 - 4 = -1 -----------------------------------------------------
test_sub:
    lda #3
    ldx #0
    jsr d_from_s16
    lda #<c_4
    ldy #>c_4
    jsr d_sub
    lda #<c_m1
    ldx #>c_m1
    jsr chk_ac
    ldx #<test_sub__n
    ldy #>test_sub__n
    jmp t_result
test_sub__n: .text "DSUB"
    .byte 0

// --- 5 - 5 = +0 (exact cancellation) --------------------------------
test_cancel:
    lda #5
    ldx #0
    jsr d_from_s16
    lda #<c_5
    ldy #>c_5
    jsr d_sub
    lda #<c_0
    ldx #>c_0
    jsr chk_ac
    ldx #<test_cancel__n
    ldy #>test_cancel__n
    jmp t_result
test_cancel__n: .text "DCANCEL"
    .byte 0

// --- 2((24) >> 16) + 1 = 16777217 (small addend survives) --------------------
test_addbig:
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
    ldx #<test_addbig__n
    ldy #>test_addbig__n
    jmp t_result
test_addbig__n: .text "DADD_BIG"
    .byte 0

// --- 2 * 3 = 6 -----------------------------------------------------
test_mul:
    lda #2
    ldx #0
    jsr d_from_s16
    lda #<c_3
    ldy #>c_3
    jsr d_mul
    lda #<c_6
    ldx #>c_6
    jsr chk_ac
    ldx #<test_mul__n
    ldy #>test_mul__n
    jmp t_result
test_mul__n: .text "DMUL"
    .byte 0

// --- 7 * 8 = 56 (via s32) -------------------------------------------
test_mulint:
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
    ldx #<test_mulint__n
    ldy #>test_mulint__n
    jmp t_result
test_mulint__n: .text "DMUL_INT"
    .byte 0

// --- -3 * 4 = -12 ---------------------------------------------------
test_mulneg:
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
    ldx #<test_mulneg__n
    ldy #>test_mulneg__n
    jmp t_result
test_mulneg__n: .text "DMUL_NEG"
    .byte 0

// --- 6 / 2 = 3 ------------------------------------------------------
test_div:
    lda #6
    ldx #0
    jsr d_from_s16
    lda #<c_2
    ldy #>c_2
    jsr d_div
    lda #<c_3
    ldx #>c_3
    jsr chk_ac
    ldx #<test_div__n
    ldy #>test_div__n
    jmp t_result
test_div__n: .text "DDIV"
    .byte 0

// --- 10 / 4 = 2.5 ---------------------------------------------------
test_divfrac:
    lda #10
    ldx #0
    jsr d_from_s16
    lda #<c_4
    ldy #>c_4
    jsr d_div
    lda #<c_2p5
    ldx #>c_2p5
    jsr chk_ac
    ldx #<test_divfrac__n
    ldy #>test_divfrac__n
    jmp t_result
test_divfrac__n: .text "DDIV_FRAC"
    .byte 0

// --- 1 / 2 = 0.5 ----------------------------------------------------
test_divhalf:
    lda #<c_1
    ldy #>c_1
    jsr d_load
    lda #<c_2
    ldy #>c_2
    jsr d_div
    lda #<c_half
    ldx #>c_half
    jsr chk_ac
    ldx #<test_divhalf__n
    ldy #>test_divhalf__n
    jmp t_result
test_divhalf__n: .text "DDIV_HALF"
    .byte 0

// --- parse "3" -> 3 -------------------------------------------------
test_str_int:
    lda #<s_3
    ldy #>s_3
    ldx #1
    jsr d_from_str
    jsr d_to_s32
    lda #<e_3
    ldx #>e_3
    jsr chk_p32
    ldx #<test_str_int__n
    ldy #>test_str_int__n
    jmp t_result
test_str_int__n: .text "DSTR_INT"
    .byte 0

// --- parse "-12" -> -12 ---------------------------------------------
test_str_neg:
    lda #<s_m12
    ldy #>s_m12
    ldx #3
    jsr d_from_str
    jsr d_to_s32
    lda #<e_m12
    ldx #>e_m12
    jsr chk_p32
    ldx #<test_str_neg__n
    ldy #>test_str_neg__n
    jmp t_result
test_str_neg__n: .text "DSTR_NEG"
    .byte 0

// --- parse "1000000" -> 1000000 -------------------------------------
test_str_big:
    lda #<s_1m
    ldy #>s_1m
    ldx #7
    jsr d_from_str
    jsr d_to_s32
    lda #<e_1m
    ldx #>e_1m
    jsr chk_p32
    ldx #<test_str_big__n
    ldy #>test_str_big__n
    jmp t_result
test_str_big__n: .text "DSTR_BIG"
    .byte 0

// --- parse "2.5" == 2.5 ---------------------------------------------
test_str_frac:
    lda #<s_2p5
    ldy #>s_2p5
    ldx #3
    jsr d_from_str
    lda #<c_2p5
    ldy #>c_2p5
    jsr d_cmp                    // 0 = equal = pass
    ldx #<test_str_frac__n
    ldy #>test_str_frac__n
    jmp t_result
test_str_frac__n: .text "DSTR_FRAC"
    .byte 0

// --- parse "0.5" == 0.5 ---------------------------------------------
test_str_half:
    lda #<s_half
    ldy #>s_half
    ldx #3
    jsr d_from_str
    lda #<c_half
    ldy #>c_half
    jsr d_cmp
    ldx #<test_str_half__n
    ldy #>test_str_half__n
    jmp t_result
test_str_half__n: .text "DSTR_HALF"
    .byte 0

// --- parse "1.5E1" == 15 --------------------------------------------
test_str_exp:
    lda #<s_15e
    ldy #>s_15e
    ldx #5
    jsr d_from_str
    lda #<c_15
    ldy #>c_15
    jsr d_cmp
    ldx #<test_str_exp__n
    ldy #>test_str_exp__n
    jmp t_result
test_str_exp__n: .text "DSTR_EXP"
    .byte 0

// --- d_to_str: 3 -> "3" --------------------------------------------
test_ts_int:
    lda #3
    ldx #0
    jsr d_from_s16
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_3
    ldx #>x_3
    jsr strcmp
    ldx #<test_ts_int__n
    ldy #>test_ts_int__n
    jmp t_result
test_ts_int__n: .text "DTS_INT"
    .byte 0

// --- -12 -> "-12" ---------------------------------------------------
test_ts_neg:
    lda #<-12
    ldx #>-12
    jsr d_from_s16
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_m12
    ldx #>x_m12
    jsr strcmp
    ldx #<test_ts_neg__n
    ldy #>test_ts_neg__n
    jmp t_result
test_ts_neg__n: .text "DTS_NEG"
    .byte 0

// --- 2.5 -> "2.5" ---------------------------------------------------
test_ts_frac:
    lda #<c_2p5
    ldy #>c_2p5
    jsr d_load
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_2p5
    ldx #>x_2p5
    jsr strcmp
    ldx #<test_ts_frac__n
    ldy #>test_ts_frac__n
    jmp t_result
test_ts_frac__n: .text "DTS_FRAC"
    .byte 0

// --- 0.5 -> "0.5" ---------------------------------------------------
test_ts_half:
    lda #<c_half
    ldy #>c_half
    jsr d_load
    jsr d_to_str
    sta CHK_ZP
    stx CHK_ZP+1
    lda #<x_half
    ldx #>x_half
    jsr strcmp
    ldx #<test_ts_half__n
    ldy #>test_ts_half__n
    jmp t_result
test_ts_half__n: .text "DTS_HALF"
    .byte 0

// --- 1000000 -> "1000000" -------------------------------------------
test_ts_big:
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
    ldx #<test_ts_big__n
    ldy #>test_ts_big__n
    jmp t_result
test_ts_big__n: .text "DTS_BIG"
    .byte 0

// --- round trip: "1.5E1" parsed then printed -> "15" ----------------
test_ts_exp:
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
    ldx #<test_ts_exp__n
    ldy #>test_ts_exp__n
    jmp t_result
test_ts_exp__n: .text "DTS_RT"
    .byte 0

// --- sqrt(4) -> "2" ------------------------------------------------
test_sqrt4:
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
    ldx #<test_sqrt4__n
    ldy #>test_sqrt4__n
    jmp t_result
test_sqrt4__n: .text "DSQRT4"
    .byte 0

// --- sqrt(9) -> "3" (perfect square must land exact) ----------------
test_sqrt9:
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
    ldx #<test_sqrt9__n
    ldy #>test_sqrt9__n
    jmp t_result
test_sqrt9__n: .text "DSQRT9"
    .byte 0

// --- sqrt(144) -> "12" ----------------------------------------------
test_sqrt144:
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
    ldx #<test_sqrt144__n
    ldy #>test_sqrt144__n
    jmp t_result
test_sqrt144__n: .text "DSQRT144"
    .byte 0

// --- sqrt(1000000) -> "1000" ----------------------------------------
test_sqrt1m:
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
    ldx #<test_sqrt1m__n
    ldy #>test_sqrt1m__n
    jmp t_result
test_sqrt1m__n: .text "DSQRT_1M"
    .byte 0

// --- sqrt(-4) -> "NAN" ----------------------------------------------
test_sqrtneg:
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
    ldx #<test_sqrtneg__n
    ldy #>test_sqrtneg__n
    jmp t_result
test_sqrtneg__n: .text "DSQRT_NEG"
    .byte 0

// --- exp(0) -> "1" -------------------------------------------------
test_exp0:
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
    ldx #<test_exp0__n
    ldy #>test_exp0__n
    jmp t_result
test_exp0__n: .text "DEXP0"
    .byte 0

// --- exp(1) = e, first 13 chars "2.71828182845" -------------------
test_exp1:
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
    ldx #<test_exp1__n
    ldy #>test_exp1__n
    jmp t_result
test_exp1__n: .text "DEXP1"
    .byte 0

// --- ln(1) -> "0" -------------------------------------------------
test_ln1:
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
    ldx #<test_ln1__n
    ldy #>test_ln1__n
    jmp t_result
test_ln1__n: .text "DLN1"
    .byte 0

// --- ln(2), first 14 chars "0.693147180559" -----------------------
test_ln2:
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
    ldx #<test_ln2__n
    ldy #>test_ln2__n
    jmp t_result
test_ln2__n: .text "DLN2"
    .byte 0

// --- ln(exp(1)) round-trips to within 2^-30 of 1 ------------------
test_lnexp:
    lda #1
    ldx #0
    jsr d_from_s16
    jsr d_exp
    jsr d_ln
    lda #<c_1
    ldy #>c_1
    jsr d_sub                    // result - 1
    jsr d_abs
    lda #<c_eps
    ldy #>c_eps
    jsr d_cmp                    // |result-1| < eps ?  ($FF = less)
    ldy #1
    cmp #$FF
    bne test_lnexp__report
    ldy #0
test_lnexp__report:
    tya
    ldx #<test_lnexp__n
    ldy #>test_lnexp__n
    jmp t_result
test_lnexp__n: .text "DLN_EXP"
    .byte 0

// --- 5((0) >> 16) = "1" -----------------------------------------------------
test_pow0:
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
    ldx #<test_pow0__n
    ldy #>test_pow0__n
    jmp t_result
test_pow0__n: .text "DPOW0"
    .byte 0

// --- 2((0) >> 16).5 = sqrt(2), first 12 chars "1.4142135623" ---------------
test_powhalf:
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
    ldx #<test_powhalf__n
    ldy #>test_powhalf__n
    jmp t_result
test_powhalf__n: .text "DPOW_HALF"
    .byte 0

// --- 2((10) >> 16) within 2^-30 of 1024 -------------------------------------
test_powint:
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
    bne test_powint__report
    ldy #0
test_powint__report:
    tya
    ldx #<test_powint__n
    ldy #>test_powint__n
    jmp t_result
test_powint__n: .text "DPOW_INT"
    .byte 0

// --- sin(0) -> "0", cos(0) -> "1", tan(0) -> "0" ------------------
test_sin0:
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
    ldx #<test_sin0__n
    ldy #>test_sin0__n
    jmp t_result
test_sin0__n: .text "DSIN0"
    .byte 0

test_cos0:
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
    ldx #<test_cos0__n
    ldy #>test_cos0__n
    jmp t_result
test_cos0__n: .text "DCOS0"
    .byte 0

// --- sin(pi/2) -> "1" ----------------------------------------------
test_sinhalfpi:
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
    ldx #<test_sinhalfpi__n
    ldy #>test_sinhalfpi__n
    jmp t_result
test_sinhalfpi__n: .text "DSIN_HPI"
    .byte 0

// --- sin(1), first 13 chars "0.84147098480" ----------------------
test_sin1:
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
    ldx #<test_sin1__n
    ldy #>test_sin1__n
    jmp t_result
test_sin1__n: .text "DSIN1"
    .byte 0

test_tan0:
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
    ldx #<test_tan0__n
    ldy #>test_tan0__n
    jmp t_result
test_tan0__n: .text "DTAN0"
    .byte 0

// --- atan(0) -> "0" -----------------------------------------------
test_atan0:
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
    ldx #<test_atan0__n
    ldy #>test_atan0__n
    jmp t_result
test_atan0__n: .text "DATAN0"
    .byte 0

// --- atan(1) within 2^-30 of pi/4 ---------------------------------
test_atan1:
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
    bne test_atan1__report
    ldy #0
test_atan1__report:
    tya
    ldx #<test_atan1__n
    ldy #>test_atan1__n
    jmp t_result
test_atan1__n: .text "DATAN1"
    .byte 0

// --- atan(sqrt3) = pi/3, first 14 chars "1.047197551196" ---------
test_atansqrt3:
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
    ldx #<test_atansqrt3__n
    ldy #>test_atansqrt3__n
    jmp t_result
test_atansqrt3__n: .text "DATAN_S3"
    .byte 0

// --- sinh(0) -> "0", cosh(0) -> "1" ------------------------------
test_sinh0:
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
    ldx #<test_sinh0__n
    ldy #>test_sinh0__n
    jmp t_result
test_sinh0__n: .text "DSINH0"
    .byte 0

test_cosh0:
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
    ldx #<test_cosh0__n
    ldy #>test_cosh0__n
    jmp t_result
test_cosh0__n: .text "DCOSH0"
    .byte 0

// --- sinh(1), first 12 chars "1.1752011936" ----------------------
test_sinh1:
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
    ldx #<test_sinh1__n
    ldy #>test_sinh1__n
    jmp t_result
test_sinh1__n: .text "DSINH1"
    .byte 0

// --- cosh(1), first 12 chars "1.5430806348" ----------------------
test_cosh1:
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
    ldx #<test_cosh1__n
    ldy #>test_cosh1__n
    jmp t_result
test_cosh1__n: .text "DCOSH1"
    .byte 0

// --- tanh(1), first 12 chars "0.7615941559" ----------------------
test_tanh1:
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
    ldx #<test_tanh1__n
    ldy #>test_tanh1__n
    jmp t_result
test_tanh1__n: .text "DTANH1"
    .byte 0

// --- tanh(30) saturates to "1" ------------------------------------
test_tanhbig:
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
    ldx #<test_tanhbig__n
    ldy #>test_tanhbig__n
    jmp t_result
test_tanhbig__n: .text "DTANH_BIG"
    .byte 0

// NUL-terminated string compare of the first strncmp_n bytes.
strncmp:
    sta CHK2
    stx CHK2+1
    ldy #0
strncmp__l:
    cpy strncmp_n
    beq strncmp__ok
    lda (CHK_ZP),y
    cmp (CHK2),y
    bne strncmp__bad
    iny
    bne strncmp__l
strncmp__ok:
    lda #0
    rts
strncmp__bad:
    lda #1
    rts

// NUL-terminated string compare: expected in A/X, actual at CHK_ZP.
// A = 0 if equal.
strcmp:
    sta CHK2
    stx CHK2+1
    ldy #0
strcmp__l:
    lda (CHK_ZP),y
    cmp (CHK2),y
    bne strcmp__bad
    lda (CHK_ZP),y
    beq strcmp__ok
    iny
    bne strcmp__l
strcmp__ok:
    lda #0
    rts
strcmp__bad:
    lda #1
    rts

// --- helpers ---------------------------------------------------------
// A=lo, X=hi of 8 expected bytes; A=0 if d_ac matches
chk_ac:
    sta CHK_ZP
    stx CHK_ZP+1
    ldy #7
chk_ac__l:
    lda d_ac,y
    cmp (CHK_ZP),y
    bne chk_ac__bad
    dey
    bpl chk_ac__l
    lda #0
    rts
chk_ac__bad:
    lda #1
    rts

// A=lo, X=hi of 4 expected bytes; A=0 if X16_P0..P3 matches
chk_p32:
    sta CHK_ZP
    stx CHK_ZP+1
    ldy #3
chk_p32__l:
    lda X16_P0,y
    cmp (CHK_ZP),y
    bne chk_p32__bad
    dey
    bpl chk_p32__l
    lda #0
    rts
chk_p32__bad:
    lda #1
    rts

// --- constants -------------------------------------------------------
c_0: .byte $00,$00,$00,$00,$00,$00,$00,$00   // 0.0
c_1: .byte $00,$00,$00,$00,$00,$00,$F0,$3F   // 1.0
c_2: .byte $00,$00,$00,$00,$00,$00,$00,$40   // 2.0
c_3: .byte $00,$00,$00,$00,$00,$00,$08,$40   // 3.0
c_4: .byte $00,$00,$00,$00,$00,$00,$10,$40   // 4.0
c_5: .byte $00,$00,$00,$00,$00,$00,$14,$40   // 5.0
c_m2: .byte $00,$00,$00,$00,$00,$00,$00,$C0   // -2.0
c_m3: .byte $00,$00,$00,$00,$00,$00,$08,$C0   // -3.0
c_2p24: .byte $00,$00,$00,$00,$00,$00,$70,$41   // 16777216.0
c_half: .byte $00,$00,$00,$00,$00,$00,$E0,$3F   // 0.5
c_1p5: .byte $00,$00,$00,$00,$00,$00,$F8,$3F   // 1.5
c_m1: .byte $00,$00,$00,$00,$00,$00,$F0,$BF   // -1.0
c_6: .byte $00,$00,$00,$00,$00,$00,$18,$40   // 6.0
c_8: .byte $00,$00,$00,$00,$00,$00,$20,$40   // 8.0
c_2p5: .byte $00,$00,$00,$00,$00,$00,$04,$40   // 2.5
c_15: .byte $00,$00,$00,$00,$00,$00,$2E,$40   // 15.0

e_123: .byte $15,$CD,$5B,$07               // 123456789
e_neg2e9: .byte $00,$6C,$CA,$88               // -2000000000
e_2p24p1: .byte $01,$00,$00,$01               // 16777217
e_56: .byte $38,$00,$00,$00               // 56
e_m12: .byte $F4,$FF,$FF,$FF               // -12
e_3: .byte $03,$00,$00,$00               // 3
e_1m: .byte $40,$42,$0F,$00               // 1000000

s_3: .text "3"
s_m12: .text "-12"
s_1m: .text "1000000"
s_2p5: .text "2.5"
s_half: .text "0.5"
s_15e: .text "1.5E1"

x_3: .text "3"
    .byte 0
x_m12: .text "-12"
    .byte 0
x_2p5: .text "2.5"
    .byte 0
x_half: .text "0.5"
    .byte 0
x_1m: .text "1000000"
    .byte 0
x_15: .text "15"
    .byte 0
x_2: .text "2"
    .byte 0
x_4: .text "4"
    .byte 0
x_12: .text "12"
    .byte 0
x_1000: .text "1000"
    .byte 0
x_nan: .text "NAN"
    .byte 0
x_1s: .text "1"
    .byte 0
x_0s: .text "0"
    .byte 0
x_e: .text "2.71828182845"
x_ln2: .text "0.693147180559"
x_sqrt2: .text "1.4142135623"
x_sin1: .text "0.84147098480"
x_pi3: .text "1.047197551196"
x_sinh1: .text "1.1752011936"
x_cosh1: .text "1.5430806348"
x_tanh1: .text "0.7615941559"
c_30: .byte $00,$00,$00,$00,$00,$00,$3E,$40   // 30.0
c_pi4: .byte $18,$2D,$44,$54,$FB,$21,$E9,$3F   // pi/4
c_sqrt3: .byte $AA,$4C,$58,$E8,$7A,$B6,$FB,$3F   // sqrt(3)
c_pih: .byte $18,$2D,$44,$54,$FB,$21,$F9,$3F   // pi/2
c_ten: .byte $00,$00,$00,$00,$00,$00,$24,$40   // 10.0
c_1024: .byte $00,$00,$00,$00,$00,$00,$90,$40   // 1024.0
c_eps: .byte $00,$00,$00,$00,$00,$00,$10,$3E   // 2^-30 ~ 9.3e-10

strncmp_n: .byte 0

#import "testlib.asm"
#import "x16_code.asm"
