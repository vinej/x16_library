;ACME
; =====================================================================
; x16lib :: audio/zsm.asm -- compact ZSM stream player
; =====================================================================
; Gate: X16_USE_ZSM
;
; Supports ZSM revision 1 streams loaded in normal 16-bit address space:
;   - ZSM header validation ('z','m'), stream starts at header+16
;   - PSG register writes
;   - YM2151 register/value batch writes
;   - delay commands, EOF, and 16-bit loop offsets
;   - PCM EXTCMD channel 0 commands 0/1 (AUDIO_CTRL/AUDIO_RATE)
;
; X16_USE_ZSM_PCM adds PCM instrument triggers from the optional PCM
; table. This first PCM layer supports memory-resident sample data in
; 16-bit address space and uses the existing AFLOW PCM streamer.
;
; Call zsm_tick at the ZSM header's tick rate. Use zsm_get_tickrate after
; zsm_init if you need to configure your scheduler.
; =====================================================================

; (zone: file scope in 64tass)

ZSM_ERR_NONE    = 0
ZSM_ERR_MAGIC   = 1
ZSM_ERR_VERSION = 2
ZSM_ERR_RANGE   = 3
ZSM_ERR_PCM     = 4

ZSM_FLAG_ACTIVE = %00000001
ZSM_FLAG_LOOP   = %00000010
ZSM_FLAG_EOF    = %00000100
ZSM_FLAG_PCM    = %00001000

ZSM_MAX_VERSION = 1
ZSM_YM_TIMEOUT  = 128

.if xuse_zsm_pcm
ZSM_PCM_FIFO_RESET = %10000000
ZSM_PCM_16BIT      = %00100000
ZSM_PCM_STEREO     = %00010000
.endif

; ---------------------------------------------------------------------
; zsm_init -- initialize from a ZSM file header
;   in:  r0 = pointer to the 16-byte ZSM header
;   out: carry clear on success
;        carry set on failure, A = ZSM_ERR_*
;
; Only 16-bit loop offsets are supported. A file with loop offset bit
; 16 set returns ZSM_ERR_RANGE.
; ---------------------------------------------------------------------
zsm_init
    lda r0L
    sta zsm_baseL
    lda r0H
    sta zsm_baseH

    ldy #0
    lda (r0),y
    cmp #'z'
    bne _magic
    iny
    lda (r0),y
    cmp #'m'
    bne _magic

    ldy #2
    lda (r0),y
    cmp #ZSM_MAX_VERSION + 1
    bcs _version

    ldy #$0c
    lda (r0),y
    sta zsm_tickL
    iny
    lda (r0),y
    sta zsm_tickH

.if xuse_zsm_pcm
    jsr zsm_pcm_init
    bcs _pcm_error
.endif

    clc
    lda zsm_baseL
    adc #16
    sta zsm_ptrL
    lda zsm_baseH
    adc #0
    sta zsm_ptrH
    lda zsm_ptrL
    sta zsm_startL
    lda zsm_ptrH
    sta zsm_startH

    ldy #3
    lda (r0),y
    sta X16_T0
    iny
    lda (r0),y
    sta X16_T1
    iny
    lda (r0),y
    bne _range

    lda X16_T0
    ora X16_T1
    beq _noloop
    clc
    lda zsm_baseL
    adc X16_T0
    sta zsm_loopL
    lda zsm_baseH
    adc X16_T1
    sta zsm_loopH
    lda #(ZSM_FLAG_ACTIVE | ZSM_FLAG_LOOP)
    bra _state
_noloop
    stz zsm_loopL
    stz zsm_loopH
    lda #ZSM_FLAG_ACTIVE
_state
    sta zsm_flags
    stz zsm_delay
    lda #ZSM_ERR_NONE
    clc
    rts
_magic
    lda #ZSM_ERR_MAGIC
    sec
    rts
_version
    lda #ZSM_ERR_VERSION
    sec
    rts
_range
    lda #ZSM_ERR_RANGE
    sec
    rts
.if xuse_zsm_pcm
_pcm_error
    lda #ZSM_ERR_PCM
    sec
    rts
.endif

; ---------------------------------------------------------------------
; zsm_init_stream -- initialize a raw headerless ZSM stream
;   in: r0 = stream pointer, r1 = loop pointer or 0 for no loop
; ---------------------------------------------------------------------
zsm_init_stream
    lda r0L
    sta zsm_baseL
    sta zsm_ptrL
    sta zsm_startL
    lda r0H
    sta zsm_baseH
    sta zsm_ptrH
    sta zsm_startH
    lda r1L
    sta zsm_loopL
    lda r1H
    sta zsm_loopH
.if xuse_zsm_pcm
    stz zsm_pcm_flags
    stz zsm_pcm_rate
.endif
    lda r1L
    ora r1H
    beq _noloop
    lda #(ZSM_FLAG_ACTIVE | ZSM_FLAG_LOOP)
    bra _state
_noloop
    lda #ZSM_FLAG_ACTIVE
_state
    sta zsm_flags
    stz zsm_delay
    lda #60
    sta zsm_tickL
    stz zsm_tickH
    clc
    rts

; ---------------------------------------------------------------------
; zsm_play / zsm_stop / zsm_rewind
; ---------------------------------------------------------------------
zsm_play
    lda #ZSM_FLAG_ACTIVE
    tsb zsm_flags
    rts

zsm_stop
    lda #ZSM_FLAG_ACTIVE
    trb zsm_flags
.if xuse_zsm_pcm
    jsr pcm_stream_stop
    stz VERA_AUDIO_RATE
.endif
    rts

zsm_rewind
    lda zsm_startL
    sta zsm_ptrL
    lda zsm_startH
    sta zsm_ptrH
    stz zsm_delay
    lda #ZSM_FLAG_EOF
    trb zsm_flags
    rts

; ---------------------------------------------------------------------
; zsm_get_tickrate -- out: A = low byte, X = high byte
; ---------------------------------------------------------------------
zsm_get_tickrate
    lda zsm_tickL
    ldx zsm_tickH
    rts

; ---------------------------------------------------------------------
; zsm_status
;   out: A = ZSM_FLAG_* bits, carry set if active
; ---------------------------------------------------------------------
zsm_status
    lda zsm_flags
    lsr
    lda zsm_flags
    rts

; ---------------------------------------------------------------------
; zsm_tick -- advance playback by one player tick
;   out: A = ZSM_FLAG_* bits, carry set if still active
; ---------------------------------------------------------------------
zsm_tick
    lda zsm_flags
    and #ZSM_FLAG_ACTIVE
    beq _inactive
    lda zsm_delay
    beq _commands
    dec zsm_delay
    bra zsm_status
_commands
    jsr zsm_next
    cmp #$40
    bcc _psg
    beq _ext
    cmp #$80
    bcc _ym
    beq _eof

    and #$7f                    ; delay 1..127 ticks
    sta zsm_delay
    bra zsm_status

_psg
    tax                         ; X = PSG register offset
    jsr zsm_next                ; A = value
    jsr zsm_psg_write
    bra _commands

_ym
    and #$3f                    ; number of reg/value pairs
    tax
    beq _commands
_ym_loop
    phx
    jsr zsm_next
    tax                         ; X = YM register
    jsr zsm_next                ; A = value
    jsr zsm_ym_write
    plx
    dex
    bne _ym_loop
    bra _commands

_ext
    jsr zsm_next
    sta X16_T0                  ; ccnnnnnn
    and #$3f
    sta X16_T1                  ; remaining payload length
    lda X16_T0
    and #%11000000
    bne _skip_ext
    jsr zsm_ext_pcm
    bra _commands
_skip_ext
    jsr zsm_skip_t1
    bra _commands

_eof
    lda zsm_flags
    and #ZSM_FLAG_LOOP
    beq _stop_eof
    lda zsm_loopL
    sta zsm_ptrL
    lda zsm_loopH
    sta zsm_ptrH
    bra _commands
_stop_eof
    lda #ZSM_FLAG_ACTIVE
    trb zsm_flags
    lda #ZSM_FLAG_EOF
    tsb zsm_flags
_inactive
    jmp zsm_status

; ---------------------------------------------------------------------
; zsm_next -- read one stream byte and advance zsm_ptr
; ---------------------------------------------------------------------
zsm_next
    lda zsm_ptrL
    sta X16_TPTR0
    lda zsm_ptrH
    sta X16_TPTR0+1
    ldy #0
    lda (X16_TPTR0),y
    inc zsm_ptrL
    bne zsm_next_done
    inc zsm_ptrH
zsm_next_done
    rts

; ---------------------------------------------------------------------
; zsm_skip_t1 -- skip X16_T1 stream bytes
; ---------------------------------------------------------------------
zsm_skip_t1
    lda X16_T1
    beq zsm_skip_done
zsm_skip_loop
    jsr zsm_next
    dec X16_T1
    bne zsm_skip_loop
zsm_skip_done
    rts

; ---------------------------------------------------------------------
; zsm_ext_pcm -- handle EXTCMD channel 0 command/argument pairs
;   X16_T1 = payload length. Unknown/truncated commands are consumed.
; ---------------------------------------------------------------------
zsm_ext_pcm
    lda X16_T1
    beq zsm_ext_pcm_done
zsm_ext_pcm_loop
    jsr zsm_next
    tax                         ; command
    dec X16_T1
    beq zsm_ext_pcm_done        ; truncated command: consumed
    jsr zsm_next
    tay                         ; argument
    dec X16_T1
    txa
    beq zsm_ext_pcm_ctrl
    cmp #1
    beq zsm_ext_pcm_rate
.if xuse_zsm_pcm
    cmp #2
    beq zsm_ext_pcm_trigger
.endif
    bra zsm_ext_pcm_next        ; command 2 instrument trigger: ignored
zsm_ext_pcm_ctrl
    tya
    sta VERA_AUDIO_CTRL
    bra zsm_ext_pcm_next
zsm_ext_pcm_rate
    tya
.if xuse_zsm_pcm
    sta zsm_pcm_rate
.endif
    sta VERA_AUDIO_RATE
    bra zsm_ext_pcm_next
.if xuse_zsm_pcm
zsm_ext_pcm_trigger
    tya
    jsr zsm_pcm_trigger
.endif
zsm_ext_pcm_next
    lda X16_T1
    bne zsm_ext_pcm_loop
zsm_ext_pcm_done
    rts

.if xuse_zsm_pcm
; ---------------------------------------------------------------------
; zsm_pcm_init -- parse optional PCM header/table from the ZSM header
;   in: r0 = ZSM header pointer
;   out: carry set if the PCM header is present but unsupported/invalid
; ---------------------------------------------------------------------
zsm_pcm_init
    stz zsm_pcm_flags
    stz zsm_pcm_rate

    ldy #6
    lda (r0),y
    sta X16_T0
    iny
    lda (r0),y
    sta X16_T1
    iny
    lda (r0),y
    beq _pcm_offset_ok
    jmp _range
_pcm_offset_ok
    lda X16_T0
    ora X16_T1
    bne _has_pcm
    clc                         ; no PCM header
    rts
_has_pcm

    clc
    lda zsm_baseL
    adc X16_T0
    sta zsm_pcm_hdrL
    lda zsm_baseH
    adc X16_T1
    sta zsm_pcm_hdrH
    bcs _range

    lda zsm_pcm_hdrL
    sta X16_TPTR0
    lda zsm_pcm_hdrH
    sta X16_TPTR0+1
    ldy #0
    lda (X16_TPTR0),y
    cmp #'P'
    bne _range
    iny
    lda (X16_TPTR0),y
    cmp #'C'
    bne _range
    iny
    lda (X16_TPTR0),y
    cmp #'M'
    bne _range
    iny
    lda (X16_TPTR0),y
    sta zsm_pcm_last

    ; data base = pcm header + 4 + 16 * (last index + 1)
    lda zsm_pcm_last
    cmp #$ff
    bne _count_to_bytes
    stz X16_T0
    lda #$10
    sta X16_T1
    bra _table_bytes
_count_to_bytes
    inc a
    sta X16_T0
    stz X16_T1
    asl X16_T0
    rol X16_T1
    asl X16_T0
    rol X16_T1
    asl X16_T0
    rol X16_T1
    asl X16_T0
    rol X16_T1
_table_bytes
    clc
    lda zsm_pcm_hdrL
    adc #4
    sta zsm_pcm_dataL
    lda zsm_pcm_hdrH
    adc #0
    sta zsm_pcm_dataH
    clc
    lda zsm_pcm_dataL
    adc X16_T0
    sta zsm_pcm_dataL
    lda zsm_pcm_dataH
    adc X16_T1
    sta zsm_pcm_dataH
    bcs _range

    lda #(ZSM_FLAG_PCM)
    tsb zsm_pcm_flags
_ok
    clc
    rts
_range
    sec
    rts

; ---------------------------------------------------------------------
; zsm_pcm_present -- out: carry set if a supported PCM table is present
; ---------------------------------------------------------------------
zsm_pcm_present
    lda zsm_pcm_flags
    and #ZSM_FLAG_PCM
    beq _no
    sec
    rts
_no
    clc
    rts

; ---------------------------------------------------------------------
; zsm_pcm_trigger -- start the PCM instrument in A
; ---------------------------------------------------------------------
zsm_pcm_trigger
    sta X16_T0                  ; instrument index
    jsr zsm_pcm_present
    bcs _present
    rts
_present
    lda X16_T0
    cmp zsm_pcm_last
    bcc _index_ok
    beq _index_ok
    rts
_index_ok
    ; instrument pointer = header + 4 + index*16
    lda X16_T0
    sta X16_T1
    stz X16_T2
    asl X16_T1
    rol X16_T2
    asl X16_T1
    rol X16_T2
    asl X16_T1
    rol X16_T2
    asl X16_T1
    rol X16_T2
    clc
    lda zsm_pcm_hdrL
    adc #4
    sta X16_TPTR0
    lda zsm_pcm_hdrH
    adc #0
    sta X16_TPTR0+1
    clc
    lda X16_TPTR0
    adc X16_T1
    sta X16_TPTR0
    lda X16_TPTR0+1
    adc X16_T2
    sta X16_TPTR0+1

    ldy #1
    lda (X16_TPTR0),y           ; instrument AUDIO_CTRL format bits
    and #(ZSM_PCM_16BIT | ZSM_PCM_STEREO)
    sta X16_T3

    ldy #4                      ; sample offset high byte unsupported
    lda (X16_TPTR0),y
    bne _done
    ldy #7                      ; sample length high byte unsupported
    lda (X16_TPTR0),y
    bne _done

    ldy #2
    lda (X16_TPTR0),y
    sta X16_T4                  ; sample offset low
    iny
    lda (X16_TPTR0),y
    sta X16_T5                  ; sample offset high
    ldy #5
    lda (X16_TPTR0),y
    sta X16_P2                  ; sample length low
    iny
    lda (X16_TPTR0),y
    sta X16_P3                  ; sample length high
    ora X16_P2
    beq _done

    ldy #8
    lda (X16_TPTR0),y
    and #%10000000
    sta pcm_str_loop

    ; sample source = pcm data base + sample offset
    clc
    lda zsm_pcm_dataL
    adc X16_T4
    sta X16_P0
    lda zsm_pcm_dataH
    adc X16_T5
    sta X16_P1
    bcs _done                  ; crossed 64K, unsupported here

    stz VERA_AUDIO_RATE
    lda VERA_AUDIO_CTRL
    and #$0f
    ora X16_T3
    ora #ZSM_PCM_FIFO_RESET
    sta VERA_AUDIO_CTRL

    lda zsm_pcm_rate
    jmp pcm_stream_start
_done
    rts
.endif

; ---------------------------------------------------------------------
; zsm_psg_write -- write A to PSG register offset X
; ---------------------------------------------------------------------
zsm_psg_write
    sta X16_T0
    lda #VERA_CTRL_ADDRSEL
    trb VERA_CTRL
    txa
    clc
    adc #<VRAM_PSG
    sta VERA_ADDR_L
    lda #>VRAM_PSG
    adc #0
    sta VERA_ADDR_M
    lda #VERA_ADDR_H_BANK
    sta VERA_ADDR_H
    lda X16_T0
    sta VERA_DATA0
    rts

; ---------------------------------------------------------------------
; zsm_ym_write -- raw YM register write
;   in: A = value, X = register
; ---------------------------------------------------------------------
zsm_ym_write
    sta X16_T0
    stx X16_T1
    php
    sei
    ldy #ZSM_YM_TIMEOUT
_wait
    dey
    bmi _done
    bit YM_DATA
    bmi _wait
    lda X16_T1
    sta YM_REG
    nop
    nop
    nop
    lda X16_T0
    sta YM_DATA
_done
    plp
    rts

; ---------------------------------------------------------------------
; Player state.
; ---------------------------------------------------------------------
zsm_baseL  .byte 0
zsm_baseH  .byte 0
zsm_startL .byte 0
zsm_startH .byte 0
zsm_ptrL   .byte 0
zsm_ptrH   .byte 0
zsm_loopL  .byte 0
zsm_loopH  .byte 0
zsm_tickL  .byte 60
zsm_tickH  .byte 0
zsm_delay  .byte 0
zsm_flags  .byte 0
.if xuse_zsm_pcm
zsm_pcm_hdrL  .byte 0
zsm_pcm_hdrH  .byte 0
zsm_pcm_dataL .byte 0
zsm_pcm_dataH .byte 0
zsm_pcm_last  .byte 0
zsm_pcm_rate  .byte 0
zsm_pcm_flags .byte 0
.endif

; (end zone)
