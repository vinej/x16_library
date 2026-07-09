;ACME
; =====================================================================
; x16lib :: storage/load.asm -- load and save
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Device 8 is the SD card. Filenames are (address, length), not
; NUL-terminated.
;
; The KERNAL's secondary address decides where a load goes:
;   0  load to the address you pass in X/Y, ignoring the file's header
;   1  load to the address in the file's own two-byte PRG header
;   2  load into VRAM bank 0 at the address you pass
;   3  load into VRAM bank 1 at the address you pass
; =====================================================================

!zone x16_load {

FS_SA_ADDR   = 0                ; load at the caller's address
FS_SA_HEADER = 1                ; load at the address in the PRG header
FS_SA_VRAM0  = 2
FS_SA_VRAM1  = 3

; ---------------------------------------------------------------------
; fs_setname -- in: X16_P0/P1 = filename address, A = length
; ---------------------------------------------------------------------
fs_setname
    ldx X16_P0
    ldy X16_P1
    jmp SETNAM

; ---------------------------------------------------------------------
; fs_load -- load a file
;   in:  X16_P0/P1 = filename address
;        X16_P2    = filename length
;        X16_P3    = device (usually 8)
;        X16_P4    = secondary address (FS_SA_*)
;        X16_P5/P6 = destination address (ignored when SA = 1)
;   out: carry clear on success; carry set with A = KERNAL error code
;        X/Y = address one past the last byte loaded
; ---------------------------------------------------------------------
fs_load
    lda X16_P2
    jsr fs_setname

    lda #1                      ; logical file number
    ldx X16_P3                  ; device
    ldy X16_P4                  ; secondary address
    jsr SETLFS

    lda #0                      ; 0 = load (1 would verify)
    ldx X16_P5
    ldy X16_P6
    jmp LOAD

; ---------------------------------------------------------------------
; fs_save -- save a block of memory as a PRG
;   in:  X16_P0/P1 = filename address
;        X16_P2    = filename length
;        X16_P3    = device
;        X16_P5/P6 = start address
;        X16_T6/T7 is used as the zero-page pointer KERNAL SAVE requires
;   out: carry clear on success; carry set with A = KERNAL error code
;
;   The end address is one past the last byte, and is passed in X/Y by
;   the caller through X16_P4 (low) -- see below.
; ---------------------------------------------------------------------
; fs_save wants five 16-bit-ish things and the parameter block is eight
; bytes, so the end address goes in T6/T7 rather than squeezing P7.
;   X16_P5/P6 = start, X16_T6/T7 = end (exclusive)
fs_save
    lda X16_P2
    jsr fs_setname

    lda #1
    ldx X16_P3
    ldy #0                      ; secondary 0: no PRG-header relocation
    jsr SETLFS

    lda X16_P5                  ; SAVE takes the start address through a
    sta X16_T4                  ; zero-page pointer, given by its address
    lda X16_P6
    sta X16_T5

    lda #X16_T4                 ; A = zero-page offset of the pointer
    ldx X16_T6                  ; X/Y = end address, exclusive
    ldy X16_T7
    jmp SAVE

; ---------------------------------------------------------------------
; fs_vload -- load straight into VRAM
;   in:  X16_P0/P1 = filename address
;        X16_P2    = filename length
;        X16_P3    = device
;        X16_P4    = VRAM bank (0 or 1)
;        X16_P5/P6 = VRAM address within that bank
;   out: as fs_load
; ---------------------------------------------------------------------
fs_vload
    lda X16_P4
    and #$01
    clc
    adc #FS_SA_VRAM0            ; bank 0 -> SA 2, bank 1 -> SA 3
    sta X16_P4
    jmp fs_load

}   ; !zone x16_load
