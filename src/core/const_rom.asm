;ACME
; =====================================================================
; x16lib :: core/const_rom.asm -- ROM banks and their $C000 entry points
; =====================================================================
; Pure symbol file. Safe to !source any number of times.
;
; The audio and graphics APIs are NOT in the $FFxx KERNAL table. They
; live at $C000+ inside their own ROM bank and must be reached with
; +jsrfar (or +rom_call_fast). See core/macros.asm.
;
; Transcribed from x16-rom-r49/inc/banks.inc, audio.inc, graphics.inc.
; =====================================================================

!ifdef X16_CONST_ROM !eof
X16_CONST_ROM = 1

BANK_KERNAL  = $00
BANK_KEYBD   = $01
BANK_CBDOS   = $02
BANK_FAT32   = $03
BANK_BASIC   = $04
BANK_MONITOR = $05
BANK_CHARSET = $06
BANK_DIAG    = $07
BANK_GRAPH   = $08
BANK_DEMO    = $09
BANK_AUDIO   = $0A
BANK_UTIL    = $0B
BANK_BANNEX  = $0C
BANK_X16EDIT = $0D          ; occupies two banks
BANK_BASLOAD = $0F

; ---------------------------------------------------------------------
; BANK_AUDIO entry points (x16-rom-r49/inc/audio.inc).
;
; ym_* / psg_* keep the ROM driver's volume and pan shadows coherent.
; Writing YM_REG/YM_DATA directly does not -- that is the AUDIOYM.TXT
; distinction between FMPOKE (via ROM) and YM! (raw).
; ---------------------------------------------------------------------
!addr {
rom_bas_fmfreq          = $C000
rom_bas_fmnote          = $C003
rom_bas_fmplaystring    = $C006
rom_bas_fmvib           = $C009
rom_bas_playstringvoice = $C00C
rom_bas_psgfreq         = $C00F
rom_bas_psgnote         = $C012
rom_bas_psgwav          = $C015
rom_bas_psgplaystring   = $C018
rom_notecon_bas2fm      = $C01B
rom_notecon_bas2midi    = $C01E
rom_notecon_bas2psg     = $C021
rom_notecon_fm2bas      = $C024
rom_notecon_fm2midi     = $C027
rom_notecon_fm2psg      = $C02A
rom_notecon_freq2bas    = $C02D
rom_notecon_freq2fm     = $C030
rom_notecon_freq2midi   = $C033
rom_notecon_freq2psg    = $C036
rom_notecon_midi2bas    = $C039
rom_notecon_midi2fm     = $C03C
rom_notecon_midi2psg    = $C03F
rom_notecon_psg2bas     = $C042
rom_notecon_psg2fm      = $C045
rom_notecon_psg2midi    = $C048
rom_psg_init            = $C04B
rom_psg_playfreq        = $C04E
rom_psg_read            = $C051
rom_psg_setatten        = $C054
rom_psg_setfreq         = $C057
rom_psg_setpan          = $C05A
rom_psg_setvol          = $C05D
rom_psg_write           = $C060
rom_ym_init             = $C063
rom_ym_loaddefpatches   = $C066
rom_ym_loadpatch        = $C069
rom_ym_loadpatchlfn     = $C06C
rom_ym_playdrum         = $C06F
rom_ym_playnote         = $C072
rom_ym_setatten         = $C075
rom_ym_setdrum          = $C078
rom_ym_setnote          = $C07B
rom_ym_setpan           = $C07E
rom_ym_read             = $C081
rom_ym_release          = $C084
rom_ym_trigger          = $C087
rom_ym_write            = $C08A
rom_bas_fmchordstring   = $C08D
rom_bas_psgchordstring  = $C090
rom_psg_getatten        = $C093
rom_psg_getpan          = $C096
rom_ym_getatten         = $C099
rom_ym_getpan           = $C09C
rom_audio_init          = $C09F
rom_psg_write_fast      = $C0A2
rom_ym_get_chip_type    = $C0A5
}

; ---------------------------------------------------------------------
; BANK_GRAPH entry points (x16-rom-r49/inc/graphics.inc).
; Most of these are also reachable through the $FFxx stubs in
; core/const_kernal.asm, which is the preferred route.
; ---------------------------------------------------------------------
!addr {
gr_GRAPH_clear                = $C000
gr_GRAPH_draw_image           = $C003
gr_GRAPH_draw_line            = $C006
gr_GRAPH_draw_oval            = $C009
gr_GRAPH_draw_rect            = $C00C
gr_GRAPH_init                 = $C00F
gr_GRAPH_move_rect            = $C012
gr_GRAPH_set_colors           = $C015
gr_GRAPH_set_window           = $C018
gr_GRAPH_get_char_size        = $C01B
gr_GRAPH_put_char             = $C01E
gr_GRAPH_set_font             = $C021
gr_font_init                  = $C024
gr_console_init               = $C027
gr_console_put_char           = $C02A
gr_console_get_char           = $C02D
gr_console_put_image          = $C030
gr_console_set_paging_message = $C033
gr_set_window_fullscreen      = $C036
gr_FB_init                    = $C039
gr_FB_get_info                = $C03C
gr_FB_set_palette             = $C03F
gr_default_palette            = $C063
}
