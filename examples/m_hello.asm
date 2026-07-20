;ACME
; =====================================================================
; x16lib example :: m_hello.asm  (the macro edition of hello.asm)
; =====================================================================
; Same program as hello.asm, but the library calls go through the
; optional friendly macro layer (core/sugar.asm): set the gates, source
; the layer, and +xm_vera_fill replaces the load-the-registers-then-jsr
; dance. The KERNAL calls (CHROUT) and the compile-time plumbing macros
; (+vera_addr) are unchanged -- the xm_ layer only wraps library routines.
;
;   .\build.ps1 -Source examples\m_hello.asm -Run
; =====================================================================

!cpu 65c02
!source "x16.asm"

X16_USE_VERA = 1

!source "core/sugar.asm"        ; the +xm_* macros (gated by the above)

* = $0801
    +basic_stub

; ---------------------------------------------------------------------
main
    lda #PETSCII_CLS
    jsr CHROUT

    ldx #0                      ; print a greeting through the KERNAL
@print
    lda msg,x
    beq @printed
    jsr CHROUT
    inx
    bne @print
@printed

    ; Star the top text row, straight in VRAM. Stepping the data port by
    ; 2 writes only the screen codes and leaves the colours alone.
    +vera_addr 0, VRAM_TEXT, VERA_INC_2
    +xm_vera_fill $2A, 80       ; screen code '*' across 80 columns

    ; Report whether this VERA has the FX register set (no-arg: call it).
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
msg      !text "HELLO FROM X16LIB (MACROS)", $0D, $00
msg_fx   !text "VERA FX: YES", $0D, $00
msg_nofx !text "VERA FX: NO", $0D, $00

; ---------------------------------------------------------------------
!source "x16_code.asm"
