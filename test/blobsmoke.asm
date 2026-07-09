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

!cpu 65c02
!source "dist/acme/x16lib.inc"      ; GENERATED constants + addresses
!source "core/macros.asm"           ; pure macro layer (emits no code)

T_ZP = $70

* = $0801
    +basic_stub

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
    bne @fail
    lda x16lib_magic+1
    cmp #'1'
    bne @fail
    lda x16lib_magic+2
    cmp #'6'
    bne @fail
    lda x16lib_magic+3
    cmp #'L'
    bne @fail
    lda x16lib_version
    cmp #1
    bne @fail
    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "BLOB_MAGIC", $00

; =====================================================================
; Call an arithmetic routine through its generated address, passing
; operands through the i16_a/i16_b addresses from the bindings.
; =====================================================================
smoke_i16
    +i16_const i16_a, 1000
    +i16_const i16_b, 7
    jsr i16_divmod
    bcs @fail
    lda i16_a
    cmp #142
    bne @fail
    lda i16_a+1
    bne @fail
    lda i16_r
    cmp #6
    bne @fail
    lda i16_r+1
    bne @fail
    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "BLOB_I16_DIVMOD", $00

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
    bne @fail

    sta T_ZP
    stx T_ZP+1
    ldy #0
@cmp
    lda (T_ZP),y
    cmp @expect,y
    bne @fail
    cmp #0
    beq @ok
    iny
    bne @cmp
@ok
    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@expect !text "65535", $00
@name   !text "BLOB_U16_TO_DEC", $00

; =====================================================================
; The macro layer against the blob: point port 0 with +vera_addr, fill
; through the blob's vera_fill, verify through port 1.
; =====================================================================
smoke_vera_fill
    +vera_addr 0, $04000, VERA_INC_1
    lda #$5A
    ldx #16
    ldy #0
    jsr vera_fill

    +vera_addr 1, $04000, VERA_INC_1
    ldx #16
@check
    lda VERA_DATA1
    cmp #$5A
    bne @fail
    dex
    bne @check
    lda #0
    bra @report
@fail
    lda #1
@report
    ldx #<@name
    ldy #>@name
    jmp t_result
@name !text "BLOB_VERA_FILL", $00

; ---------------------------------------------------------------------
!source "test/testlib.asm"

* = $8000
!binary "dist/x16lib.bin"
