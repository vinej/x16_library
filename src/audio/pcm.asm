;ACME
; =====================================================================
; x16lib :: audio/pcm.asm -- VERA PCM audio (4 KB FIFO)
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; AUDIO_CTRL ($9F3B): bit 7 read = FIFO full, bit 6 read = FIFO empty,
;   bit 5 = 16-bit, bit 4 = stereo, bits 3:0 = volume (0-15).
;   Writing a 1 to bit 7 resets the FIFO.
; AUDIO_RATE ($9F3C): 0 stops playback, 128 = 48828 Hz. Above 128 is
;   invalid.
; AUDIO_DATA ($9F3D): each write pushes one byte. Writes are silently
;   dropped when the FIFO is full.
;
; Samples are two's-complement signed.
;
; Set the rate to 0, prime the FIFO, then set the real rate. Starting
; playback on an empty FIFO underruns immediately.
; =====================================================================

!zone x16_pcm {

PCM_FIFO_FULL   = %10000000
PCM_FIFO_EMPTY  = %01000000
PCM_FIFO_RESET  = %10000000     ; on write
PCM_16BIT       = %00100000
PCM_STEREO      = %00010000

; ---------------------------------------------------------------------
; pcm_ctrl  -- in: A = control byte (volume | stereo | 16-bit | reset)
; pcm_rate  -- in: A = sample rate (0 stops, 128 is full speed)
; pcm_reset -- clear the FIFO, keeping the current format and volume
; ---------------------------------------------------------------------
pcm_ctrl
    sta VERA_AUDIO_CTRL
    rts

pcm_rate
    cmp #129
    bcc @ok
    lda #128                    ; anything above 128 is invalid
@ok
    sta VERA_AUDIO_RATE
    rts

pcm_reset
    lda VERA_AUDIO_CTRL
    and #(PCM_16BIT | PCM_STEREO | $0F)
    ora #PCM_FIFO_RESET
    sta VERA_AUDIO_CTRL
    rts

; ---------------------------------------------------------------------
; pcm_full  -- out: carry set if the FIFO cannot take another byte
; pcm_empty -- out: carry set if the FIFO has run dry
; ---------------------------------------------------------------------
pcm_full
    lda VERA_AUDIO_CTRL
    asl                         ; bit 7 into carry
    rts

pcm_empty
    lda VERA_AUDIO_CTRL
    and #PCM_FIFO_EMPTY
    cmp #PCM_FIFO_EMPTY         ; carry set when the bit is set
    rts

; ---------------------------------------------------------------------
; pcm_put -- in: A = sample byte.  Dropped by the hardware if full.
; ---------------------------------------------------------------------
pcm_put
    sta VERA_AUDIO_DATA
    rts

; ---------------------------------------------------------------------
; pcm_write -- push a block into the FIFO
;   in:  X16_P0/P1 = source address, X16_P2/P3 = byte count
;
; Does not throttle: intended for priming an empty FIFO with up to 4 KB.
; Bytes written past a full FIFO are discarded by the hardware, so pace
; a longer stream yourself with pcm_full.
; ---------------------------------------------------------------------
pcm_write
    ldy #0
@loop
    lda X16_P2
    ora X16_P3
    beq @done                   ; count exhausted

    lda (X16_P0),y
    sta VERA_AUDIO_DATA

    inc X16_P0                  ; advance the source pointer
    bne @dec
    inc X16_P1
@dec
    lda X16_P2                  ; 16-bit decrement of the count
    bne @dec_low
    dec X16_P3
@dec_low
    dec X16_P2
    bra @loop
@done
    rts

}   ; !zone x16_pcm
