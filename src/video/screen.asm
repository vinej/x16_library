;ACME
; =====================================================================
; x16lib :: video/screen.asm -- screen mode, text output, cursor
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
; =====================================================================

!zone x16_screen {

; ---------------------------------------------------------------------
; screen_set_mode
;   in:  A = mode  ($00 80x60, $01 80x30, $02 40x60, $03 40x30,
;                   $04 40x15, $05 20x30, $06 20x15, $07 22x23,
;                   $08 64x50, $09 64x25, $0A 32x50, $0B 32x25,
;                   $80 320x240@256c + 40x30 text)
;   out: carry clear on success, set if the mode is unsupported
;
; KERNAL SCREEN_MODE takes carry clear to mean "set".
; ---------------------------------------------------------------------
screen_set_mode
    clc
    jmp SCREEN_MODE

; ---------------------------------------------------------------------
; screen_get_mode
;   out: A = current mode
; ---------------------------------------------------------------------
screen_get_mode
    sec
    jmp SCREEN_MODE

; ---------------------------------------------------------------------
; screen_reset -- restore the default text mode (KERNAL CINT)
; ---------------------------------------------------------------------
screen_reset
    jmp CINT

; ---------------------------------------------------------------------
; screen_cls -- clear the text screen
; ---------------------------------------------------------------------
screen_cls
    lda #PETSCII_CLS
    jmp CHROUT

; ---------------------------------------------------------------------
; screen_color
;   in:  A = foreground (0-15), X = background (0-15)
;
; Sets the colour used by every subsequent CHROUT. Writes the KERNAL's
; editor colour byte directly -- there is no jump-table entry for this.
; ---------------------------------------------------------------------
screen_color
    and #$0F
    sta X16_T0
    txa
    and #$0F
    asl
    asl
    asl
    asl                         ; background into the high nibble
    ora X16_T0
    sta KERNAL_COLOR
    rts

; ---------------------------------------------------------------------
; screen_border
;   in:  A = colour (0-15)
;
; DC_BORDER is only visible when DCSEL = 0, so select that bank first.
; ---------------------------------------------------------------------
screen_border
    pha
    +vera_dcsel 0
    pla
    sta VERA_DC_BORDER
    rts

; ---------------------------------------------------------------------
; screen_locate -- move the text cursor
;   in:  X = row, Y = column
; screen_get_cursor -- read it back
;   out: X = row, Y = column
;
; KERNAL PLOT takes carry clear to mean "set".
; ---------------------------------------------------------------------
screen_locate
    clc
    jmp PLOT

screen_get_cursor
    sec
    jmp PLOT

; ---------------------------------------------------------------------
; screen_charset
;   in:  A = charset (1 = ISO, 2 = PET upper/graphics,
;                     3 = PET upper/lower, ... 12 = Katakana)
; ---------------------------------------------------------------------
screen_charset
    jmp SCREEN_SET_CHARSET

; ---------------------------------------------------------------------
; screen_puts -- print a NUL-terminated string
;   in:  A = address low, X = address high
;   Strings longer than 255 bytes are truncated at 255.
; ---------------------------------------------------------------------
screen_puts
    sta X16_TPTR0
    stx X16_TPTR0+1
    ldy #0
@loop
    lda (X16_TPTR0),y
    beq @done
    jsr CHROUT
    iny
    bne @loop
@done
    rts

}   ; !zone x16_screen
