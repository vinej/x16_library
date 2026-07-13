;dasm
; =====================================================================
; x16lib :: core/macros.asm -- inlined plumbing (dasm port)
; =====================================================================
; dasm port of the ACME macro layer. dasm macros take positional
; parameters ({1}, {2}, ...) rather than ACME's named `.param`, and use
; MAC/ENDM with IF/ELSE/ENDIF. ACME's `^` bank-byte operator becomes
; `>> 16`; its `>>>` logical shift becomes `>>` (operands are unsigned).
; ACME's compile-time !error asserts are dropped -- dasm has no direct
; equivalent and the callers here pass valid arguments.
;
; Requires processor 65c02 (trb/tsb).
; =====================================================================

; ---------------------------------------------------------------------
; vera_addrsel port      select which data port the ADDR registers refer
;                        to (ADDRSEL is bit 0 of CTRL). trb/tsb preserve
;                        DCSEL (bits 6:1).
; ---------------------------------------------------------------------
    MAC vera_addrsel
    lda #VERA_CTRL_ADDRSEL
    IF {1} = 0
    trb VERA_CTRL               ; clear bit 0
    ELSE
    tsb VERA_CTRL               ; set bit 0
    ENDIF
    ENDM

; ---------------------------------------------------------------------
; vera_dcsel n           select the $9F29-$9F2C register bank (0-63).
;                        Preserves ADDRSEL. Never writes bit 7.
; ---------------------------------------------------------------------
    MAC vera_dcsel
    lda VERA_CTRL
    and #VERA_CTRL_ADDRSEL
    ora #(({1}) << 1)
    sta VERA_CTRL
    ENDM

; ---------------------------------------------------------------------
; vera_addr port, addr, inc     point a data port at a 17-bit VRAM
;                               address. `inc` is a VERA_INC_* index.
; ---------------------------------------------------------------------
    MAC vera_addr
    vera_addrsel {1}
    lda #<({2})
    sta VERA_ADDR_L
    lda #>({2})
    sta VERA_ADDR_M
    lda #(((({2}) >> 16) & VERA_ADDR_H_BANK) | (({3}) << 4))
    sta VERA_ADDR_H
    ENDM

; Same, but decrementing.
    MAC vera_addr_decr
    vera_addrsel {1}
    lda #<({2})
    sta VERA_ADDR_L
    lda #>({2})
    sta VERA_ADDR_M
    lda #(((({2}) >> 16) & VERA_ADDR_H_BANK) | VERA_ADDR_H_DECR | (({3}) << 4))
    sta VERA_ADDR_H
    ENDM

; ---------------------------------------------------------------------
; vpoke addr, value      one-off VRAM byte write. Clobbers A, flags.
; ---------------------------------------------------------------------
    MAC vpoke
    vera_addr 0, {1}, VERA_INC_0
    lda #({2})
    sta VERA_DATA0
    ENDM

; ---------------------------------------------------------------------
; Bank registers.
; ---------------------------------------------------------------------
    MAC set_rambank
    lda #({1})
    sta RAM_BANK
    ENDM

    MAC set_rombank
    lda #({1})
    sta ROM_BANK
    ENDM

; ---------------------------------------------------------------------
; jsrfar addr, bank      call a routine in another ROM/RAM bank via the
;                        KERNAL's JSRFAR ($FF6E) mechanism.
; ---------------------------------------------------------------------
    MAC jsrfar
    jsr JSRFAR
    dc.w {1}
    dc.b {2}
    ENDM

; ---------------------------------------------------------------------
; rom_call_fast bank, entry     ~40 cycles cheaper than jsrfar, but it
;                               CLOBBERS A and leaves ROM_BANK = bank.
; ---------------------------------------------------------------------
    MAC rom_call_fast
    lda #({1})
    sta ROM_BANK
    jsr {2}
    ENDM

; ---------------------------------------------------------------------
; i16_const dest, value     load a 16-bit literal into a 2-byte
;                           little-endian buffer.
; ---------------------------------------------------------------------
    MAC i16_const
    lda #<({2})
    sta {1}
    lda #>({2})
    sta {1}+1
    ENDM

; ---------------------------------------------------------------------
; i32_const dest, value     load a 32-bit literal into a 4-byte
;                           little-endian buffer.
; ---------------------------------------------------------------------
    MAC i32_const
    lda #<({2})
    sta {1}
    lda #>({2})
    sta {1}+1
    lda #<((({2}) >> 16))
    sta {1}+2
    lda #<((({2}) >> 24))
    sta {1}+3
    ENDM

; ---------------------------------------------------------------------
; basic_stub                emit `10 SYS 2061` so the PRG autoruns.
;                           Must be at $0801; code begins at $080D.
; ---------------------------------------------------------------------
    MAC basic_stub
    dc.w $080B                  ; link to the end-of-program marker
    dc.w 10                     ; line number
    dc.b $9E                    ; SYS token
    dc.b "2061"                 ; = $080D
    dc.b $00                    ; end of line
    dc.w $0000                  ; end of program
    ENDM
