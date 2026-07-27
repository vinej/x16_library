;ACME
; =====================================================================
; x16lib :: ui/filepick.asm -- a file browser on a panel
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; A directory panel with a mouse and a keyboard: scrolling, descent into
; folders, and one question answered -- which file? The caller does the
; rest. It is the same browser in every program that opens it, which is
; the point: one set of keys, one look, one copy.
;
;       +xm_fp_filter pattern          ; what to list
;       jsr fp_open                    ; A = FPK_NONE / FPK_PICK / FPK_ALT
;       cmp #FPK_PICK
;       bne @nothing
;       jsr fp_path                    ; X/Y = the absolute path
;
; ...or, from a BANKED filepick, fp_copy_path / fp_copy_name into your
; own buffer: a pointer this module returns names its own storage, which
; travels into the bank with it and is not mapped once the wrapper has
; switched back.
;       ...
; @nothing
;       jsr fp_close
;
; THE FILTER is a list of patterns separated by ';':
;
;       "*.prg"             programs
;       "*.bmx;*.png"       either kind of picture
;       "*.*"               every file, whatever it is called
;
; Directories are always listed whatever the filter says, or there would
; be no way to reach the file you wanted. Matching folds case: a drive
; answers in ASCII and a pattern in a PETSCII source is written
; lower-case, and clearing bit 5 lands either on the other.
;
; fp_primary sets a SECOND pattern for callers that list everything but
; can only act on some of it -- a launcher lists "*.*" with a primary of
; "*.prg", and anything else is marked [dat] and can be handed to a
; program rather than run.
;
; WHY THIS IS WORTH BANKING: it is around 3 KB, and a program only needs
; it while the panel is up. -Bank it and the whole browser leaves low
; RAM, wrappers and all; the caller pays for the wrapper it calls.
;
; THE ENTRY CACHE is 64 entries of 40 bytes in a RAM bank -- fp_cache
; says where, and $A400 in bank 63 is the default. The bank is paged in
; while the panel is up and the caller's own bank is restored by
; fp_close.
;
; SAVE-UNDER: a launcher repaints itself when the panel closes and does
; not care what was underneath. A spreadsheet does. fp_saveunder keeps
; the covered characters and colours in a bank and puts them back --
; about 5.7 KB of an 8 KB bank at 80 columns.
; =====================================================================

!zone x16_filepick {

FPK_NONE   = 0                   ; cancelled: ESC, Run/Stop, or the x box
FPK_PICK   = 1                   ; a file was chosen: fp_path has it
FPK_ALT    = 2                   ; the second gesture: right click, or 'a'
FPK_HERE   = 3                   ; 'h': this DIRECTORY, not a file in it

FPK_ESIZE  = 40                  ; one cache entry: type, then the name
FPK_ETYPE  = 0
FPK_ENAME  = 1
FPK_MAXENT = 64
FPK_NOBANK = 255                 ; fp_saveunder: keep nothing
FPK_PTOP   = 3                   ; the panel's first row
FPK_DBLCLK = 30                  ; jiffies: half a second

; ---- configuration ---------------------------------------------------
fp_vram     !word $2000     ; the listing: VRAM, not banked RAM
fp_vramh    !byte $01       ; ...$12000 by default, clear of the text map
fp_filt     !word 0             ; 0 means "*.*"
fp_prim     !word 0             ; 0 means "the same as the filter"
fp_head     !word 0             ; 0 means "files in "
fp_foot     !word 0
fp_apanel   !byte $F6           ; blue on light grey
fp_abar     !byte $F6
fp_asel     !byte $6F           ; inverted
fp_under    !word $4000     ; the save-under, also VRAM: $14000
fp_underh   !byte $01
fp_undon    !byte 0         ; 0 = keep nothing
fp_chset    !byte 3             ; PET upper/lower; 255 leaves it alone
fp_startat  !word 0             ; 0 means "/"

; ---- state -----------------------------------------------------------
fp_curdir   !fill 64
fp_full     !fill 64
fp_nm       !fill 40
fp_nent     !byte 0
fp_sel      !byte 0
fp_top      !byte 0
fp_down     !byte 0
fp_lastck   !word 0
fp_lastidx  !byte 255
fp_rows     !byte 40
fp_left     !byte 6
fp_wide     !byte 68
fp_scrw     !byte 80
fp_scrh     !byte 60
fp_bankwas  !byte 0
fp_saved    !byte 0
fp_pass     !byte 0
fp_act      !byte 0
fp_key      !byte 0
fp_row      !byte 0
fp_idx      !byte 0
fp_attr     !byte 0
fp_cnt      !byte 0
fp_tmp      !byte 0
fp_tmp2     !byte 0
fp_kind     !byte 0         ; an entry's type, which .ent must not eat
fp_src      !word 0             ; scratch pointers, kept out of the ZP
fp_dst      !word 0             ; block so a library call cannot eat them
fp_pat      !word 0
fp_ptr      !word 0

.root       !text "/", 0
.headdef    !text "files in ", 0
.alldef     !text "*.*", 0
.footdef    !text "double click opens   esc closes", 0
.dirtag     !text "[dir] ", 0
.dattag     !text "[dat] ", 0
.blanktag   !text "      ", 0
.closebox   !text " x ", 0
.dotdot     !text "..", 0

; =====================================================================
; configuration
; =====================================================================

; ---------------------------------------------------------------------
; fp_cache -- where the listing is held
;   in: X16_P0/P1 = VRAM address (low 16 bits), X16_P2 = bit 16
;
; 2,560 bytes of VRAM, not RAM: a banked filepick runs from the $A000
; window, so reaching its own data through a RAM bank would page its own
; code away. The default is $12000, clear of the text map at $1B000.
; ---------------------------------------------------------------------
fp_cache
    lda X16_P0
    sta fp_vram
    lda X16_P1
    sta fp_vram+1
    lda X16_P2
    and #$01
    sta fp_vramh
    rts

; ---------------------------------------------------------------------
; fp_filter -- which files to list, as a ';' list of "*.ext" patterns
;   in: X16_P0/P1 = the pattern string, NUL-terminated
; ---------------------------------------------------------------------
fp_filter
    lda X16_P0
    sta fp_filt
    lda X16_P1
    sta fp_filt+1
    rts

; ---------------------------------------------------------------------
; fp_primary -- which of the listed files the caller can act on itself
;   in: X16_P0/P1 = the pattern string, NUL-terminated
;
; Anything listed that does NOT match is marked [dat] in the panel, and
; fp_is_primary reports which kind was chosen.
; ---------------------------------------------------------------------
fp_primary
    lda X16_P0
    sta fp_prim
    lda X16_P1
    sta fp_prim+1
    rts

; ---------------------------------------------------------------------
; fp_style -- the panel's colours
;   in: A = panel, X = header/footer, Y = the selected row
; ---------------------------------------------------------------------
fp_style
    sta fp_apanel
    stx fp_abar
    sty fp_asel
    rts

; ---------------------------------------------------------------------
; fp_heading -- the text in front of the path on the header row
;   in: X16_P0/P1 = the string, NUL-terminated
; ---------------------------------------------------------------------
fp_heading
    lda X16_P0
    sta fp_head
    lda X16_P1
    sta fp_head+1
    rts

; ---------------------------------------------------------------------
; fp_footing -- the reminder along the bottom of the panel
;   in: X16_P0/P1 = the string, NUL-terminated
; ---------------------------------------------------------------------
fp_footing
    lda X16_P0
    sta fp_foot
    lda X16_P1
    sta fp_foot+1
    rts

; ---------------------------------------------------------------------
; fp_saveunder -- keep what the panel covers, and put it back on close
;   in: A = 0 for none, non-zero to keep it
;       X16_P0/P1 = VRAM address (low 16 bits), X16_P2 = bit 16
;
; The text map is VRAM, so its copy lives in VRAM too: 5,712 bytes at 80
; columns, $14000 by default. A launcher that repaints itself does not
; need this; a spreadsheet does.
; ---------------------------------------------------------------------
fp_saveunder
    sta fp_undon
    beq .sv_off
    lda X16_P0
    sta fp_under
    lda X16_P1
    sta fp_under+1
    lda X16_P2
    and #$01
    sta fp_underh
.sv_off
    rts

; ---------------------------------------------------------------------
; fp_charset -- the charset the panel is drawn in (3 = PET upper/lower)
;   in: A = charset number, or 255 to leave whatever the caller had
;
; There is no way to ask the KERNAL which charset is loaded, so the
; browser cannot put back what it does not know: a caller using the
; graphics set should pass 255 and draw its own.
; ---------------------------------------------------------------------
fp_charset
    sta fp_chset
    rts

; ---------------------------------------------------------------------
; fp_start_dir -- where the browser opens
;   in: X16_P0/P1 = the path, NUL-terminated (the default is "/")
; ---------------------------------------------------------------------
fp_start_dir
    lda X16_P0
    sta fp_startat
    lda X16_P1
    sta fp_startat+1
    rts

; =====================================================================
; what the caller reads back
; =====================================================================

; ---------------------------------------------------------------------
; fp_path -- the absolute path of the chosen entry
;   out: X/Y = a pointer to it, NUL-terminated
;
; ONLY SAFE UNBANKED. This module's storage moves with the module: put
; it in a RAM bank with -Bank and the pointer names an address in a bank
; that is no longer mapped by the time the caller reads it. The caller
; sees whatever is in the window instead -- an empty string, if it is a
; freshly cleared bank, which is how a perfectly good file arrived at
; the drive with no name at all.
;
; Use fp_copy_path / fp_copy_name / fp_copy_dir instead: they run with
; the module's bank paged in and copy into the CALLER's memory.
; ---------------------------------------------------------------------
fp_path
    ldx #<fp_full
    ldy #>fp_full
    rts

; ---------------------------------------------------------------------
; fp_name -- the chosen entry's name, without the directory
;   out: X/Y = a pointer into the path, NUL-terminated
; ---------------------------------------------------------------------
fp_name
    lda #<fp_full
    sta fp_ptr
    lda #>fp_full
    sta fp_ptr+1
    ldy #0
.nm_scan
    lda fp_full,y
    beq .nm_done
    cmp #'/'
    bne .nm_next
    ; the character after this slash starts the name
    tya
    sec
    adc #<fp_full               ; sec: +1 as well, for the slash itself
    sta fp_ptr
    lda #>fp_full
    adc #0
    sta fp_ptr+1
.nm_next
    iny
    bne .nm_scan
.nm_done
    ldx fp_ptr
    ldy fp_ptr+1
    rts

; ---------------------------------------------------------------------
; fp_dir -- the directory being browsed, which is where the drive is
;           left standing
;   out: X/Y = a pointer to it, NUL-terminated
; ---------------------------------------------------------------------
fp_dir
    ldx #<fp_curdir
    ldy #>fp_curdir
    rts

; ---------------------------------------------------------------------
; fp_copy_path -- the absolute path, copied into the caller's memory
;   in:  X16_P0/P1 = destination, X16_P2 = its size (the NUL included)
;   out: A = how many characters were copied, terminator aside
;
; This is the one to use from a BANKED filepick: the copy happens with
; the module's bank paged in, and lands somewhere the caller can still
; read afterwards.
; ---------------------------------------------------------------------
fp_copy_path
    lda #<fp_full
    sta fp_src
    lda #>fp_full
    sta fp_src+1
    bra .copy_out

; ---------------------------------------------------------------------
; fp_copy_name -- just the name, without the directory
;   in:  X16_P0/P1 = destination, X16_P2 = its size
;   out: A = how many characters were copied
; ---------------------------------------------------------------------
fp_copy_name
    jsr fp_name
    stx fp_src
    sty fp_src+1
    bra .copy_out

; ---------------------------------------------------------------------
; fp_copy_dir -- the directory being browsed, which is where the drive
;                was left standing
;   in:  X16_P0/P1 = destination, X16_P2 = its size
;   out: A = how many characters were copied
; ---------------------------------------------------------------------
fp_copy_dir
    lda #<fp_curdir
    sta fp_src
    lda #>fp_curdir
    sta fp_src+1
.copy_out
    lda X16_P0
    sta fp_dst
    lda X16_P1
    sta fp_dst+1
    lda X16_P2
    beq .co_none
    dec                         ; leave room for the terminator
    jsr .put_str
    tya                         ; .put_str leaves Y = the length
    rts
.co_none
    lda #0
    rts

; ---------------------------------------------------------------------
; fp_is_primary -- is the chosen entry one the caller can act on?
;   out: carry set when it matches the primary pattern
; ---------------------------------------------------------------------
fp_is_primary
    jsr fp_name
    stx X16_P0
    sty X16_P1
    jsr .primpat
    sta X16_P2
    stx X16_P3
    jmp fp_match

; ---------------------------------------------------------------------
; fp_panel_top / fp_panel_left / fp_panel_width / fp_panel_rows
;   out: A = the panel's geometry, for a caller drawing inside it
;
; Valid once fp_open has run: the panel is sized to the screen it finds.
; ---------------------------------------------------------------------
fp_panel_top
    lda #FPK_PTOP
    rts

fp_panel_left
    lda fp_left
    rts

fp_panel_width
    lda fp_wide
    rts

fp_panel_rows
    lda fp_rows
    rts

; =====================================================================
; matching
; =====================================================================

; ---------------------------------------------------------------------
; fp_match -- does a name match a ';' list of patterns?
;   in:  X16_P0/P1 = the name, X16_P2/P3 = the pattern list
;   out: carry set when it matches
;
; A pattern list is "*.prg", or "*.bmx;*.png", or "*.*" for anything.
; A pattern pointer of $0000 matches everything, which is what an unset
; filter means.
; ---------------------------------------------------------------------
fp_match
    lda X16_P2
    ora X16_P3
    bne .m_have
    sec                         ; no pattern: everything matches
    rts
.m_have
    lda X16_P2
    sta fp_pat
    lda X16_P3
    sta fp_pat+1
.m_loop
    lda fp_pat
    sta X16_T0
    lda fp_pat+1
    sta X16_T1
    ldy #0
    lda (X16_T0),y
    beq .m_no                   ; end of the list, nothing matched
    jsr .match_one
    bcs .m_yes
    ; step past this pattern to the one after the ';'
.m_skip
    lda fp_pat
    sta X16_T0
    lda fp_pat+1
    sta X16_T1
    ldy #0
    lda (X16_T0),y
    beq .m_no
    cmp #';'
    beq .m_next
    inc fp_pat
    bne .m_skip
    inc fp_pat+1
    bra .m_skip
.m_next
    inc fp_pat
    bne .m_loop
    inc fp_pat+1
    bra .m_loop
.m_yes
    sec
    rts
.m_no
    clc
    rts

; One pattern, at fp_pat, against the name in X16_P0/P1.
;   out: carry set when it matches
.match_one
    lda fp_pat
    sta X16_T0
    lda fp_pat+1
    sta X16_T1
    ldy #0
    lda (X16_T0),y
    cmp #'*'
    beq .mo_star
    clc                         ; only "*..." patterns are understood
    rts
.mo_star
    ldy #1
    lda (X16_T0),y
    bne .hop1   ; "*"
    jmp .mo_all
.hop1
    cmp #';'
    bne .hop2   ; "*;..."
    jmp .mo_all
.hop2
    cmp #'.'
    beq .hop3
    jmp .mo_bad
.hop3
    ldy #2
    lda (X16_T0),y
    cmp #'*'
    bne .hop4   ; "*.*"
    jmp .mo_all
.hop4
    ; "*.ext": measure the extension, up to the next ';'
    lda fp_pat
    clc
    adc #2
    sta fp_src
    lda fp_pat+1
    adc #0
    sta fp_src+1
    ldy #0
.mo_extlen
    lda fp_src
    sta X16_T0
    lda fp_src+1
    sta X16_T1
    lda (X16_T0),y
    beq .mo_gotext
    cmp #';'
    beq .mo_gotext
    iny
    bne .mo_extlen
.mo_gotext
    cpy #0
    beq .mo_bad                 ; "*." on its own is not a pattern
    sty fp_cnt                  ; the extension's length

    ; the name's length
    lda X16_P0
    sta X16_T0
    lda X16_P1
    sta X16_T1
    ldy #0
.mo_namelen
    lda (X16_T0),y
    beq .mo_gotname
    iny
    bne .mo_namelen
.mo_gotname
    cpy fp_cnt                  ; a name has to be longer than ".ext"
    bcc .mo_bad
    beq .mo_bad
    tya
    sec
    sbc fp_cnt                  ; where the tail starts
    sta fp_tmp
    ; the character before the tail must be the dot
    tay
    dey
    lda (X16_T0),y
    cmp #'.'
    bne .mo_bad
    ; compare, folding case
    ldy #0
.mo_cmp
    cpy fp_cnt
    beq .mo_all
    lda X16_P0
    sta X16_T0
    lda X16_P1
    sta X16_T1
    tya
    clc
    adc fp_tmp
    tax                         ; index of this tail character
    txa
    tay
    lda (X16_T0),y
    jsr .fold
    sta fp_tmp2
    lda fp_src
    sta X16_T0
    lda fp_src+1
    sta X16_T1
    txa
    sec
    sbc fp_tmp
    tay
    lda (X16_T0),y
    jsr .fold
    cmp fp_tmp2
    bne .mo_bad
    iny
    bne .mo_cmp
.mo_all
    sec
    rts
.mo_bad
    clc
    rts

; A -> the same letter with bit 5 clear, whichever case it arrived in
.fold
    cmp #$41
    bcc .fd_out
    cmp #$5B
    bcc .fd_do
    cmp #$61
    bcc .fd_out
    cmp #$7B
    bcs .fd_out
.fd_do
    and #$DF
.fd_out
    rts

; -> A/X = the primary pattern, falling back to the filter, then to "*.*"
.primpat
    lda fp_prim
    ora fp_prim+1
    beq .pp_filt
    lda fp_prim
    ldx fp_prim+1
    rts
.pp_filt
    lda fp_filt
    ora fp_filt+1
    beq .pp_all
    lda fp_filt
    ldx fp_filt+1
    rts
.pp_all
    lda #<.alldef
    ldx #>.alldef
    rts

; -> A/X = the filter, or "*.*"
.filtpat
    lda fp_filt
    ora fp_filt+1
    beq .fp_all
    lda fp_filt
    ldx fp_filt+1
    rts
.fp_all
    lda #<.alldef
    ldx #>.alldef
    rts

; =====================================================================
; small helpers
; =====================================================================

; X16_P0/P1 = string -> Y = its length, terminator aside
.zlen
    lda X16_P0
    sta X16_T0
    lda X16_P1
    sta X16_T1
    ldy #0
.zl_loop
    lda (X16_T0),y
    beq .zl_done
    iny
    bne .zl_loop
.zl_done
    rts

; fp_src -> fp_dst, at most A characters, always terminated
.put_str
    sta fp_cnt
    ldy #0
.ps_loop
    cpy fp_cnt
    beq .ps_end
    lda fp_src
    sta X16_T0
    lda fp_src+1
    sta X16_T1
    lda (X16_T0),y
    beq .ps_end
    pha
    lda fp_dst
    sta X16_T0
    lda fp_dst+1
    sta X16_T1
    pla
    sta (X16_T0),y
    iny
    bne .ps_loop
.ps_end
    lda fp_dst
    sta X16_T0
    lda fp_dst+1
    sta X16_T1
    lda #0
    sta (X16_T0),y
    rts

; A = entry index: point VERA port 0 at that entry in the cache.
;
; The cache is in VRAM rather than in a RAM bank, and that is not a
; detail: a BANKED filepick runs from the $A000 window itself, so paging
; a bank in to reach its own data would page its own code away. VRAM is
; reachable from anywhere.
.ent
    sta fp_tmp
    stz fp_ptr
    stz fp_ptr+1
    lda fp_tmp                  ; index * 40 = index*32 + index*8
    sta fp_ptr
    asl fp_ptr                  ; *2
    rol fp_ptr+1
    asl fp_ptr                  ; *4
    rol fp_ptr+1
    asl fp_ptr                  ; *8
    rol fp_ptr+1
    lda fp_ptr
    sta fp_tmp2                 ; keep index*8
    lda fp_ptr+1
    sta fp_cnt
    asl fp_ptr                  ; *16
    rol fp_ptr+1
    asl fp_ptr                  ; *32
    rol fp_ptr+1
    clc
    lda fp_ptr
    adc fp_tmp2
    sta fp_ptr
    lda fp_ptr+1
    adc fp_cnt
    sta fp_ptr+1
    clc                         ; + the cache's own address
    lda fp_ptr
    adc fp_vram
    sta fp_ptr
    lda fp_ptr+1
    adc fp_vram+1
    sta fp_ptr+1
    ; fall through: point port 0 at fp_ptr, stepping by one
.point0
    stz VERA_CTRL               ; ADDRSEL 0
    lda fp_ptr
    sta VERA_ADDR_L
    lda fp_ptr+1
    sta VERA_ADDR_M
    lda fp_vramh
    and #$01
    ora #$10                    ; increment 1
    sta VERA_ADDR_H
    rts

; A = entry index: point port 0 at that entry's NAME
.ent_name
    jsr .ent
    clc
    lda fp_ptr
    adc #FPK_ENAME
    sta fp_ptr
    lda fp_ptr+1
    adc #0
    sta fp_ptr+1
    jmp .point0

; A = entry index -> A = its type, port 0 left just past it
.ent_type
    jsr .ent
    lda VERA_DATA0
    rts

; A = entry index: copy its name out of VRAM into fp_nm, so the rest of
; the code can treat it as an ordinary string.
.ent_fetch
    jsr .ent_name
    ldy #0
.ef_loop
    lda VERA_DATA0
    sta fp_nm,y
    beq .ef_done
    iny
    cpy #FPK_ESIZE-2
    bne .ef_loop
    lda #0
    sta fp_nm,y
.ef_done
    rts

; =====================================================================
; the listing
; =====================================================================

; Read the current directory into the cache: directories first, then
; whatever the primary pattern matches, then the rest. Three passes over
; the listing rather than a sort.
.read
    stz fp_nent
    stz fp_pass
.rd_pass
    stz X16_P0                  ; dir_open with no name: "$"
    stz X16_P1
    stz X16_P2
    lda #8
    sta X16_P3
    jsr dir_open
    bcc .hop5
    jmp .rd_done
.hop5
.rd_next
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    lda #40
    sta X16_P2
    jsr dir_next
    bcs .hop6
    jmp .rd_close
.hop6
    jsr dir_type
    sta fp_tmp                  ; the type the drive reported
    ; Not files. The header line is a path on an emulator's host
    ; filesystem (HOST) and the volume label on a real card (NONE, with
    ; raw directory bytes in the name), and the "BLOCKS FREE." trailer
    ; is NONE as well: listing either put rubbish in the panel.
    cmp #DIR_TYPE_NONE
    beq .rd_next
    cmp #DIR_TYPE_HOST
    beq .rd_next
    lda fp_nent
    cmp #FPK_MAXENT
    bcs .rd_next                ; the cache is full
    ; which pass wants this one?
    lda fp_tmp
    cmp #DIR_TYPE_DIR
    bne .rd_file
    lda fp_pass
    bne .rd_next                ; directories belong to pass 0
    lda fp_nm                   ; "." leads nowhere
    cmp #'.'
    bne .rd_keep_dir
    lda fp_nm+1
    beq .rd_next
.rd_keep_dir
    lda #DIR_TYPE_DIR
    sta fp_kind
    bra .rd_store
.rd_file
    lda fp_pass
    beq .rd_next                ; files are passes 1 and 2
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    jsr .filtpat
    sta X16_P2
    stx X16_P3
    jsr fp_match
    bcc .rd_next                ; not ours to show at all
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    jsr .primpat
    sta X16_P2
    stx X16_P3
    jsr fp_match
    ; The carry says primary -- and the cmp below would destroy it, so
    ; put it somewhere that survives asking which pass this is. Without
    ; this the pass test read its own comparison's carry, every file
    ; came out primary, and nothing was ever marked [dat].
    lda #0
    rol                         ; 1 = primary, 0 = data
    sta fp_cnt
    lda fp_pass
    cmp #1
    bne .rd_datapass
    lda fp_cnt                  ; pass 1 keeps the primaries
    bne .rd_isprim
    jmp .rd_next
.rd_isprim
    lda #DIR_TYPE_PRG
    sta fp_kind
    bra .rd_store
.rd_datapass
    lda fp_cnt                  ; pass 2 keeps everything else
    beq .rd_isdata
    jmp .rd_next
.rd_isdata
    lda #DIR_TYPE_SEQ
    sta fp_kind
.rd_store
    lda fp_nent
    jsr .ent                    ; port 0 at the entry, stepping by one
    lda fp_kind
    sta VERA_DATA0              ; the type
    ldy #0                      ; ...then the name, terminator included
.rd_name
    lda fp_nm,y
    sta VERA_DATA0
    beq .rd_named
    iny
    cpy #FPK_ESIZE-2
    bne .rd_name
    lda #0
    sta VERA_DATA0
.rd_named
    inc fp_nent
    jmp .rd_next
.rd_close
    jsr dir_close
    inc fp_pass
    lda fp_pass
    cmp #3
    bcs .hop8
    jmp .rd_pass
.hop8
.rd_done
    rts

; fp_curdir + "/" + the name at X16_P0/P1 -> fp_full
.make_path
    lda X16_P0
    sta fp_src
    lda X16_P1
    sta fp_src+1
    ldy #0
.mp_dir
    lda fp_curdir,y
    beq .mp_slash
    sta fp_full,y
    iny
    cpy #40
    bne .mp_dir
.mp_slash
    cpy #0
    beq .mp_name
    dey
    lda fp_full,y
    iny
    cmp #'/'
    beq .mp_name
    lda #'/'
    sta fp_full,y
    iny
.mp_name
    sty fp_tmp                  ; where the name goes
    ldx #0
.mp_copy
    txa
    tay
    lda fp_src
    sta X16_T0
    lda fp_src+1
    sta X16_T1
    lda (X16_T0),y
    beq .mp_end
    ldy fp_tmp
    sta fp_full,y
    inc fp_tmp
    lda fp_tmp
    cmp #63
    bcs .mp_end
    inx
    bne .mp_copy
.mp_end
    ldy fp_tmp
    lda #0
    sta fp_full,y
    rts

; Where we are, kept by hand: ".." trims the last component, anything
; else appends one. The drive is not asked, because it answers with a
; volume label on a card and a path on an emulator.
.descend
    lda X16_P0
    sta fp_src
    lda X16_P1
    sta fp_src+1
    lda fp_src
    sta X16_T0
    lda fp_src+1
    sta X16_T1
    ldy #0
    lda (X16_T0),y
    cmp #'.'
    bne .ds_append
    iny
    lda (X16_T0),y
    cmp #'.'
    bne .ds_append
    iny
    lda (X16_T0),y
    bne .ds_append
    ; ".." -- back up over the last component
    ldy #0
.ds_len
    lda fp_curdir,y
    beq .ds_gotlen
    iny
    bne .ds_len
.ds_gotlen
    cpy #2
    bcc .ds_root
.ds_back
    dey
    beq .ds_root
    lda fp_curdir,y
    cmp #'/'
    bne .ds_back
    cpy #0
    bne .ds_cut
.ds_root
    lda #'/'
    sta fp_curdir
    lda #0
    sta fp_curdir+1
    rts
.ds_cut
    lda #0
    sta fp_curdir,y
    rts
.ds_append
    ldy #0
.ds_alen
    lda fp_curdir,y
    beq .ds_agot
    iny
    bne .ds_alen
.ds_agot
    cpy #0
    beq .ds_acopy
    dey
    lda fp_curdir,y
    iny
    cmp #'/'
    beq .ds_acopy
    lda #'/'
    sta fp_curdir,y
    iny
.ds_acopy
    sty fp_tmp
    ldx #0
.ds_aloop
    txa
    tay
    lda fp_src
    sta X16_T0
    lda fp_src+1
    sta X16_T1
    lda (X16_T0),y
    beq .ds_aend
    ldy fp_tmp
    sta fp_curdir,y
    inc fp_tmp
    lda fp_tmp
    cmp #63
    bcs .ds_aend
    inx
    bne .ds_aloop
.ds_aend
    ldy fp_tmp
    lda #0
    sta fp_curdir,y
    rts

; =====================================================================
; the panel
; =====================================================================
.layout
    jsr screen_get_mode
    cmp #0
    bne .ly_small
    lda #80
    sta fp_scrw
    lda #60
    sta fp_scrh
    lda #40
    sta fp_rows
    lda #6
    sta fp_left
    lda #68
    sta fp_wide
    rts
.ly_small
    lda #40
    sta fp_scrw
    lda #30
    sta fp_scrh
    lda #22
    sta fp_rows
    lda #1
    sta fp_left
    lda #38
    sta fp_wide
    rts

; A = row, X = colour: fill one row of the panel
.prow
    pha
    phx
    tax                         ; screen_addr wants X = row, Y = column
    ldy fp_left
    jsr screen_addr
    plx                         ; colour
    lda fp_wide
    ldy #' '
    jsr screen_blitfill
    pla
    rts

; X16_P0/P1 = text, A = colour, X = row, Y = column: blit a NUL string
.blitz
    sta fp_attr
    pha
    phy
    txa
    tax
    ply
    jsr screen_addr
    pla
    jsr .zlen                   ; Y = length
    cpy #0
    beq .bz_done
    tya
    ldx fp_attr
    jsr screen_blit
.bz_done
    rts

.draw
    ; ---- the header row ------------------------------------------
    lda #FPK_PTOP
    ldx fp_abar
    jsr .prow
    lda fp_head
    ora fp_head+1
    bne .dw_head
    lda #<.headdef
    sta X16_P0
    lda #>.headdef
    sta X16_P1
    bra .dw_headgo
.dw_head
    lda fp_head
    sta X16_P0
    lda fp_head+1
    sta X16_P1
.dw_headgo
    ldx #FPK_PTOP
    ldy fp_left
    iny
    jsr screen_addr
    jsr .zlen
    cpy #0
    beq .dw_path
    tya
    ldx fp_abar
    jsr screen_blit
.dw_path
    lda #<fp_curdir
    sta X16_P0
    lda #>fp_curdir
    sta X16_P1
    jsr .zlen
    tya
    ; a deep path must not run off the bar
    sta fp_tmp
    lda fp_wide
    sec
    sbc #14
    cmp fp_tmp
    bcs .dw_pathlen
    sta fp_tmp
.dw_pathlen
    lda fp_tmp
    beq .dw_close
    ldx fp_abar
    jsr screen_blit
.dw_close
    ldx #FPK_PTOP
    lda fp_left
    clc
    adc fp_wide
    sec
    sbc #3
    tay
    jsr screen_addr
    lda #<.closebox
    sta X16_P0
    lda #>.closebox
    sta X16_P1
    lda #3
    ldx #$F2                    ; red on light grey: click to close
    jsr screen_blit

    ; ---- the rows -------------------------------------------------
    stz fp_row
.dw_row
    lda fp_row
    cmp fp_rows
    bcc .hop9
    jmp .dw_foot
.hop9
    clc
    adc fp_top
    sta fp_idx
    ldx fp_apanel
    cmp fp_sel
    bne .dw_attr
    ldx fp_asel
.dw_attr
    stx fp_attr
    lda fp_row
    clc
    adc #FPK_PTOP+1
    ldx fp_attr
    jsr .prow
    lda fp_idx
    cmp fp_nent
    bcs .dw_next
    ; Read the entry out of VRAM FIRST. The cache and the screen are
    ; both reached through VERA port 0, and screen_addr points it at the
    ; screen -- fetching a name after that wrote the row into the cache
    ; instead of onto the display, and left the panel blank.
    lda fp_idx
    jsr .ent_type
    sta fp_kind                 ; .ent uses fp_tmp2 itself
    lda fp_idx
    jsr .ent_fetch              ; the name, into fp_nm
    lda fp_row
    clc
    adc #FPK_PTOP+1
    tax
    lda fp_left
    clc
    adc #2
    tay
    jsr screen_addr
    lda fp_kind
    cmp #DIR_TYPE_DIR
    bne .dw_notdir
    lda #<.dirtag
    ldx #>.dirtag
    bra .dw_tag
.dw_notdir
    cmp #DIR_TYPE_SEQ
    bne .dw_blanktag
    lda #<.dattag
    ldx #>.dattag
    bra .dw_tag
.dw_blanktag
    lda #<.blanktag
    ldx #>.blanktag
.dw_tag
    sta X16_P0
    stx X16_P1
    lda #6
    ldx fp_attr
    jsr screen_blit
    ; the name, clamped: a row that runs over wraps around the screen
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    jsr .zlen
    tya
    sta fp_tmp
    lda fp_wide
    sec
    sbc #10
    cmp fp_tmp
    bcs .dw_namelen
    sta fp_tmp
.dw_namelen
    lda fp_tmp
    beq .dw_next
    ldx fp_attr
    jsr screen_blit
.dw_next
    inc fp_row
    jmp .dw_row

    ; ---- the footer ------------------------------------------------
.dw_foot
    lda fp_rows
    clc
    adc #FPK_PTOP+1
    ldx fp_abar
    jsr .prow
    lda fp_foot
    ora fp_foot+1
    bne .dw_footset
    lda #<.footdef
    sta X16_P0
    lda #>.footdef
    sta X16_P1
    bra .dw_footgo
.dw_footset
    lda fp_foot
    sta X16_P0
    lda fp_foot+1
    sta X16_P1
.dw_footgo
    lda fp_rows
    clc
    adc #FPK_PTOP+1
    tax
    lda fp_left
    clc
    adc #1
    tay
    jsr screen_addr
    jsr .zlen
    cpy #0
    beq .dw_end
    tya
    sta fp_tmp
    lda fp_wide
    sec
    sbc #2
    cmp fp_tmp
    bcs .dw_footlen
    sta fp_tmp
.dw_footlen
    lda fp_tmp
    ldx fp_abar
    jsr screen_blit
.dw_end
    rts

; A = the key: move the selection
.move
    cmp #$91                    ; up
    bne .mv_down
    lda fp_sel
    beq .mv_clamp
    dec fp_sel
    bra .mv_clamp
.mv_down
    cmp #$11
    bne .mv_home
    lda fp_sel
    clc
    adc #1
    cmp fp_nent
    bcs .mv_clamp
    inc fp_sel
    bra .mv_clamp
.mv_home
    cmp #$13
    bne .mv_clamp
    stz fp_sel
.mv_clamp
    lda fp_sel                  ; scrolled off the top?
    cmp fp_top
    bcs .mv_bottom
    sta fp_top
.mv_bottom
    lda fp_top                  ; ...or off the bottom?
    clc
    adc fp_rows
    cmp fp_sel
    beq .mv_scroll
    bcs .mv_out
.mv_scroll
    lda fp_sel
    sec
    sbc fp_rows
    clc
    adc #1
    sta fp_top
.mv_out
    rts

; =====================================================================
; save-under
;
; The text map IS VRAM, so keeping a copy of it somewhere else in VRAM
; costs nothing but the space: port 0 walks the screen, port 1 walks the
; scratch, and the bytes go across one at a time. A RAM bank would have
; been the obvious place and is the wrong one -- a banked filepick runs
; from the $A000 window, and paging a bank in there would page its own
; code out mid-copy.
;
; Two bytes per cell, (rows + 2) rows of the panel's width: 5,712 bytes
; at 80 columns.
; =====================================================================

; A = row: point port 1 at that row's copy in the scratch area
.under_addr
    sta fp_tmp
    stz fp_dst
    stz fp_dst+1
    lda fp_tmp
    beq .ua_have
    ldx fp_tmp
.ua_loop
    clc
    lda fp_dst
    adc fp_wide
    sta fp_dst
    lda fp_dst+1
    adc #0
    sta fp_dst+1
    dex
    bne .ua_loop
.ua_have
    asl fp_dst                  ; two bytes per cell
    rol fp_dst+1
    clc
    lda fp_dst
    adc fp_under
    sta fp_dst
    lda fp_dst+1
    adc fp_under+1
    sta fp_dst+1
    lda #1
    sta VERA_CTRL               ; ADDRSEL 1
    lda fp_dst
    sta VERA_ADDR_L
    lda fp_dst+1
    sta VERA_ADDR_M
    lda fp_underh
    and #$01
    ora #$10                    ; increment 1
    sta VERA_ADDR_H
    stz VERA_CTRL               ; back to port 0 for the caller
    rts

.save_under
    lda fp_undon
    bne .su_go1
    rts
.su_go1
    stz fp_row
.su_row
    lda fp_row
    cmp fp_rows
    bcc .su_go
    beq .su_go
    sec                         ; rows + 2: the header and the footer
    sbc fp_rows
    cmp #2
    bcc .su_go
    lda #1
    sta fp_saved
    rts
.su_go
    lda fp_row
    clc
    adc #FPK_PTOP
    tax
    ldy fp_left
    jsr screen_addr             ; port 0 at the screen row
    lda fp_row
    jsr .under_addr             ; port 1 at its copy
    lda fp_wide
    asl                         ; two bytes per cell
    sta fp_cnt
.su_cell
    lda VERA_DATA0
    sta VERA_DATA1
    dec fp_cnt
    bne .su_cell
    inc fp_row
    bra .su_row

.restore_under
    lda fp_undon
    bne .ru_go1
    rts
.ru_go1
    lda fp_saved
    bne .ru_go2
    rts
.ru_go2
    stz fp_row
.ru_row
    lda fp_row
    cmp fp_rows
    bcc .ru_go
    beq .ru_go
    sec
    sbc fp_rows
    cmp #2
    bcc .ru_go
    stz fp_saved
    rts
.ru_go
    lda fp_row
    clc
    adc #FPK_PTOP
    tax
    ldy fp_left
    jsr screen_addr
    lda fp_row
    jsr .under_addr
    lda fp_wide
    asl
    sta fp_cnt
.ru_cell
    lda VERA_DATA1
    sta VERA_DATA0
    dec fp_cnt
    bne .ru_cell
    inc fp_row
    bra .ru_row

; =====================================================================
; opening, closing, and the loop between
; =====================================================================

; ---------------------------------------------------------------------
; fp_open -- put the panel up on the starting directory
;   out: A = FPK_NONE (cancelled), FPK_PICK (a file), FPK_ALT (the
;        second gesture on a file: right click, or 'a'), FPK_HERE ('h':
;        the directory being shown, for "save into...")
;
; FPK_HERE is for a caller that wants a PLACE rather than a file. The
; drive is left standing in that directory whatever the answer, so a
; bare filename written afterwards lands there and fp_copy_dir names it.
; Without it ESC has to double as "use this one", and then there is no
; way left to mean "cancel".
;
; The chosen path is fp_path either way it ended on a file. Call
; fp_close when done with it -- that is what puts back the screen and
; the caller's RAM bank.
; ---------------------------------------------------------------------
fp_open
    jsr .layout
    stz fp_saved
    lda fp_startat
    ora fp_startat+1
    bne .op_start
    lda #<.root
    sta X16_P0
    lda #>.root
    sta X16_P1
    bra .op_setdir
.op_start
    lda fp_startat
    sta X16_P0
    lda fp_startat+1
    sta X16_P1
.op_setdir
    lda X16_P0
    sta fp_src
    lda X16_P1
    sta fp_src+1
    lda #<fp_curdir
    sta fp_dst
    lda #>fp_curdir
    sta fp_dst+1
    lda #63
    jsr .put_str
    lda fp_src                  ; and take the drive there
    sta X16_P0
    lda fp_src+1
    sta X16_P1
    jsr .zlen                   ; Y = length
    lda X16_P0                  ; dos_chdir wants A/X = name, Y = length
    ldx X16_P1
    jsr dos_chdir
    stz fp_sel
    stz fp_top
    lda #255
    sta fp_lastidx
    lda fp_chset
    cmp #255
    beq .op_nochar
    jsr screen_charset
.op_nochar
    jsr .save_under
    jsr .read
    lda #1                      ; the pointer, with the panel's bounds
    ldx fp_scrw
    ldy fp_scrh
    jsr mse_config
    lda #1                      ; the click that opened us may still be held
    sta fp_down
    jmp .loop

; ---------------------------------------------------------------------
; fp_resume -- the same panel again, same directory, same selection
;   out: A = as fp_open
;
; For a caller that acted on an FPK_ALT and wants the browser back.
; ---------------------------------------------------------------------
fp_resume
    lda #1
    ldx fp_scrw
    ldy fp_scrh
    jsr mse_config
    lda #1
    sta fp_down
    jmp .loop

; ---------------------------------------------------------------------
; fp_close -- put back what the panel covered and the caller's RAM bank
;
; The DRIVE is left in the directory that was being browsed: a caller
; that needs to be somewhere else should say so with dos_chdir.
; ---------------------------------------------------------------------
fp_close
    jsr .restore_under
    jmp mse_hide

; ---------------------------------------------------------------------
; fp_redraw -- paint the panel again, after a caller has drawn over it
; ---------------------------------------------------------------------
fp_redraw
    jmp .draw

.loop
    jsr .draw
.lp_input
    stz fp_key
    stz fp_act
.lp_poll
    jsr key_get
    sta fp_key
    beq .hop10
    ; The KERNAL answers in PETSCII, where an unshifted letter is $41-$5A
    ; -- the codes ASCII uses for CAPITALS -- and a shifted one is
    ; $C1-$DA. ACME's 'n' is $6E, which the keyboard never sends, so
    ; every letter command in here was dead until this fold.
    cmp #$C1
    bcc .kf_done
    cmp #$DB
    bcs .kf_done
    sec
    sbc #$80
    sta fp_key
.kf_done
    jmp .lp_act
.hop10
    jsr mse_get
    and #3                      ; left (1) and right (2)
    sta fp_tmp
    bne .lp_press
    stz fp_down                 ; released
    bra .lp_poll
.lp_press
    lda fp_down
    bne .lp_poll                ; still the same press
    lda #1
    sta fp_down
    ; which cell is under the pointer?
    lda X16_P2                  ; y, in pixels
    lsr X16_P3
    ror
    lsr X16_P3
    ror
    lsr X16_P3
    ror
    sta fp_row                  ; the text row
    lda X16_P0                  ; x
    lsr X16_P1
    ror
    lsr X16_P1
    ror
    lsr X16_P1
    ror
    sta fp_tmp2                 ; the text column
    ; the x box on the header row closes, like ESC
    lda fp_row
    cmp #FPK_PTOP
    bne .lp_rows
    lda fp_left
    clc
    adc fp_wide
    sec
    sbc #3
    cmp fp_tmp2
    bcs .lp_poll
    lda #$1B
    sta fp_key
    jmp .lp_act
.lp_rows
    lda fp_row
    cmp #FPK_PTOP+1
    bcc .lp_poll
    sec
    sbc #FPK_PTOP+1
    sta fp_row                  ; the line within the list
    cmp fp_rows
    bcs .lp_poll
    clc
    adc fp_top
    cmp fp_nent
    bcc .fk1677
    jmp .lp_poll
.fk1677
    sta fp_idx
    sta fp_sel
    lda fp_tmp
    and #2
    beq .lp_left
    ; RIGHT button: the ALT gesture
    lda #3
    sta fp_act
    lda #255
    sta fp_lastidx
    bra .lp_act
.lp_left
    jsr clock_get_timer         ; A/X = the low 16 bits of the jiffy clock
    sta fp_tmp
    stx fp_tmp2
    lda fp_idx
    cmp fp_lastidx
    bne .lp_single
    sec                         ; how long since the last click here?
    lda fp_tmp
    sbc fp_lastck
    sta fp_cnt
    lda fp_tmp2
    sbc fp_lastck+1
    bne .lp_single              ; more than 255 jiffies ago
    lda fp_cnt
    cmp #FPK_DBLCLK
    bcs .lp_single
    lda #1                      ; double click
    sta fp_act
    lda #255
    sta fp_lastidx
    bra .lp_act
.lp_single
    lda fp_tmp
    sta fp_lastck
    lda fp_tmp2
    sta fp_lastck+1
    lda fp_idx
    sta fp_lastidx
    lda #2                      ; select only
    sta fp_act
.lp_act
    lda fp_act
    cmp #2
    bne .hop11   ; selection moved: redraw and carry on
    jmp .loop
.hop11
    cmp #3
    bne .lp_key
    ; the ALT gesture, which only makes sense on a file
    lda fp_sel
    jsr .ent_type
    cmp #DIR_TYPE_DIR
    beq .lp_again
    jsr .path_of_sel
    lda #FPK_ALT
    rts
.lp_again
    lda #1
    sta fp_down
    jmp .loop
.lp_key
    lda fp_act
    cmp #1
    bne .lp_haskey
    lda #$0D                    ; a double click is Enter
    sta fp_key
.lp_haskey
    lda fp_key
    cmp #'H'                    ; "the folder I am looking at"
    bne .lp_nothere
    lda #FPK_HERE
    rts
.lp_nothere
!ifdef X16_USE_FILEPICK_EDIT {
    lda fp_key
    cmp #'N'
    bne .lp_note1
    jmp .ed_newdir
.lp_note1
    cmp #'E'                    ; not 'r': that already runs/picks
    bne .lp_note2
    jmp .ed_rename
.lp_note2
    cmp #'D'
    bne .lp_note3
    jmp .ed_delete
.lp_note3
    cmp #'C'
    bne .lp_note4
    jmp .ed_copy
.lp_note4
    cmp #'V'
    bne .lp_note5
    jmp .ed_paste
.lp_note5
}
    lda fp_key
    cmp #$1B
    bne .hop12
    jmp .lp_none
.hop12
    cmp #$03
    bne .hop13
    jmp .lp_none
.hop13
    cmp #$91
    bne .hop14
    jmp .lp_move
.hop14
    cmp #$11
    bne .hop15
    jmp .lp_move
.hop15
    cmp #$13
    beq .lp_move
    lda fp_nent
    bne .hop16   ; nothing to act on
    jmp .lp_input
.hop16
    lda fp_sel
    jsr .ent_type
    cmp #DIR_TYPE_DIR
    bne .lp_file
    lda fp_key
    cmp #$0D
    beq .hop17
    jmp .lp_input
.hop17
    ; descend: the drive first, then our own idea of where we are
    lda fp_sel
    jsr .ent_fetch
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    jsr .zlen                   ; Y = length
    lda #<fp_nm                 ; A/X = name, Y = length
    ldx #>fp_nm
    jsr dos_chdir
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    jsr .descend
    stz fp_sel
    stz fp_top
    jsr .read
    jmp .loop
.lp_file
    lda fp_key
    cmp #$0D
    beq .lp_pick
    cmp #'R'
    beq .lp_pick
    cmp #'A'
    beq .hop18
    jmp .lp_input
.hop18
    jsr .path_of_sel
    lda #FPK_ALT
    rts
.lp_pick
    jsr .path_of_sel
    lda #FPK_PICK
    rts
.lp_move
    lda fp_key
    jsr .move
    jmp .loop
.lp_none
    lda #FPK_NONE
    rts

!ifdef X16_USE_FILEPICK_EDIT {
; =====================================================================
; managing what is in the panel, rather than only choosing from it
;
;   n  make a folder        c  remember a file  (copy)
;   e  rename               v  write it here    (paste)
;   d  delete
;
; Gated on its own: a program that only wants to ask "which file?" --
; imgview does -- should not carry mkdir and delete to get it.
;
; Every one of these ends by re-reading the directory, so the panel is
; never showing something the drive no longer has.
; =====================================================================
fp_clip     !fill 64            ; the file 'c' remembered, absolute
fp_clipok   !byte 0
fp_buf      !fill 256           ; what a copy moves at a time
fp_elen     !byte 0             ; length of the text being edited

.s_newdir   !text "new folder: ", 0
.s_rename   !text "rename to: ", 0
.s_delete   !text "delete? y/n: ", 0
.s_swr      !text ",s,w", 0

; Edit fp_nm in place on the panel's first row. X16_P0/P1 = the label.
;   out: carry set when Enter was pressed with something in the field
.ed_prompt
    lda X16_P0
    sta fp_src
    lda X16_P1
    sta fp_src+1
.ep_draw
    lda #FPK_PTOP+1
    ldx fp_abar
    jsr .prow
    ldx #FPK_PTOP+1
    ldy fp_left
    iny
    jsr screen_addr
    lda fp_src
    sta X16_P0
    lda fp_src+1
    sta X16_P1
    jsr .zlen
    tya
    ldx fp_abar
    jsr screen_blit
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    lda fp_elen
    beq .ep_cursor
    ldx fp_abar
    jsr screen_blit
.ep_cursor
    lda #<.s_cursor
    sta X16_P0
    lda #>.s_cursor
    sta X16_P1
    lda #1
    ldx fp_abar
    jsr screen_blit
    jsr key_wait
    cmp #$0D
    beq .ep_enter
    cmp #$1B
    beq .ep_cancel
    cmp #$03
    beq .ep_cancel
    cmp #$14                    ; backspace
    bne .ep_char
    lda fp_elen
    beq .ep_draw
    dec fp_elen
    ldy fp_elen
    lda #0
    sta fp_nm,y
    bra .ep_draw
.ep_char
    cmp #' '
    bcc .ep_draw
    cmp #$80
    bcs .ep_draw
    ldy fp_elen
    cpy #30
    bcs .ep_draw
    sta fp_nm,y
    inc fp_elen
    ldy fp_elen
    lda #0
    sta fp_nm,y
    jmp .ep_draw
.ep_enter
    lda fp_elen
    beq .ep_cancel
    sec
    rts
.ep_cancel
    clc
    rts

.s_cursor   !text "_", 0

; X16_P0/P1 = question -> carry set on y
.ed_confirm
    lda #FPK_PTOP+1
    ldx fp_abar
    jsr .prow
    ldx #FPK_PTOP+1
    ldy fp_left
    iny
    jsr screen_addr
    jsr .zlen
    tya
    ldx fp_abar
    jsr screen_blit
    jsr key_wait
    and #$DF                    ; either case
    cmp #'Y'
    beq .ec_yes
    clc
    rts
.ec_yes
    sec
    rts

; n -- make a folder here
.ed_newdir
    stz fp_nm
    stz fp_elen
    lda #<.s_newdir
    sta X16_P0
    lda #>.s_newdir
    sta X16_P1
    jsr .ed_prompt
    bcs .far1977
    jmp .ed_done
.far1977
    lda #<fp_nm
    ldx #>fp_nm
    ldy fp_elen
    jsr dos_mkdir
    jmp .ed_reread

; e -- rename the selected entry
.ed_rename
    lda fp_nent
    bne .far1987
    jmp .ed_done
.far1987
    lda fp_sel
    jsr .ent_fetch              ; the old name, into fp_nm
    lda #<fp_nm
    sta fp_src
    lda #>fp_nm
    sta fp_src+1
    lda #<fp_clip
    sta fp_dst
    lda #>fp_clip
    sta fp_dst+1
    lda #38
    jsr .put_str                ; keep it: the prompt edits fp_nm
    sty fp_clipok               ; ...and its length, borrowed for a moment
    ldy #0
.er_len
    lda fp_nm,y
    beq .er_gotlen
    iny
    bne .er_len
.er_gotlen
    sty fp_elen
    lda #<.s_rename
    sta X16_P0
    lda #>.s_rename
    sta X16_P1
    jsr .ed_prompt
    bcc .ed_clipreset
    lda #<fp_clip               ; old name
    sta X16_P0
    lda #>fp_clip
    sta X16_P1
    lda fp_clipok
    sta X16_P2
    lda #<fp_nm                 ; new name
    ldx #>fp_nm
    ldy fp_elen
    jsr dos_rename
.ed_clipreset
    stz fp_clipok               ; it was only borrowed
    jmp .ed_reread

; d -- delete the selected entry, folder or file
.ed_delete
    lda fp_nent
    beq .ed_done
    lda fp_sel
    jsr .ent_type
    sta fp_kind
    lda fp_sel
    jsr .ent_fetch
    ldy #0
.dl_len
    lda fp_nm,y
    beq .dl_gotlen
    iny
    bne .dl_len
.dl_gotlen
    sty fp_elen
    lda #<.s_delete
    sta X16_P0
    lda #>.s_delete
    sta X16_P1
    jsr .ed_confirm
    bcc .ed_done
    lda fp_kind
    cmp #DIR_TYPE_DIR
    beq .dl_dir
    lda #<fp_nm
    ldx #>fp_nm
    ldy fp_elen
    jsr dos_delete
    jmp .ed_reread
.dl_dir
    lda #<fp_nm
    ldx #>fp_nm
    ldy fp_elen
    jsr dos_rmdir
    jmp .ed_reread

; c -- remember the selected file
.ed_copy
    lda fp_nent
    beq .ed_done
    lda fp_sel
    jsr .ent_type
    cmp #DIR_TYPE_DIR
    beq .ed_done                ; folders are not copied, only their files
    jsr .path_of_sel            ; fp_full = the absolute path
    lda #<fp_full
    sta fp_src
    lda #>fp_full
    sta fp_src+1
    lda #<fp_clip
    sta fp_dst
    lda #>fp_clip
    sta fp_dst+1
    lda #62
    jsr .put_str
    lda #1
    sta fp_clipok
.ed_done
    jmp .loop

; v -- write the remembered file into the folder on show
.ed_paste
    lda fp_clipok
    beq .ed_done
    ; the destination name is the source's leaf, plus ",s,w" so the
    ; drive writes a sequential file rather than looking for a program
    lda #<fp_clip
    sta fp_src
    lda #>fp_clip
    sta fp_src+1
    ldy #0
    ldx #0
.pa_leaf
    lda fp_clip,y
    beq .pa_gotleaf
    cmp #'/'
    bne .pa_next
    iny
    tya
    tax                         ; x = where the leaf starts
    dey
.pa_next
    iny
    bne .pa_leaf
.pa_gotleaf
    txa
    tay
    ldx #0
.pa_copy
    lda fp_clip,y
    beq .pa_suffix
    sta fp_nm,x
    inx
    iny
    bne .pa_copy
.pa_suffix
    ldy #0
.pa_swr
    lda .s_swr,y
    beq .pa_named
    sta fp_nm,x
    inx
    iny
    bne .pa_swr
.pa_named
    stx fp_elen
    ; source: the absolute path, read on logical file 4
    lda #<fp_clip
    sta X16_P0
    lda #>fp_clip
    sta X16_P1
    ldy #0
.pa_slen
    lda fp_clip,y
    beq .pa_gotslen
    iny
    bne .pa_slen
.pa_gotslen
    sty X16_P2
    lda #4
    sta X16_P3
    lda #8
    sta X16_P4
    lda #2
    sta X16_P5
    jsr fio_open_read
    bcs .pa_failsrc
    ; destination on logical file 5, in whatever directory we are in
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    lda fp_elen
    sta X16_P2
    lda #5
    sta X16_P3
    lda #8
    sta X16_P4
    lda #2
    sta X16_P5
    jsr fio_open_write
    bcs .pa_faildst
.pa_block
    ldx #4                      ; read a block
    jsr CHKIN
    ldy #0
.pa_read
    jsr CHRIN
    sta fp_buf,y
    iny
    beq .pa_full                ; 256 bytes
    jsr READST
    beq .pa_read
    sty fp_cnt                  ; short block: the last one
    lda #1
    sta fp_tmp
    bra .pa_write
.pa_full
    sty fp_cnt                  ; 0 means 256
    stz fp_tmp
.pa_write
    ldx #5
    jsr CHKOUT
    ldy #0
.pa_out
    lda fp_buf,y
    jsr CHROUT
    iny
    cpy fp_cnt
    bne .pa_out
    lda fp_tmp
    beq .pa_block
    ; done
    jsr CLRCHN
    lda #5
    jsr CLOSE
    lda #4
    jsr CLOSE
    bra .ed_reread
.pa_faildst
    jsr CLRCHN
    lda #4
    jsr CLOSE
    jmp .loop
.pa_failsrc
    jsr CLRCHN
    lda #4
    jsr CLOSE
    jmp .loop

.ed_reread
    jsr .read
    stz fp_sel
    stz fp_top
    jmp .loop
}

; the selected entry's name -> fp_full, as an absolute path
.path_of_sel
    lda fp_sel
    jsr .ent_fetch
    lda #<fp_nm
    sta X16_P0
    lda #>fp_nm
    sta X16_P1
    jmp .make_path

}
