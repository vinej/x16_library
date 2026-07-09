;ACME
; =====================================================================
; x16lib :: audio/ym.asm -- YM2151 FM synthesiser
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; The chip is at YM_REG ($9F40) and YM_DATA ($9F41). Note: NOT $9FE0.
;
; Two ways in, and they do not mix freely:
;
;   ym_write   writes a chip register directly. Fast, complete access to
;              everything (LFO, per-operator envelopes) -- but the ROM
;              audio driver keeps RAM shadows of volume and pan, and a
;              raw write leaves those stale.
;
;   ym_poke    goes through the ROM driver in BANK_AUDIO, keeping its
;              shadows coherent. Use this if you also use the note API.
;
; This is the AUDIOYM.TXT distinction between YM! and FMPOKE.
; =====================================================================

!zone x16_ym {

YM_TIMEOUT = 128                ; busy-wait spins before giving up
YM_BUSY    = %10000000          ; YM_DATA bit 7 while the chip is busy

; ---------------------------------------------------------------------
; ym_write -- raw register write
;   in:  A = value, X = register
;   out: carry clear on success, set if the chip stayed busy
;   Preserves A and X.
;
; The busy flag must be clear before touching YM_REG, and the chip needs
; settling time between the register select and the data write. Wrapped
; in sei so an interrupt cannot land between the two halves and leave a
; half-issued write behind.
; ---------------------------------------------------------------------
ym_write
    php
    sei

    ldy #YM_TIMEOUT
@wait
    dey
    bmi @timeout
    bit YM_DATA
    bmi @wait                   ; busy

    stx YM_REG
    nop                         ; settling time between select and data
    nop
    nop
    sta YM_DATA

    plp
    clc
    rts
@timeout
    plp
    sec
    rts

; ---------------------------------------------------------------------
; ym_busy -- out: carry set while the chip is busy
; ---------------------------------------------------------------------
ym_busy
    lda YM_DATA
    asl                         ; bit 7 into carry
    rts

; ---------------------------------------------------------------------
; ROM driver entry points. All of these live in BANK_AUDIO at $C000+,
; not in the $FFxx jump table, so they go through jsrfar -- which saves
; and restores the caller's ROM bank and preserves A/X/Y.
; ---------------------------------------------------------------------

; ym_init -- reset the chip and load the default instrument patches
ym_init
    +jsrfar rom_audio_init, BANK_AUDIO
    +jsrfar rom_ym_loaddefpatches, BANK_AUDIO
    rts

; ym_poke -- in: A = value, X = register.  Keeps the driver's shadows.
ym_poke
    +jsrfar rom_ym_write, BANK_AUDIO
    rts

; ym_patch -- in: A = patch number (0-162), X = channel (0-7)
ym_patch
    +jsrfar rom_ym_loadpatch, BANK_AUDIO
    rts

; ym_note -- in: A = packed note ((octave<<4) | 1..12), X = channel
;            0 releases the note
ym_note
    +jsrfar rom_ym_playnote, BANK_AUDIO
    rts

; ym_release -- in: X = channel
ym_release_note
    +jsrfar rom_ym_release, BANK_AUDIO
    rts

; ym_vol -- in: A = attenuation (0 = loudest), X = channel
ym_vol
    +jsrfar rom_ym_setatten, BANK_AUDIO
    rts

; ym_pan -- in: A = pan bits, X = channel
ym_pan
    +jsrfar rom_ym_setpan, BANK_AUDIO
    rts

; ym_drum -- in: A = drum (25-87), X = channel
ym_drum
    +jsrfar rom_ym_playdrum, BANK_AUDIO
    rts

}   ; !zone x16_ym
