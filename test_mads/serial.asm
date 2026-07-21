;ACME
; =====================================================================
; x16lib :: test/serial.asm -- on-target tests for comms/serial.asm
; =====================================================================
; This runner needs a UART to talk to, so build.ps1 -Test runs it under
; the emulator's serial-MIDI card (-midicard -sf2), which models two
; 16C550s at $9F60 and $9F68. We drive the library, then read the raw
; registers back through absolute addresses -- an oracle independent of
; the code under test, exactly like the VERA tests read the data port.
;
; What a 16C550 emulator can and cannot check:
;   detection and register programming (init) verify against readback;
;   the RX path is exercised only for its empty/non-blocking behaviour,
;   because nothing feeds the receive FIFO headless; TX is checked for
;   liveness (THRE handshake completes) since transmitted bytes leave
;   for the synth and cannot be read back. Real byte round-trips are a
;   hardware test, noted in the README.
; =====================================================================

    icl "x16.asm"

X16_USE_SERIAL = 1
X16_USE_SERIAL_ZIMODEM = 1      ; the WiFi/ESP32 layer (pulls SERIAL)

    icl "core/sugar.asm"        ; optional friendly xm_* macros (tested below)

; The harness's zero-page pointer (see runner.asm).
T_ZP = $70

; The two UARTs the emulated card presents, and the registers we probe.
U0      = $9F60
U0_IER  = U0+1
U0_LCR  = U0+3
U0_MCR  = U0+4
U0_LSR  = U0+5
U1      = $9F68
U1_LCR  = U1+3

    org $0801
    basic_stub

main
    jsr t_init

    jsr test_ser_detect
    jsr test_ser_init
    jsr test_ser_baud16
    jsr test_ser_select
    jsr test_ser_rx_empty
    jsr test_ser_put
    jsr test_zi_hexdecode
    jsr test_zi_cmd
    jsr test_serial_sugar

    jsr t_summary
    rts

; ---------------------------------------------------------------------
; ser_detect finds exactly the two UARTs the card presents, in order.
; ---------------------------------------------------------------------
test_ser_detect
    jsr ser_detect
    bcs test_ser_detect__fail                   ; carry clear = at least one found
    cmp #2                      ; A = count
    bne test_ser_detect__fail
    lda ser_u0                  ; first at $9F60
    cmp #<U0
    bne test_ser_detect__fail
    lda ser_u0+1
    cmp #>U0
    bne test_ser_detect__fail
    lda ser_u1                  ; second at $9F68
    cmp #<U1
    bne test_ser_detect__fail
    lda ser_u1+1
    cmp #>U1
    bne test_ser_detect__fail
    lda #0
    bra test_ser_detect__report
test_ser_detect__fail
    lda #1
test_ser_detect__report
    ldx #<test_ser_detect__name
    ldy #>test_ser_detect__name
    jmp t_result
test_ser_detect__name dta c'SER_DETECT', 0

; ---------------------------------------------------------------------
; ser_init programs 8N1 (LCR $03), auto-flow (MCR $27) and the 9600-baud
; divisor ($0060). Read every one of those straight off the chip.
; ---------------------------------------------------------------------
test_ser_init
    lda #<SER_BAUD_9600
    sta X16_P0
    lda #>SER_BAUD_9600
    sta X16_P1
    lda #<U0
    ldx #>U0
    jsr ser_init

    lda U0_LCR                  ; 8N1, DLAB off
    cmp #$03
    bne test_ser_init__fail
    lda U0_MCR                  ; DTR+RTS+auto-flow+OUT2
    cmp #$27
    bne test_ser_init__fail
    lda #$80                    ; raise DLAB to see the divisor latch
    sta U0_LCR
    lda U0                      ; DLL = low byte of $0060
    cmp #$60
    bne test_ser_init__fail
    lda U0_IER                  ; DLM = high byte of $0060
    cmp #$00
    bne test_ser_init__fail
    lda #$03                    ; put the line back the way init left it
    sta U0_LCR
    lda #0
    bra test_ser_init__report
test_ser_init__fail
    lda #1
test_ser_init__report
    ldx #<test_ser_init__name
    ldy #>test_ser_init__name
    jmp t_result
test_ser_init__name dta c'SER_INIT', 0

; ---------------------------------------------------------------------
; A divisor with a non-zero high byte proves ser_init writes DLM as well
; as DLL. $0180 is the 2400-baud divisor.
; ---------------------------------------------------------------------
test_ser_baud16
    lda #<SER_BAUD_2400
    sta X16_P0
    lda #>SER_BAUD_2400
    sta X16_P1
    lda #<U0
    ldx #>U0
    jsr ser_init

    lda #$80
    sta U0_LCR
    lda U0                      ; DLL = $80
    cmp #$80
    bne test_ser_baud16__fail
    lda U0_IER                  ; DLM = $01
    cmp #$01
    bne test_ser_baud16__fail
    lda #$03
    sta U0_LCR
    lda #0
    bra test_ser_baud16__report
test_ser_baud16__fail
    lda #1
test_ser_baud16__report
    ldx #<test_ser_baud16__name
    ldy #>test_ser_baud16__name
    jmp t_result
test_ser_baud16__name dta c'SER_BAUD16', 0

; ---------------------------------------------------------------------
; ser_init remembers which UART it was handed: initialise the second one
; and confirm its own LCR took the setting.
; ---------------------------------------------------------------------
test_ser_select
    lda #<SER_BAUD_9600
    sta X16_P0
    lda #>SER_BAUD_9600
    sta X16_P1
    lda #<U1
    ldx #>U1
    jsr ser_init

    lda U1_LCR                  ; UART 1's line control
    cmp #$03
    bne test_ser_select__fail
    lda #0
    bra test_ser_select__report
test_ser_select__fail
    lda #1
test_ser_select__report
    ldx #<test_ser_select__name
    ldy #>test_ser_select__name
    jmp t_result
test_ser_select__name dta c'SER_SELECT', 0

; ---------------------------------------------------------------------
; With nothing feeding the receive FIFO, ser_avail must say "nothing"
; and ser_get must return empty rather than block.
; ---------------------------------------------------------------------
test_ser_rx_empty
    lda #<SER_BAUD_9600
    sta X16_P0
    lda #>SER_BAUD_9600
    sta X16_P1
    lda #<U0
    ldx #>U0
    jsr ser_init

    jsr ser_avail               ; carry set would mean a phantom byte
    bcs test_ser_rx_empty__fail
    jsr ser_get                 ; must report empty (carry set), not hang
    bcc test_ser_rx_empty__fail
    lda #0
    bra test_ser_rx_empty__report
test_ser_rx_empty__fail
    lda #1
test_ser_rx_empty__report
    ldx #<test_ser_rx_empty__name
    ldy #>test_ser_rx_empty__name
    jmp t_result
test_ser_rx_empty__name dta c'SER_RX_EMPTY', 0

; ---------------------------------------------------------------------
; ser_put: the transmit holding register reads empty, so the THRE
; handshake should complete and the call return (a stuck poll would trip
; the harness's timeout). Confirms the TX path is live.
; ---------------------------------------------------------------------
test_ser_put
    lda #<SER_BAUD_9600
    sta X16_P0
    lda #>SER_BAUD_9600
    sta X16_P1
    lda #<U0
    ldx #>U0
    jsr ser_init

    lda U0_LSR                  ; THRE (bit 5) set = room to send
    and #%00100000
    beq test_ser_put__fail
    lda #'X'
    jsr ser_put                 ; returns only if the handshake cleared
    lda #0
    bra test_ser_put__report
test_ser_put__fail
    lda #1
test_ser_put__report
    ldx #<test_ser_put__name
    ldy #>test_ser_put__name
    jmp t_result
test_ser_put__name dta c'SER_PUT', 0

; ---------------------------------------------------------------------
; ZiModem's hex-mode payload decoder is pure computation, so it has an
; independent oracle: feed known ASCII hex, check the packed bytes back.
; This is the one ZiModem routine the emulator can verify -- the rest of
; the protocol talks to an ESP32 that is not present headless.
test_zi_hexdecode
    lda #<test_zi_hexdecode__out                  ; destination pointer in P0/P1
    sta X16_P0
    lda #>test_zi_hexdecode__out
    sta X16_P1
    ldy #10                     ; "DEADBEEF01" = 10 digits -> 5 bytes
    lda #<test_zi_hexdecode__hex
    ldx #>test_zi_hexdecode__hex
    jsr zi_hexdecode
    cmp #5                      ; A = bytes produced
    bne test_zi_hexdecode__fail
    lda test_zi_hexdecode__out+0
    cmp #$DE
    bne test_zi_hexdecode__fail
    lda test_zi_hexdecode__out+1
    cmp #$AD
    bne test_zi_hexdecode__fail
    lda test_zi_hexdecode__out+2
    cmp #$BE
    bne test_zi_hexdecode__fail
    lda test_zi_hexdecode__out+3
    cmp #$EF
    bne test_zi_hexdecode__fail
    lda test_zi_hexdecode__out+4
    cmp #$01
    bne test_zi_hexdecode__fail
    lda test_zi_hexdecode__out+5                  ; one past the run: untouched
    bne test_zi_hexdecode__fail
    lda #0
    bra test_zi_hexdecode__report
test_zi_hexdecode__fail
    lda #1
test_zi_hexdecode__report
    ldx #<test_zi_hexdecode__name
    ldy #>test_zi_hexdecode__name
    jmp t_result
test_zi_hexdecode__name dta c'ZI_HEXDECODE', 0
test_zi_hexdecode__hex  dta c'DEADBEEF01'
test_zi_hexdecode__out
    :(8) dta 0

; ---------------------------------------------------------------------
; zi_cmd is the transmit half of the AT-command exchange: it must frame
; the line and return (the reply-reading half needs a real board). Under
; the emulated UART the send completes, so this pins the TX path and that
; the routine does not hang -- a stuck THRE poll would trip the harness.
test_zi_cmd
    lda #<SER_BAUD_9600
    sta X16_P0
    lda #>SER_BAUD_9600
    sta X16_P1
    lda #<U0
    ldx #>U0
    jsr ser_init                ; select UART 0
    lda #<test_zi_cmd__cmd
    ldx #>test_zi_cmd__cmd
    jsr zi_cmd                  ; "ati" + CR/LF -> transmit, then returns
    lda #0
    ldx #<test_zi_cmd__name
    ldy #>test_zi_cmd__name
    jmp t_result
test_zi_cmd__name dta c'ZI_CMD', 0
test_zi_cmd__cmd  dta c'ati', 0

; ---------------------------------------------------------------------
; The xm_* macros expand to exactly the hand-written argument setup + jsr,
; so this both proves they work and (via the 7-way PRG hash) that they
; convert byte-identically. xm_ser_init is checked through the register
; oracle; xm_zi_hexdecode against a known vector.
test_serial_sugar
    xm_ser_init U0,SER_BAUD_9600  ; macro form of ser_init on UART 0
    lda U0_LCR
    cmp #$03
    bne test_serial_sugar__fail
    lda U0_MCR
    cmp #$27
    bne test_serial_sugar__fail
    ; pass plain (global) labels to the macro: a cheap-local passed as a
    ; macro argument does not resolve inside the expansion on 64tass.
    xm_zi_hexdecode sugar_hex,4,sugar_out  ; "BEEF" -> BE EF
    cmp #2
    bne test_serial_sugar__fail
    lda sugar_out+0
    cmp #$BE
    bne test_serial_sugar__fail
    lda sugar_out+1
    cmp #$EF
    bne test_serial_sugar__fail
    lda #0
    bra test_serial_sugar__report
test_serial_sugar__fail
    lda #1
test_serial_sugar__report
    ldx #<test_serial_sugar__name
    ldy #>test_serial_sugar__name
    jmp t_result
test_serial_sugar__name dta c'SERIAL_SUGAR', 0
sugar_hex dta c'BEEF'
sugar_out
    :(4) dta 0

; ---------------------------------------------------------------------
    icl "test_mads/testlib.asm"
    icl "x16_code.asm"
