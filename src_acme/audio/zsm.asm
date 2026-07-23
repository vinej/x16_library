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
; PCM instrument triggers are consumed and ignored here. Full sample
; indexing/streaming belongs in a larger player; this gate provides the
; music-register parser that a game can tick from VSYNC or a timer.
;
; Call zsm_tick at the ZSM header's tick rate. Use zsm_get_tickrate after
; zsm_init if you need to configure your scheduler.
; =====================================================================

!zone x16_zsm {

ZSM_ERR_NONE    = 0
ZSM_ERR_MAGIC   = 1
ZSM_ERR_VERSION = 2
ZSM_ERR_RANGE   = 3

ZSM_FLAG_ACTIVE = %00000001
ZSM_FLAG_LOOP   = %00000010
ZSM_FLAG_EOF    = %00000100

ZSM_MAX_VERSION = 1
ZSM_YM_TIMEOUT  = 128

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
    bne @magic
    iny
    lda (r0),y
    cmp #'m'
    bne @magic

    ldy #2
    lda (r0),y
    cmp #ZSM_MAX_VERSION + 1
    bcs @version

    ldy #$0c
    lda (r0),y
    sta zsm_tickL
    iny
    lda (r0),y
    sta zsm_tickH

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
    bne @range

    lda X16_T0
    ora X16_T1
    beq @noloop
    clc
    lda zsm_baseL
    adc X16_T0
    sta zsm_loopL
    lda zsm_baseH
    adc X16_T1
    sta zsm_loopH
    lda #(ZSM_FLAG_ACTIVE | ZSM_FLAG_LOOP)
    bra @state
@noloop
    stz zsm_loopL
    stz zsm_loopH
    lda #ZSM_FLAG_ACTIVE
@state
    sta zsm_flags
    stz zsm_delay
    lda #ZSM_ERR_NONE
    clc
    rts
@magic
    lda #ZSM_ERR_MAGIC
    sec
    rts
@version
    lda #ZSM_ERR_VERSION
    sec
    rts
@range
    lda #ZSM_ERR_RANGE
    sec
    rts

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
    lda r1L
    ora r1H
    beq @noloop
    lda #(ZSM_FLAG_ACTIVE | ZSM_FLAG_LOOP)
    bra @state
@noloop
    lda #ZSM_FLAG_ACTIVE
@state
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
    beq @inactive
    lda zsm_delay
    beq @commands
    dec zsm_delay
    bra zsm_status
@commands
    jsr zsm_next
    cmp #$40
    bcc @psg
    beq @ext
    cmp #$80
    bcc @ym
    beq @eof

    and #$7f                    ; delay 1..127 ticks
    sta zsm_delay
    bra zsm_status

@psg
    tax                         ; X = PSG register offset
    jsr zsm_next                ; A = value
    jsr zsm_psg_write
    bra @commands

@ym
    and #$3f                    ; number of reg/value pairs
    tax
    beq @commands
@ym_loop
    phx
    jsr zsm_next
    tax                         ; X = YM register
    jsr zsm_next                ; A = value
    jsr zsm_ym_write
    plx
    dex
    bne @ym_loop
    bra @commands

@ext
    jsr zsm_next
    sta X16_T0                  ; ccnnnnnn
    and #$3f
    sta X16_T1                  ; remaining payload length
    lda X16_T0
    and #%11000000
    bne @skip_ext
    jsr zsm_ext_pcm
    bra @commands
@skip_ext
    jsr zsm_skip_t1
    bra @commands

@eof
    lda zsm_flags
    and #ZSM_FLAG_LOOP
    beq @stop_eof
    lda zsm_loopL
    sta zsm_ptrL
    lda zsm_loopH
    sta zsm_ptrH
    bra @commands
@stop_eof
    lda #ZSM_FLAG_ACTIVE
    trb zsm_flags
    lda #ZSM_FLAG_EOF
    tsb zsm_flags
@inactive
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
    bra zsm_ext_pcm_next        ; command 2 instrument trigger: ignored
zsm_ext_pcm_ctrl
    tya
    sta VERA_AUDIO_CTRL
    bra zsm_ext_pcm_next
zsm_ext_pcm_rate
    tya
    sta VERA_AUDIO_RATE
zsm_ext_pcm_next
    lda X16_T1
    bne zsm_ext_pcm_loop
zsm_ext_pcm_done
    rts

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
@wait
    dey
    bmi @done
    bit YM_DATA
    bmi @wait
    lda X16_T1
    sta YM_REG
    nop
    nop
    nop
    lda X16_T0
    sta YM_DATA
@done
    plp
    rts

; ---------------------------------------------------------------------
; Player state.
; ---------------------------------------------------------------------
zsm_baseL  !byte 0
zsm_baseH  !byte 0
zsm_startL !byte 0
zsm_startH !byte 0
zsm_ptrL   !byte 0
zsm_ptrH   !byte 0
zsm_loopL  !byte 0
zsm_loopH  !byte 0
zsm_tickL  !byte 60
zsm_tickH  !byte 0
zsm_delay  !byte 0
zsm_flags  !byte 0

}   ; !zone x16_zsm
