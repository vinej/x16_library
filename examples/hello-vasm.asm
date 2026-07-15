;vasm
; =====================================================================
; x16lib example :: hello-vasm.asm
; =====================================================================
; The vasm twin of examples/hello.asm: include in place of !source, org
; in place of *=, .locals in place of @cheap labels (same scoping!), and
; a macro is called by name with no leading '+'. Assembles to the same
; PRG as the ACME build.
;
;   .\build_vasm.ps1 -Source examples\hello-vasm.asm -Run
; =====================================================================

    include "x16.asm"

X16_USE_VERA = 1

    org $0801
    basic_stub

; ---------------------------------------------------------------------
main
    lda #PETSCII_CLS
    jsr CHROUT

    ; Print a greeting through the KERNAL.
    ldx #0
.print
    lda msg,x
    beq .printed
    jsr CHROUT
    inx
    bne .print
.printed

    ; Star the top text row, straight in VRAM (step by 2: screen codes
    ; only, colours untouched).
    vera_addr 0, VRAM_TEXT, VERA_INC_2
    lda #$2A                    ; screen code for '*'
    ldx #80                     ; 80 columns
    ldy #0
    jsr vera_fill

    ; Report whether this VERA has the FX register set.
    jsr vera_has_fx
    bcc .nofx
    ldx #0
.fxmsg
    lda msg_fx,x
    beq .done
    jsr CHROUT
    inx
    bne .fxmsg
.nofx
    ldx #0
.nofxmsg
    lda msg_nofx,x
    beq .done
    jsr CHROUT
    inx
    bne .nofxmsg
.done
    rts

; ---------------------------------------------------------------------
msg      byte "HELLO FROM X16LIB", $0D, $00
msg_fx   byte "VERA FX: YES", $0D, $00
msg_nofx byte "VERA FX: NO", $0D, $00

; ---------------------------------------------------------------------
    include "x16_code.asm"
