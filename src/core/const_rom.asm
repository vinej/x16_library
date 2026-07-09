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
bas_fmfreq          = $C000
bas_fmnote          = $C003
bas_fmplaystring    = $C006
bas_fmvib           = $C009
bas_playstringvoice = $C00C
bas_psgfreq         = $C00F
bas_psgnote         = $C012
bas_psgwav          = $C015
bas_psgplaystring   = $C018
notecon_bas2fm      = $C01B
notecon_bas2midi    = $C01E
notecon_bas2psg     = $C021
notecon_fm2bas      = $C024
notecon_fm2midi     = $C027
notecon_fm2psg      = $C02A
notecon_freq2bas    = $C02D
notecon_freq2fm     = $C030
notecon_freq2midi   = $C033
notecon_freq2psg    = $C036
notecon_midi2bas    = $C039
notecon_midi2fm     = $C03C
notecon_midi2psg    = $C03F
notecon_psg2bas     = $C042
notecon_psg2fm      = $C045
notecon_psg2midi    = $C048
psg_init            = $C04B
psg_playfreq        = $C04E
psg_read            = $C051
psg_setatten        = $C054
psg_setfreq         = $C057
psg_setpan          = $C05A
psg_setvol          = $C05D
psg_write           = $C060
ym_init             = $C063
ym_loaddefpatches   = $C066
ym_loadpatch        = $C069
ym_loadpatchlfn     = $C06C
ym_playdrum         = $C06F
ym_playnote         = $C072
ym_setatten         = $C075
ym_setdrum          = $C078
ym_setnote          = $C07B
ym_setpan           = $C07E
ym_read             = $C081
ym_release          = $C084
ym_trigger          = $C087
ym_write_rom        = $C08A
bas_fmchordstring   = $C08D
bas_psgchordstring  = $C090
psg_getatten        = $C093
psg_getpan          = $C096
ym_getatten         = $C099
ym_getpan           = $C09C
audio_init          = $C09F
psg_write_fast      = $C0A2
ym_get_chip_type    = $C0A5
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
