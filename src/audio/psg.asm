;ACME
; =====================================================================
; x16lib :: audio/psg.asm -- VERA PSG (16 voices)
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
; Requires X16_USE_VERA (psg_init uses vera_fill).
;
; The voices live in VRAM at $1F9C0, four bytes each:
;   0  frequency 7:0
;   1  frequency 15:8
;   2  right(7) | left(6) | volume(5:0)
;   3  waveform(7:6) | pulse width or XOR(5:0)
;
; output_frequency = 25000000/512 / 2^17 * freq_word
;   -> freq_word = Hz * 2.68435 (approximately), so A4 (440 Hz) is 1181.
;
; That VRAM range is write-only. Reads return the last value the host
; wrote, so psg_get_* only report what this program last set.
; =====================================================================

!zone x16_psg {

PSG_PAN_LEFT  = %01000000
PSG_PAN_RIGHT = %10000000
PSG_PAN_BOTH  = %11000000

PSG_WAVE_PULSE    = %00000000
PSG_WAVE_SAWTOOTH = %01000000
PSG_WAVE_TRIANGLE = %10000000
PSG_WAVE_NOISE    = %11000000

; ---------------------------------------------------------------------
; psg_voice_ptr -- point data port 0 at a voice register
;   in:  X = voice (0-15), A = byte offset within the voice (0-3)
; ---------------------------------------------------------------------
psg_voice_ptr
    sta X16_T2
    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL

    txa
    asl
    asl                         ; voice * 4, never carries (max 60)
    clc
    adc X16_T2
    clc
    adc #<VRAM_PSG              ; $C0 + up to 63, may carry
    sta VERA_ADDR_L
    lda #>VRAM_PSG
    adc #0
    sta VERA_ADDR_M
    lda #(VERA_ADDR_H_BANK | (VERA_INC_1 << 4))
    sta VERA_ADDR_H
    rts

; ---------------------------------------------------------------------
; psg_init -- silence all 16 voices
; ---------------------------------------------------------------------
psg_init
    +vera_addr 0, VRAM_PSG, VERA_INC_1
    lda #0
    ldx #(16 * VERA_PSG_VOICE_SIZE)
    ldy #0
    jmp vera_fill

; ---------------------------------------------------------------------
; psg_set_freq -- in: X = voice, X16_P0/P1 = frequency word
; ---------------------------------------------------------------------
psg_set_freq
    lda #0
    jsr psg_voice_ptr
    lda X16_P0
    sta VERA_DATA0
    lda X16_P1
    sta VERA_DATA0
    rts

; ---------------------------------------------------------------------
; psg_set_vol -- in: X = voice, A = volume (0-63), Y = pan (PSG_PAN_*)
; ---------------------------------------------------------------------
psg_set_vol
    and #$3F
    sta X16_T3
    tya
    and #PSG_PAN_BOTH
    ora X16_T3
    sta X16_T3
    lda #2
    jsr psg_voice_ptr
    lda X16_T3
    sta VERA_DATA0
    rts

; ---------------------------------------------------------------------
; psg_set_wave -- in: X = voice, A = waveform (PSG_WAVE_*),
;                     Y = pulse width / XOR (0-63)
; ---------------------------------------------------------------------
psg_set_wave
    and #PSG_WAVE_NOISE         ; keep bits 7:6
    sta X16_T3
    tya
    and #$3F
    ora X16_T3
    sta X16_T3
    lda #3
    jsr psg_voice_ptr
    lda X16_T3
    sta VERA_DATA0
    rts

; ---------------------------------------------------------------------
; psg_note_off -- in: X = voice.  Volume to zero, everything else kept.
; ---------------------------------------------------------------------
psg_note_off
    lda #2
    jsr psg_voice_ptr
    lda VERA_DATA0              ; the host-written shadow
    and #PSG_PAN_BOTH           ; keep the panning, drop the volume
    pha
    lda #2
    jsr psg_voice_ptr
    pla
    sta VERA_DATA0
    rts

}   ; !zone x16_psg
