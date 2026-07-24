;ACME
; =====================================================================
; x16lib :: audio/wavfile.asm -- parse a WAV/RIFF header
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; wav_parse_header reads a RIFF/WAVE header from a memory buffer and
; publishes the PCM format, so the caller can hand the numbers to the
; PCM streamer and stream the sample data that follows. Parsing the
; small header from RAM keeps this independent of how the file is read
; (LOAD, MACPTR, a bank, ...); the caller streams the bulk data itself.
;
; WAV layout:  "RIFF" <size> "WAVE"  then 8-byte-headed chunks; the
; "fmt " chunk carries the format, the "data" chunk the samples.
; =====================================================================

; (zone: file scope in dasm)

    SUBROUTINE
wav_format   dc.b 0           ; audio format code (1 = PCM)
    SUBROUTINE
wav_channels dc.b 0           ; channel count
    SUBROUTINE
wav_rate     ds 4, 0        ; sample rate, little-endian
    SUBROUTINE
wav_bits     dc.b 0           ; bits per sample
    SUBROUTINE
wav_data_off dc.w 0           ; byte offset of the sample data in the buffer
    SUBROUTINE
wav_data_len ds 4, 0        ; sample-data length in bytes

    SUBROUTINE
wavfile_cur
    dc.w 0                   ; current chunk offset from the buffer base
    SUBROUTINE
wavfile_sz
    ds 4, 0                ; current chunk size
    SUBROUTINE
wavfile_adv
    dc.w 0                   ; bytes to advance to the next chunk
    SUBROUTINE
wavfile_fmt
    dc.b 0                   ; have we seen a fmt chunk yet?

; ---------------------------------------------------------------------
; wav_parse_header -- parse a WAV header from a buffer
;   in:  X16_P0/P1 = pointer to the header bytes (consumed as a walking
;        pointer; the buffer must hold everything up to the data chunk)
;   out: carry clear on success, with wav_format/channels/rate/bits and
;        wav_data_off/wav_data_len filled in; carry set if the buffer is
;        not RIFF/WAVE or has no fmt+data chunks.
; ---------------------------------------------------------------------
    SUBROUTINE
wav_parse_header
    bra wavfile_begin
    SUBROUTINE
wavfile_bad
    sec
    rts
    SUBROUTINE
wavfile_begin
    ldy #0                     ; "RIFF"
    lda (X16_P0),y
    cmp #'R
    bne wavfile_bad
    iny
    lda (X16_P0),y
    cmp #'I
    bne wavfile_bad
    iny
    lda (X16_P0),y
    cmp #'F
    bne wavfile_bad
    iny
    lda (X16_P0),y
    cmp #'F
    bne wavfile_bad
    ldy #8                     ; "WAVE"
    lda (X16_P0),y
    cmp #'W
    bne wavfile_bad
    iny
    lda (X16_P0),y
    cmp #'A
    bne wavfile_bad
    iny
    lda (X16_P0),y
    cmp #'V
    bne wavfile_bad
    iny
    lda (X16_P0),y
    cmp #'E
    bne wavfile_bad

    stz wavfile_fmt
    lda #12                    ; first chunk starts at offset 12
    sta wavfile_cur
    stz wavfile_cur+1
    lda X16_P0
    clc
    adc #12
    sta X16_P0
    lda X16_P1
    adc #0
    sta X16_P1

    SUBROUTINE
wavfile_chunk
    ldy #0                     ; "fmt " ?
    lda (X16_P0),y
    cmp #'f
    bne wavfile_not_fmt
    iny
    lda (X16_P0),y
    cmp #'m
    bne wavfile_not_fmt
    iny
    lda (X16_P0),y
    cmp #'t
    bne wavfile_not_fmt
    iny
    lda (X16_P0),y
    cmp #' 
    bne wavfile_not_fmt
    ; fmt chunk body starts at +8
    ldy #8
    lda (X16_P0),y
    sta wav_format
    ldy #10
    lda (X16_P0),y
    sta wav_channels
    ldy #12
    lda (X16_P0),y
    sta wav_rate
    iny
    lda (X16_P0),y
    sta wav_rate+1
    iny
    lda (X16_P0),y
    sta wav_rate+2
    iny
    lda (X16_P0),y
    sta wav_rate+3
    ldy #22
    lda (X16_P0),y
    sta wav_bits
    inc wavfile_fmt
    bra wavfile_advance

    SUBROUTINE
wavfile_not_fmt
    ldy #0                     ; "data" ?
    lda (X16_P0),y
    cmp #'d
    bne wavfile_advance
    iny
    lda (X16_P0),y
    cmp #'a
    bne wavfile_advance
    iny
    lda (X16_P0),y
    cmp #'t
    bne wavfile_advance
    iny
    lda (X16_P0),y
    cmp #'a
    bne wavfile_advance
    ; data chunk: length at +4, sample data at +8
    ldy #4
    lda (X16_P0),y
    sta wav_data_len
    iny
    lda (X16_P0),y
    sta wav_data_len+1
    iny
    lda (X16_P0),y
    sta wav_data_len+2
    iny
    lda (X16_P0),y
    sta wav_data_len+3
    lda wavfile_cur
    clc
    adc #8
    sta wav_data_off
    lda wavfile_cur+1
    adc #0
    sta wav_data_off+1
    lda wavfile_fmt                   ; a data chunk before fmt is malformed
    bne wavfile_datok
    jmp wavfile_bad
    SUBROUTINE
wavfile_datok
    clc
    rts

    SUBROUTINE
wavfile_advance
    ldy #4                     ; chunk size (32-bit; header chunks are small)
    lda (X16_P0),y
    sta wavfile_sz
    iny
    lda (X16_P0),y
    sta wavfile_sz+1
    iny
    lda (X16_P0),y
    sta wavfile_sz+2
    iny
    lda (X16_P0),y
    sta wavfile_sz+3
    lda wavfile_sz                    ; pad an odd size up to even
    and #1
    beq wavfile_even
    inc wavfile_sz
    bne wavfile_even
    inc wavfile_sz+1
    SUBROUTINE
wavfile_even
    lda wavfile_sz                    ; adv = 8 + size (16-bit is plenty pre-data)
    clc
    adc #8
    sta wavfile_adv
    lda wavfile_sz+1
    adc #0
    sta wavfile_adv+1
    lda X16_P0                 ; walk the pointer and the offset
    clc
    adc wavfile_adv
    sta X16_P0
    lda X16_P1
    adc wavfile_adv+1
    sta X16_P1
    lda wavfile_cur
    clc
    adc wavfile_adv
    sta wavfile_cur
    lda wavfile_cur+1
    adc wavfile_adv+1
    sta wavfile_cur+1
    lda wavfile_cur+1                 ; bail if we walk past a sane header size
    cmp #4                     ; ~1 KB of chunks without a data: give up
    bcc wavfile_more
    jmp wavfile_bad
    SUBROUTINE
wavfile_more
    jmp wavfile_chunk

; (end zone)
