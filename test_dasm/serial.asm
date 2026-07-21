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

    processor 65c02
    include "x16.asm"

X16_USE_SERIAL = 1
X16_USE_SERIAL_ZIMODEM = 1      ; the WiFi/ESP32 layer (pulls SERIAL)

    include "core/sugar.asm"        ; optional friendly xm_* macros (tested below)

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

    SUBROUTINE
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
    SUBROUTINE
test_ser_detect
    jsr ser_detect
    bcs .fail                   ; carry clear = at least one found
    cmp #2                      ; A = count
    bne .fail
    lda ser_u0                  ; first at $9F60
    cmp #<U0
    bne .fail
    lda ser_u0+1
    cmp #>U0
    bne .fail
    lda ser_u1                  ; second at $9F68
    cmp #<U1
    bne .fail
    lda ser_u1+1
    cmp #>U1
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SER_DETECT", 0

; ---------------------------------------------------------------------
; ser_init programs 8N1 (LCR $03), auto-flow (MCR $27) and the 9600-baud
; divisor ($0060). Read every one of those straight off the chip.
; ---------------------------------------------------------------------
    SUBROUTINE
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
    bne .fail
    lda U0_MCR                  ; DTR+RTS+auto-flow+OUT2
    cmp #$27
    bne .fail
    lda #$80                    ; raise DLAB to see the divisor latch
    sta U0_LCR
    lda U0                      ; DLL = low byte of $0060
    cmp #$60
    bne .fail
    lda U0_IER                  ; DLM = high byte of $0060
    cmp #$00
    bne .fail
    lda #$03                    ; put the line back the way init left it
    sta U0_LCR
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SER_INIT", 0

; ---------------------------------------------------------------------
; A divisor with a non-zero high byte proves ser_init writes DLM as well
; as DLL. $0180 is the 2400-baud divisor.
; ---------------------------------------------------------------------
    SUBROUTINE
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
    bne .fail
    lda U0_IER                  ; DLM = $01
    cmp #$01
    bne .fail
    lda #$03
    sta U0_LCR
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SER_BAUD16", 0

; ---------------------------------------------------------------------
; ser_init remembers which UART it was handed: initialise the second one
; and confirm its own LCR took the setting.
; ---------------------------------------------------------------------
    SUBROUTINE
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
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SER_SELECT", 0

; ---------------------------------------------------------------------
; With nothing feeding the receive FIFO, ser_avail must say "nothing"
; and ser_get must return empty rather than block.
; ---------------------------------------------------------------------
    SUBROUTINE
test_ser_rx_empty
    lda #<SER_BAUD_9600
    sta X16_P0
    lda #>SER_BAUD_9600
    sta X16_P1
    lda #<U0
    ldx #>U0
    jsr ser_init

    jsr ser_avail               ; carry set would mean a phantom byte
    bcs .fail
    jsr ser_get                 ; must report empty (carry set), not hang
    bcc .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SER_RX_EMPTY", 0

; ---------------------------------------------------------------------
; ser_put: the transmit holding register reads empty, so the THRE
; handshake should complete and the call return (a stuck poll would trip
; the harness's timeout). Confirms the TX path is live.
; ---------------------------------------------------------------------
    SUBROUTINE
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
    beq .fail
    lda #'X
    jsr ser_put                 ; returns only if the handshake cleared
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SER_PUT", 0

; ---------------------------------------------------------------------
; ZiModem's hex-mode payload decoder is pure computation, so it has an
; independent oracle: feed known ASCII hex, check the packed bytes back.
; This is the one ZiModem routine the emulator can verify -- the rest of
; the protocol talks to an ESP32 that is not present headless.
    SUBROUTINE
test_zi_hexdecode
    lda #<.out                  ; destination pointer in P0/P1
    sta X16_P0
    lda #>.out
    sta X16_P1
    ldy #10                     ; "DEADBEEF01" = 10 digits -> 5 bytes
    lda #<.hex
    ldx #>.hex
    jsr zi_hexdecode
    cmp #5                      ; A = bytes produced
    bne .fail
    lda .out+0
    cmp #$DE
    bne .fail
    lda .out+1
    cmp #$AD
    bne .fail
    lda .out+2
    cmp #$BE
    bne .fail
    lda .out+3
    cmp #$EF
    bne .fail
    lda .out+4
    cmp #$01
    bne .fail
    lda .out+5                  ; one past the run: untouched
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "ZI_HEXDECODE", 0
.hex  dc.b "DEADBEEF01"
.out  ds 8, 0

; ---------------------------------------------------------------------
; zi_cmd is the transmit half of the AT-command exchange: it must frame
; the line and return (the reply-reading half needs a real board). Under
; the emulated UART the send completes, so this pins the TX path and that
; the routine does not hang -- a stuck THRE poll would trip the harness.
    SUBROUTINE
test_zi_cmd
    lda #<SER_BAUD_9600
    sta X16_P0
    lda #>SER_BAUD_9600
    sta X16_P1
    lda #<U0
    ldx #>U0
    jsr ser_init                ; select UART 0
    lda #<.cmd
    ldx #>.cmd
    jsr zi_cmd                  ; "ati" + CR/LF -> transmit, then returns
    lda #0
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "ZI_CMD", 0
.cmd  dc.b "ati", 0

; ---------------------------------------------------------------------
; The xm_* macros expand to exactly the hand-written argument setup + jsr,
; so this both proves they work and (via the 7-way PRG hash) that they
; convert byte-identically. xm_ser_init is checked through the register
; oracle; xm_zi_hexdecode against a known vector.
    SUBROUTINE
test_serial_sugar
    xm_ser_init U0, SER_BAUD_9600  ; macro form of ser_init on UART 0
    lda U0_LCR
    cmp #$03
    bne .fail
    lda U0_MCR
    cmp #$27
    bne .fail
    ; pass plain (global) labels to the macro: a cheap-local passed as a
    ; macro argument does not resolve inside the expansion on 64tass.
    xm_zi_hexdecode sugar_hex, 4, sugar_out  ; "BEEF" -> BE EF
    cmp #2
    bne .fail
    lda sugar_out+0
    cmp #$BE
    bne .fail
    lda sugar_out+1
    cmp #$EF
    bne .fail
    lda #0
    bra .report
.fail
    lda #1
.report
    ldx #<.name
    ldy #>.name
    jmp t_result
.name dc.b "SERIAL_SUGAR", 0
    SUBROUTINE
sugar_hex dc.b "BEEF"
    SUBROUTINE
sugar_out ds 4, 0

; ---------------------------------------------------------------------
    include "test_dasm/testlib.asm"
    include "x16_code.asm"
