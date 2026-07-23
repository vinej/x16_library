;ACME
; =====================================================================
; x16lib :: storage/iec.asm -- low-level IEC / serial bus wrappers
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; These are direct helpers for the classic Commodore serial bus / IEC
; KERNAL calls. Most programs should use FILEIO, LOAD, DOS, or BMX
; instead; this gate is for protocols that need explicit bus control.
;
; MACPTR and MCIOUT are X16 block transfers for the current channel:
;       A   = byte count, 0 lets the implementation choose
;       X/Y = destination/source pointer
;       X/Y = bytes transferred on return
;       C   = set when unsupported/error
; =====================================================================

; (zone: file scope in dasm)

IEC_CMD_DATA  = $60             ; secondary data channel command base
IEC_CMD_CLOSE = $E0             ; close channel command base
IEC_CMD_OPEN  = $F0             ; open channel command base

; --- raw KERNAL wrappers ---------------------------------------------
    SUBROUTINE
iec_listen
    jmp LISTEN                  ; A = device number

    SUBROUTINE
iec_talk
    jmp TALK                    ; A = device number

    SUBROUTINE
iec_second
    jmp SECOND                  ; A = secondary/listen command byte

    SUBROUTINE
iec_tksa
    jmp TKSA                    ; A = secondary/talk command byte

    SUBROUTINE
iec_ciout
    jmp CIOUT                   ; A = byte to send

    SUBROUTINE
iec_acptr
    jmp ACPTR                   ; out: A = byte received

    SUBROUTINE
iec_unlisten
    jmp UNLSN

    SUBROUTINE
iec_untalk
    jmp UNTLK

    SUBROUTINE
iec_set_timeout
    jmp SETTMO                  ; A = timeout control (ROM r49 is a no-op)

    SUBROUTINE
iec_readst
    jmp READST                  ; out: A = serial/KERNAL status

    SUBROUTINE
iec_macptr
    jmp MACPTR                  ; block read: A=count, X/Y=dest

    SUBROUTINE
iec_mciout
    jmp MCIOUT                  ; block write: A=count, X/Y=source

; ---------------------------------------------------------------------
; iec_open_channel -- LISTEN device, send OPEN secondary command
;   in: A = device number, Y = secondary channel
; ---------------------------------------------------------------------
    SUBROUTINE
iec_open_channel
    jsr LISTEN
    tya
    ora #IEC_CMD_OPEN
    jmp SECOND

; ---------------------------------------------------------------------
; iec_data_channel -- LISTEN device, send DATA secondary command
;   in: A = device number, Y = secondary channel
; ---------------------------------------------------------------------
    SUBROUTINE
iec_data_channel
    jsr LISTEN
    tya
    ora #IEC_CMD_DATA
    jmp SECOND

; ---------------------------------------------------------------------
; iec_talk_channel -- TALK device, send DATA secondary command
;   in: A = device number, Y = secondary channel
; ---------------------------------------------------------------------
    SUBROUTINE
iec_talk_channel
    jsr TALK
    tya
    ora #IEC_CMD_DATA
    jmp TKSA

; ---------------------------------------------------------------------
; iec_close_channel -- LISTEN device, send CLOSE secondary command
;   in: A = device number, Y = secondary channel
; ---------------------------------------------------------------------
    SUBROUTINE
iec_close_channel
    jsr LISTEN
    tya
    ora #IEC_CMD_CLOSE
    jmp SECOND

; (end zone)
