;ACME
; =====================================================================
; x16lib :: video/screen.asm -- screen mode, text output, cursor
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; ---------------------------------------------------------------------
; THE KERNAL REQUIRES ADDRSEL = 0.
;
; Several KERNAL screen routines write VERA_ADDR_L/M/H *before* they set
; ADDRSEL, taking it on faith that port 0 is already selected. The screen
; scroller is the clearest case (x16-rom-r49 kernal/drivers/x16/screen.s):
;
;       lda pnt : sta VERA_ADDR_L   ; destination -- ADDRSEL assumed 0
;       ...
;       lda #1  : sta VERA_CTRL     ; only now switch to port 1
;       lda sal : sta VERA_ADDR_L   ; source
;
; Call that with ADDRSEL = 1 and the destination lands in port 1, where
; the source promptly overwrites it. The screen corrupts.
;
; screen_set_char is worse still: it writes all three ADDR registers and
; then `sta VERA_DATA0` without ever touching VERA_CTRL. With ADDRSEL = 1
; the address goes to port 1 while the character goes out of port 0, at
; whatever stale address port 0 happened to hold.
;
; So every routine here that enters a KERNAL routine which touches VERA
; forces ADDRSEL = 0 first. If you call CHROUT / CINT yourself after
; touching port 1 -- and +vera_addr 1 and vera_copy both leave it
; selected -- either go through screen_chrout, or emit +vera_addrsel 0
; beforehand.
;
; Note also that the KERNAL leaves DCSEL = 0, so do not expect a DCSEL
; selection to survive a call into it.
; =====================================================================

; (zone: locals promoted to globals in vasm)

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
    pha
    vera_addrsel 0
    pla
    clc
    jmp SCREEN_MODE

; The query/border/cursor/charset/puts helpers below are behind
; X16_USE_SCREEN_EXTRA: a program that just sets a mode and prints does
; not need them, so the core (set_mode/reset/cls/chrout/color/locate)
; can stand alone. X16_USE_SCREEN pulls them, for compat.
    ifdef X16_USE_SCREEN_EXTRA
; ---------------------------------------------------------------------
; screen_get_mode
;   out: A = current mode
; ---------------------------------------------------------------------
screen_get_mode
    vera_addrsel 0
    sec
    jmp SCREEN_MODE

; ---------------------------------------------------------------------
; screen_get_size -- the live text grid, after any screen_set_mode
;   out: X = columns, Y = rows
; ---------------------------------------------------------------------
screen_get_size
    jmp SCREEN
    endif

; ---------------------------------------------------------------------
; screen_reset -- restore the default text mode (KERNAL CINT)
; ---------------------------------------------------------------------
screen_reset
    vera_addrsel 0
    jmp CINT

; ---------------------------------------------------------------------
; screen_cls -- clear the text screen
; ---------------------------------------------------------------------
screen_cls
    vera_addrsel 0
    lda #PETSCII_CLS
    jmp CHROUT

; ---------------------------------------------------------------------
; screen_chrout -- CHROUT with the ADDRSEL precondition established
;   in:  A = character
; ---------------------------------------------------------------------
screen_chrout
    pha
    vera_addrsel 0
    pla
    jmp CHROUT

; ---------------------------------------------------------------------
; screen_color
;   in:  A = foreground (0-15), X = background (0-15)
;
; Sets the colour used by every subsequent CHROUT. Writes the KERNAL's
; editor colour byte directly -- there is no jump-table entry for this.
; Touches no VERA state.
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

    ifdef X16_USE_SCREEN_EXTRA
; ---------------------------------------------------------------------
; screen_border
;   in:  A = colour (0-15)
;
; DC_BORDER is only visible when DCSEL = 0, so select that bank first.
; Does not enter the KERNAL.
; ---------------------------------------------------------------------
screen_border
    pha
    vera_dcsel 0
    pla
    sta VERA_DC_BORDER
    rts
    endif

; ---------------------------------------------------------------------
; screen_locate -- move the text cursor
;   in:  X = row, Y = column
; screen_get_cursor -- read it back
;   out: X = row, Y = column
;
; KERNAL PLOT takes carry clear to mean "set".
;
; No ADDRSEL guard here: PLOT only moves the cursor variables (it lands
; in screen_set_position, which just writes `pnt`) and never touches
; VERA. Adding one would cost a clobbered A for nothing.
; ---------------------------------------------------------------------
screen_locate
    clc
    jmp PLOT

    ifdef X16_USE_SCREEN_EXTRA
screen_get_cursor
    sec
    jmp PLOT

; ---------------------------------------------------------------------
; screen_charset
;   in:  A = charset (1 = ISO, 2 = PET upper/graphics,
;                     3 = PET upper/lower, ... 12 = Katakana)
; ---------------------------------------------------------------------
screen_charset
    pha
    vera_addrsel 0
    pla
    jmp SCREEN_SET_CHARSET

; ---------------------------------------------------------------------
; Direct text-map access.
;
; CHROUT costs several hundred cycles a character once the editor's
; scroll checks, colour handling and cursor bookkeeping are paid for.
; A program that repaints a whole text screen -- a spreadsheet, a file
; browser, any full-screen TUI -- cannot afford that, so these three
; write VERA's tile map itself: screen_addr points port 0 at a cell with
; auto-increment 1, and each following pair of bytes is one character
; and its colour. The address walks the row on its own, so a whole line
; costs one set-up and two stores per column.
;
; The KERNAL is not involved and neither is its cursor: these do not
; scroll, do not wrap, and do not move the CHROUT cursor. Do not print
; past the end of a row.
;
; Text is PETSCII on the way in -- the same bytes you would give CHROUT
; -- and is folded to screen codes here, so the caller never has to know
; the difference.
;
; The colour byte is foreground | background << 4, the same layout
; screen_color builds.
; ---------------------------------------------------------------------

; ---------------------------------------------------------------------
; screen_addr -- point VERA port 0 at a character cell
;   in:  X = row, Y = column
;
; Reads L1_MAPBASE and L1_CONFIG, so it follows whatever screen_set_mode
; left behind rather than assuming the 80x60 default. Leaves ADDRSEL = 0
; and the increment set to 1.
; ---------------------------------------------------------------------
screen_addr
    jsr screen_addr_calc
    vera_addrsel 0
    jmp screen_addr_store

; ---------------------------------------------------------------------
; screen_addr1 -- the same, for VERA port 1
;   in:  X = row, Y = column
;
; Port 1 is what you point at the destination when moving text around
; with vera_copy; screen_scroll below is the usual reason to want it.
; ---------------------------------------------------------------------
screen_addr1
    jsr screen_addr_calc
    vera_addrsel 1
screen_addr_store
    lda X16_T0
    sta VERA_ADDR_L
    lda X16_T1
    sta VERA_ADDR_M
    lda X16_T2
    and #$01                    ; bit 16 of the address
    ora #$10                    ; increment 1
    sta VERA_ADDR_H
    rts

; address of (X = row, Y = column) into X16_T0/T1/T2, port untouched
screen_addr_calc
    sty X16_T5                  ; column
    stx X16_T6                  ; row

    lda VERA_L1_MAPBASE         ; map base = MAPBASE << 9
    asl                         ; carry = bit 16
    sta X16_T1                  ; mid
    lda #0
    rol
    sta X16_T2                  ; high
    stz X16_T0                  ; low

    lda VERA_L1_CONFIG          ; MAP_WIDTH: 0=32 1=64 2=128 3=256 tiles
    lsr
    lsr
    lsr
    lsr
    and #3
    clc
    adc #6                      ; bytes per row = 2 << (5 + width)
    tay

    lda X16_T6                  ; row << Y
    sta X16_T3
    stz X16_T4
.shift
    asl X16_T3
    rol X16_T4
    dey
    bne .shift

    clc                         ; base += row * stride
    lda X16_T0
    adc X16_T3
    sta X16_T0
    lda X16_T1
    adc X16_T4
    sta X16_T1
    bcc .nocarry1
    inc X16_T2
.nocarry1
    lda X16_T5                  ; base += column * 2
    asl
    tax
    lda #0
    rol
    tay
    txa
    clc
    adc X16_T0
    sta X16_T0
    tya
    adc X16_T1
    sta X16_T1
    bcc .nocarry2
    inc X16_T2
.nocarry2
    rts

; ---------------------------------------------------------------------
; screen_scode -- PETSCII to screen code
;   in:  A = PETSCII, out: A = screen code
;
; The standard CBM folding. Exposed because a caller building its own
; tile data occasionally wants it.
; ---------------------------------------------------------------------
screen_scode
    cmp #$20
    bcc .plus80                 ; $00-$1F
    cmp #$40
    bcc .same                   ; $20-$3F
    cmp #$60
    bcc .minus40                ; $40-$5F
    cmp #$80
    bcc .minus20                ; $60-$7F
    cmp #$A0
    bcc .plus40                 ; $80-$9F
    cmp #$C0
    bcc .minus40                ; $A0-$BF
.minus80                        ; $C0-$FF
    sec
    sbc #$80
.same
    rts
.plus80
    clc
    adc #$80
    rts
.minus40
    sec
    sbc #$40
    rts
.minus20
    sec
    sbc #$20
    rts
.plus40
    clc
    adc #$40
    rts

; ---------------------------------------------------------------------
; screen_blit -- write a run of characters, all one colour
;   in:  X16_P0/P1 = source, A = count (1-255), X = colour byte
;
; Port 0 must already point at the first cell (screen_addr); it is left
; pointing just past the last one, so runs can be chained.
; ---------------------------------------------------------------------
screen_blit
    sta X16_T7                  ; count
    stx X16_T3                  ; colour
    ldy #0
.loop
    lda (X16_P0),y
    jsr screen_scode
    sta VERA_DATA0
    lda X16_T3
    sta VERA_DATA0
    iny
    cpy X16_T7
    bne .loop
    rts

; ---------------------------------------------------------------------
; screen_blitfill -- write a run of one repeated character
;   in:  A = count (1-255), X = colour byte, Y = character (PETSCII)
;
; Same contract as screen_blit; the usual way to blank part of a line.
; ---------------------------------------------------------------------
screen_blitfill
    sta X16_T7                  ; count
    stx X16_T3                  ; colour
    tya
    jsr screen_scode
    sta X16_T4                  ; screen code, converted once
    ldy #0
.loop
    lda X16_T4
    sta VERA_DATA0
    lda X16_T3
    sta VERA_DATA0
    iny
    cpy X16_T7
    bne .loop
    rts

; ---------------------------------------------------------------------
; screen_scroll -- slide a rectangle of the text screen up or down
;   in:  X16_P0 = top row of the region
;        X16_P1 = left column
;        X16_P2 = height, in rows
;        X16_P3 = width, in columns
;        X16_P4 = distance to move, in rows
;        A      = 0 to move the picture up (toward row 0), 1 for down
;
; The point of this is not to save typing: a full-screen program that
; re-renders its whole grid to scroll one line pays for every cell it
; draws, and for a spreadsheet or a directory listing most of that cost
; is formatting the contents, not the drawing. Moving the picture inside
; VRAM and rendering only the row that appears costs one row instead of
; a screenful, whatever the contents happen to be.
;
; The rows uncovered at the trailing edge keep their old contents -- the
; caller draws what belongs there. Nothing happens when the distance is
; zero, or when it is large enough that nothing would survive, so the
; caller can simply repaint in that case.
;
; Vertical only. Scrolling sideways would move a row onto itself, and
; vera_copy walks forward, so the two would overlap.
; ---------------------------------------------------------------------
screen_scroll
    sta X16_P7                  ; direction
    lda X16_P4
    beq .done                   ; nothing to do
    cmp X16_P2
    bcs .done                   ; nothing would survive: let the caller repaint

    sec
    lda X16_P2
    sbc X16_P4
    sta X16_P5                  ; rows to copy
    stz X16_P6                  ; index
.loop
    lda X16_P7
    bne .down
    lda X16_P0                  ; up: dst = top + i, src = dst + distance
    clc
    adc X16_P6
    sta X16_T7
    clc
    adc X16_P4
    tax
    bra .move
.down
    lda X16_P0                  ; down: dst = bottom - i, src = dst - distance
    clc
    adc X16_P2
    sec
    sbc #1
    sec
    sbc X16_P6
    sta X16_T7
    sec
    sbc X16_P4
    tax
.move
    phx                         ; port 1 = destination
    ldx X16_T7
    ldy X16_P1
    jsr screen_addr1
    plx                         ; port 0 = source
    ldy X16_P1
    jsr screen_addr
    lda X16_P3                  ; width in cells -> bytes
    asl
    tax
    lda #0
    rol
    tay
    jsr vera_copy
    inc X16_P6
    lda X16_P6
    cmp X16_P5
    bne .loop
.done
    rts

; ---------------------------------------------------------------------
; screen_puts -- print a NUL-terminated string
;   in:  A = address low, X = address high
;   Strings longer than 255 bytes are truncated at 255.
; ---------------------------------------------------------------------
screen_puts
    sta X16_TPTR0
    stx X16_TPTR0+1
    vera_addrsel 0
    ldy #0
.loop
    lda (X16_TPTR0),y
    beq .done
    jsr CHROUT
    iny
    bne .loop
.done
    rts
    endif

; (end zone)
