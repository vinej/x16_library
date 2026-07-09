;ACME
; =====================================================================
; x16lib example :: hello.asm
; =====================================================================
; Smallest program that proves the whole toolchain works: assemble with
; ACME, autorun from BASIC, print through the KERNAL, and touch VRAM
; through the library.
;
;   .\build.ps1 -Source examples\hello.asm -Run
; =====================================================================

!cpu 65c02
!source "x16.asm"

X16_USE_VERA = 1

* = $0801
    +basic_stub

; ---------------------------------------------------------------------
main
    lda #PETSCII_CLS
    jsr CHROUT

    ; Print a greeting through the KERNAL.
    ldx #0
@print
    lda msg,x
    beq @printed
    jsr CHROUT
    inx
    bne @print
@printed

    ; Star the top text row, straight in VRAM.
    ;
    ; A text cell is two bytes: screen code, then colour. Stepping the
    ; data port by 2 writes only the screen codes and leaves the colours
    ; alone -- no read-modify-write, no second loop.
    +vera_addr 0, VRAM_TEXT, VERA_INC_2
    lda #$2A                    ; screen code for '*'
    ldx #80                     ; 80 columns
    ldy #0
    jsr vera_fill

    ; Report whether this VERA has the FX register set.
    jsr vera_has_fx
    bcc @nofx
    ldx #0
@fxmsg
    lda msg_fx,x
    beq @done
    jsr CHROUT
    inx
    bne @fxmsg
@nofx
    ldx #0
@nofxmsg
    lda msg_nofx,x
    beq @done
    jsr CHROUT
    inx
    bne @nofxmsg
@done
    rts

; ---------------------------------------------------------------------
msg      !text "HELLO FROM X16LIB", $0D, $00
msg_fx   !text "VERA FX: YES", $0D, $00
msg_nofx !text "VERA FX: NO", $0D, $00

; ---------------------------------------------------------------------
!source "x16_code.asm"
