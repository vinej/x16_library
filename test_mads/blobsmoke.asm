;ACME
; =====================================================================
; x16lib :: test/blobsmoke.asm -- validate the dist blob and bindings
; =====================================================================
;   .\dist.ps1        (which runs:  .\build.ps1 -Test -Source test\blobsmoke.asm)
;
; This program deliberately does NOT source the library. It uses only
; what a ca65 / 64tass / KickAssembler user gets: the generated
; dist/acme/x16lib.inc bindings (same numbers, ACME syntax) plus the
; macro layer, with the pre-assembled dist/x16lib.bin included at
; $8000. If a routine or variable address in the bindings is wrong, or
; the blob does not actually work at its fixed org, this fails.
; =====================================================================

    icl "dist/acme/x16lib.inc"      ; GENERATED constants + addresses
    icl "core/macros.asm"           ; pure macro layer (emits no code)

T_ZP = $70

    org $0801
    basic_stub

main
    jsr t_init

    jsr smoke_magic
    jsr smoke_i16
    jsr smoke_to_dec
    jsr smoke_vera_fill

    jsr t_summary
    rts

; =====================================================================
; The blob's signature must sit at exactly $8000: "X16L", version 1.
; A wrong org would shift every binding address.
; =====================================================================
smoke_magic
    lda x16lib_magic
    cmp #'X'
    bne smoke_magic__fail
    lda x16lib_magic+1
    cmp #'1'
    bne smoke_magic__fail
    lda x16lib_magic+2
    cmp #'6'
    bne smoke_magic__fail
    lda x16lib_magic+3
    cmp #'L'
    bne smoke_magic__fail
    lda x16lib_version
    cmp #1
    bne smoke_magic__fail
    lda #0
    bra smoke_magic__report
smoke_magic__fail
    lda #1
smoke_magic__report
    ldx #<smoke_magic__name
    ldy #>smoke_magic__name
    jmp t_result
smoke_magic__name dta c'BLOB_MAGIC', $00

; =====================================================================
; Call an arithmetic routine through its generated address, passing
; operands through the i16_a/i16_b addresses from the bindings.
; =====================================================================
smoke_i16
    i16_const i16_a,1000
    i16_const i16_b,7
    jsr i16_divmod
    bcs smoke_i16__fail
    lda i16_a
    cmp #142
    bne smoke_i16__fail
    lda i16_a+1
    bne smoke_i16__fail
    lda i16_r
    cmp #6
    bne smoke_i16__fail
    lda i16_r+1
    bne smoke_i16__fail
    lda #0
    bra smoke_i16__report
smoke_i16__fail
    lda #1
smoke_i16__report
    ldx #<smoke_i16__name
    ldy #>smoke_i16__name
    jmp t_result
smoke_i16__name dta c'BLOB_I16_DIVMOD', $00

; =====================================================================
; u16_to_dec exercises the X16_P0/P1 zero-page bindings and returns a
; pointer into the blob's own num_buf.
; =====================================================================
smoke_to_dec
    lda #<65535
    sta X16_P0
    lda #>65535
    sta X16_P1
    jsr u16_to_dec              ; A/X -> "65535", Y = 5
    cpy #5
    bne smoke_to_dec__fail

    sta T_ZP
    stx T_ZP+1
    ldy #0
smoke_to_dec__cmp
    lda (T_ZP),y
    cmp smoke_to_dec__expect,y
    bne smoke_to_dec__fail
    cmp #0
    beq smoke_to_dec__ok
    iny
    bne smoke_to_dec__cmp
smoke_to_dec__ok
    lda #0
    bra smoke_to_dec__report
smoke_to_dec__fail
    lda #1
smoke_to_dec__report
    ldx #<smoke_to_dec__name
    ldy #>smoke_to_dec__name
    jmp t_result
smoke_to_dec__expect dta c'65535', $00
smoke_to_dec__name   dta c'BLOB_U16_TO_DEC', $00

; =====================================================================
; The macro layer against the blob: point port 0 with +vera_addr, fill
; through the blob's vera_fill, verify through port 1.
; =====================================================================
smoke_vera_fill
    vera_addr 0,$04000,VERA_INC_1
    lda #$5A
    ldx #16
    ldy #0
    jsr vera_fill

    vera_addr 1,$04000,VERA_INC_1
    ldx #16
smoke_vera_fill__check
    lda VERA_DATA1
    cmp #$5A
    bne smoke_vera_fill__fail
    dex
    bne smoke_vera_fill__check
    lda #0
    bra smoke_vera_fill__report
smoke_vera_fill__fail
    lda #1
smoke_vera_fill__report
    ldx #<smoke_vera_fill__name
    ldy #>smoke_vera_fill__name
    jmp t_result
smoke_vera_fill__name dta c'BLOB_VERA_FILL', $00

; ---------------------------------------------------------------------
    icl "test_mads/testlib.asm"

    org X16LIB_ORG  ; the org travels in the generated inc
!binary "dist/x16lib.bin"
