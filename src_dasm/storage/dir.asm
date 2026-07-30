;ACME
; =====================================================================
; x16lib :: storage/dir.asm -- reading a directory
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; A drive hands its directory over as a BASIC program listing, which is
; a peculiar thing to have to parse but is what every CBM drive does:
;
;       load address (2)
;       link (2)  blocks (2)  text... $00      <- one entry
;       link (2)  blocks (2)  text... $00
;       $00 $00                                <- end
;
; The "line number" is the block count, and the text carries the name in
; quotes followed by its type:
;
;       "GAME.PRG"        PRG
;       "LEVELS"          DIR
;
; These routines walk that so a caller never sees it:
;
;       +xm_dir_open path, path_len, 8
;       bcs no_directory
; loop  +xm_dir_next namebuf, 40
;       bcc done                  ; carry CLEAR at the end of the listing
;       jsr dir_type              ; A = DIR_TYPE_PRG, _DIR, ...
;       ...
;       bra loop
; done  jsr dir_close
;
; The header line comes back as DIR_TYPE_HOST and the trailing "BLOCKS
; FREE." line as DIR_TYPE_NONE with an empty name, rather than being
; hidden -- a file browser wants to skip them, a disk info panel wants
; to show them, and this way neither has to re-parse anything.
; =====================================================================

; (zone: file scope in dasm)

DIR_LFN = 3                     ; logical file: clear of fs_load's 1 and
                                ; of the command channel's 15

DIR_TYPE_NONE = 0               ; no name on the line: "BLOCKS FREE."
DIR_TYPE_PRG  = 1
DIR_TYPE_SEQ  = 2
DIR_TYPE_USR  = 3
DIR_TYPE_REL  = 4
DIR_TYPE_DIR  = 5
DIR_TYPE_HOST = 6               ; the header line naming the volume

    SUBROUTINE
dir_ty   dc.b 0
    SUBROUTINE
dir_blk  dc.w 0

    SUBROUTINE
dir_dollar
    dc.b "$"

; ---------------------------------------------------------------------
; dir_open -- open a directory for reading
;   in:  X16_P0/P1 = path address, X16_P2 = path length
;        (a length of 0 asks for "$", the current directory)
;        X16_P3    = device (usually 8)
;   out: carry set if the directory could not be opened
; ---------------------------------------------------------------------
    SUBROUTINE
dir_open
    lda X16_P2
    bne dir_named
    lda #1                      ; no path given: just "$"
    ldx #<dir_dollar
    ldy #>dir_dollar
    bra dir_setnam
    SUBROUTINE
dir_named
    ldx X16_P0
    ldy X16_P1
    SUBROUTINE
dir_setnam
    jsr SETNAM
    lda #DIR_LFN
    ldx X16_P3
    ldy #0                      ; secondary 0: the directory, not a file
    jsr SETLFS
    jsr OPEN
    bcs dir_nothing_open           ; the OPEN itself failed: nothing to undo
    ldx #DIR_LFN
    jsr CHKIN
    bcs dir_openbad
    jsr dir_getb                   ; the two load-address bytes, discarded
    bcs dir_openbad
    jsr dir_getb
    bcs dir_openbad
    clc
    rts

; Past the OPEN, DIR_LFN is live and the input channel may be pointing at
; it. Returning without this cleanup left the logical file claimed and the
; channel redirected, so every later dir_open answered FILE OPEN.
    SUBROUTINE
dir_openbad
    jsr CLRCHN
    lda #DIR_LFN
    jsr CLOSE
    SUBROUTINE
dir_nothing_open
    sec
    rts

; ---------------------------------------------------------------------
; dir_next -- read the next entry
;   in:  X16_P0/P1 = a buffer for the name, X16_P2 = its size (2-255)
;   out: carry SET if an entry was read, CLEAR at the end of the listing
;
; The name arrives NUL-terminated and truncated to fit -- the buffer
; size is honoured, so a long name cannot walk off the end of it.
; dir_type and dir_blocks then describe the entry just read.
; ---------------------------------------------------------------------
    SUBROUTINE
dir_next
    stz dir_ty                  ; DIR_TYPE_NONE until the line says more
    stz dir_blk
    stz dir_blk+1

    ldx #DIR_LFN                ; the caller may have used the channel
    jsr CHKIN                   ; in between, so re-select it every time
    bcs dir_no

    jsr dir_getb                   ; link
    bcs dir_no
    sta X16_T0
    jsr dir_getb
    bcs dir_no
    ora X16_T0
    beq dir_no                     ; a zero link is the end of the listing

    jsr dir_getb                   ; the line number is the block count
    bcs dir_no
    sta dir_blk
    jsr dir_getb
    bcs dir_no
    sta dir_blk+1

    stz X16_T1                  ; name bytes stored so far
    stz X16_T2                  ; 0 before the name, 1 inside, 2 after
    SUBROUTINE
dir_text
    jsr dir_getb
    bcs dir_endline                ; the file ended: keep what we have
    cmp #0
    beq dir_endline                ; and $00 ends the line properly
    ldx X16_T2
    cpx #1
    beq dir_inname
    cpx #2
    beq dir_after
    cmp #'"                    ; before the name: find the quote
    bne dir_text
    inc X16_T2
    bra dir_text

    SUBROUTINE
dir_inname
    cmp #'"                    ; the closing quote ends the name
    beq dir_closed
    ldx X16_T1
    inx
    cpx X16_P2                  ; room for this byte AND a terminator?
    bcs dir_text                   ; no: drop it, but keep parsing the type
    ldy X16_T1                  ; CHRIN is free to clobber Y, so load it
    sta (X16_P0),y              ; here rather than holding it across
    inc X16_T1
    bra dir_text
    SUBROUTINE
dir_closed
    lda #2
    sta X16_T2
    bra dir_text

    SUBROUTINE
dir_after
    cmp #'                     ; the first non-space after the name is
    beq dir_text                   ; the type
    ldx dir_ty
    bne dir_text                   ; already classified this line
    jsr dir_classify
    bra dir_text

    SUBROUTINE
dir_endline
    ldy X16_T1
    lda #0
    sta (X16_P0),y              ; NUL-terminate within the buffer
    sec                         ; an entry was read
    rts
    SUBROUTINE
dir_no
    clc
    rts

; The first letter is enough: PRG, SEQ, USR, REL, DIR and HOST do not
; collide. A suffix like PRG< (locked) classifies the same way.
    SUBROUTINE
dir_classify
    cmp #'P
    beq dir_t_prg
    cmp #'S
    beq dir_t_seq
    cmp #'U
    beq dir_t_usr
    cmp #'R
    beq dir_t_rel
    cmp #'D
    beq dir_t_dir
    cmp #'H
    beq dir_t_host
    rts
    SUBROUTINE
dir_t_prg
    lda #DIR_TYPE_PRG
    bra dir_setty
    SUBROUTINE
dir_t_seq
    lda #DIR_TYPE_SEQ
    bra dir_setty
    SUBROUTINE
dir_t_usr
    lda #DIR_TYPE_USR
    bra dir_setty
    SUBROUTINE
dir_t_rel
    lda #DIR_TYPE_REL
    bra dir_setty
    SUBROUTINE
dir_t_dir
    lda #DIR_TYPE_DIR
    bra dir_setty
    SUBROUTINE
dir_t_host
    lda #DIR_TYPE_HOST
    SUBROUTINE
dir_setty
    sta dir_ty
    rts

; ---------------------------------------------------------------------
; dir_type -- what the entry dir_next just read is
;   out: A = DIR_TYPE_PRG, DIR_TYPE_DIR, DIR_TYPE_HOST, ...
; ---------------------------------------------------------------------
    SUBROUTINE
dir_type
    lda dir_ty
    rts

; ---------------------------------------------------------------------
; dir_blocks -- how big the entry dir_next just read is
;   out: X/Y = the block count the listing gave for it
; ---------------------------------------------------------------------
    SUBROUTINE
dir_blocks
    ldx dir_blk
    ldy dir_blk+1
    rts

; ---------------------------------------------------------------------
; dir_close -- finished with the directory
; ---------------------------------------------------------------------
    SUBROUTINE
dir_close
    jsr CLRCHN
    lda #DIR_LFN
    jmp CLOSE

; one byte from the directory channel; carry set if the stream ended
    SUBROUTINE
dir_getb
    jsr CHRIN
    sta X16_T3
    jsr READST
    cmp #0
    bne dir_getb_end
    lda X16_T3
    clc
    rts
    SUBROUTINE
dir_getb_end
    sec
    rts

; (end zone)
