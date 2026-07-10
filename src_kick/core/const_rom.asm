//ACME
// =====================================================================
// x16lib :: core/const_rom.asm -- ROM banks and their $C000 entry points
// =====================================================================
// Pure symbol file. Safe to !source any number of times.
//
// The audio and graphics APIs are NOT in the $FFxx KERNAL table. They
// live at $C000+ inside their own ROM bank and must be reached with
// +jsrfar (or +rom_call_fast). See core/macros.asm.
//
// Transcribed from x16-rom-r49/inc/banks.inc, audio.inc, graphics.inc.
// =====================================================================

#importonce

.label BANK_KERNAL = $00
.label BANK_KEYBD = $01
.label BANK_CBDOS = $02
.label BANK_FAT32 = $03
.label BANK_BASIC = $04
.label BANK_MONITOR = $05
.label BANK_CHARSET = $06
.label BANK_DIAG = $07
.label BANK_GRAPH = $08
.label BANK_DEMO = $09
.label BANK_AUDIO = $0A
.label BANK_UTIL = $0B
.label BANK_BANNEX = $0C
.label BANK_X16EDIT = $0D          // occupies two banks
.label BANK_BASLOAD = $0F

// ---------------------------------------------------------------------
// BANK_AUDIO entry points (x16-rom-r49/inc/audio.inc).
//
// ym_* / psg_* keep the ROM driver's volume and pan shadows coherent.
// Writing YM_REG/YM_DATA directly does not -- that is the AUDIOYM.TXT
// distinction between FMPOKE (via ROM) and YM! (raw).
// ---------------------------------------------------------------------
// (!addr block: .const assignments in KickAssembler)
.label rom_bas_fmfreq = $C000
.label rom_bas_fmnote = $C003
.label rom_bas_fmplaystring = $C006
.label rom_bas_fmvib = $C009
.label rom_bas_playstringvoice = $C00C
.label rom_bas_psgfreq = $C00F
.label rom_bas_psgnote = $C012
.label rom_bas_psgwav = $C015
.label rom_bas_psgplaystring = $C018
.label rom_notecon_bas2fm = $C01B
.label rom_notecon_bas2midi = $C01E
.label rom_notecon_bas2psg = $C021
.label rom_notecon_fm2bas = $C024
.label rom_notecon_fm2midi = $C027
.label rom_notecon_fm2psg = $C02A
.label rom_notecon_freq2bas = $C02D
.label rom_notecon_freq2fm = $C030
.label rom_notecon_freq2midi = $C033
.label rom_notecon_freq2psg = $C036
.label rom_notecon_midi2bas = $C039
.label rom_notecon_midi2fm = $C03C
.label rom_notecon_midi2psg = $C03F
.label rom_notecon_psg2bas = $C042
.label rom_notecon_psg2fm = $C045
.label rom_notecon_psg2midi = $C048
.label rom_psg_init = $C04B
.label rom_psg_playfreq = $C04E
.label rom_psg_read = $C051
.label rom_psg_setatten = $C054
.label rom_psg_setfreq = $C057
.label rom_psg_setpan = $C05A
.label rom_psg_setvol = $C05D
.label rom_psg_write = $C060
.label rom_ym_init = $C063
.label rom_ym_loaddefpatches = $C066
.label rom_ym_loadpatch = $C069
.label rom_ym_loadpatchlfn = $C06C
.label rom_ym_playdrum = $C06F
.label rom_ym_playnote = $C072
.label rom_ym_setatten = $C075
.label rom_ym_setdrum = $C078
.label rom_ym_setnote = $C07B
.label rom_ym_setpan = $C07E
.label rom_ym_read = $C081
.label rom_ym_release = $C084
.label rom_ym_trigger = $C087
.label rom_ym_write = $C08A
.label rom_bas_fmchordstring = $C08D
.label rom_bas_psgchordstring = $C090
.label rom_psg_getatten = $C093
.label rom_psg_getpan = $C096
.label rom_ym_getatten = $C099
.label rom_ym_getpan = $C09C
.label rom_audio_init = $C09F
.label rom_psg_write_fast = $C0A2
.label rom_ym_get_chip_type = $C0A5
// (end addr)

// ---------------------------------------------------------------------
// BANK_BASIC floating-point jump table.
//
// The ROM ships a C128/C65-compatible FP library. Its jump table sits at
// $FE00 inside BANK_BASIC (cfg/basic-x16.cfgtpl: FPJMP start = $FE00)
// and is a stable ABI -- unlike the implementation addresses in
// basic.sym, which move between ROM revisions.
//
// 52 entries. The six after fp_poly are compiled out (`const_rom_if 0` in
// math/jumptab.s) and read back as $AA fill. Do not call them.
//
// Everything operates on FAC, the floating accumulator in zero page.
// Pointer arguments are A = low byte, Y = high byte.
//
// CAUTION: fp_fsub and fp_fdiv are the reverse of what the comments in
// jumptab.s claim. Each does `jsr conupk` (ARG = mem) and then falls into
// the ARG-first form, so what you actually get is
//       fp_fsub:  FAC = mem - FAC          (NOT FAC - mem)
//       fp_fdiv:  FAC = mem / FAC
//       fp_fsubt: FAC = ARG - FAC
//       fp_fdivt: FAC = ARG / FAC
// util/float.asm wraps these back into the intuitive direction.
// ---------------------------------------------------------------------
// (!addr block: .const assignments in KickAssembler)
.label fp_ayint = $FE00       // facmo:faclo = (s16)FAC, high byte first
.label fp_givayf = $FE03       // FAC = (s16) A:Y        (A = high, Y = low)
.label fp_fout = $FE06       // FAC -> ASCIIZ at FP_FBUFFR; returns A/Y = ptr
.label fp_val = $FE09       // FAC = value of the string at X:Y, length A
.label fp_getadr = $FE0C       // A:Y = (u16)FAC         (A = high, Y = low)
.label fp_floatc = $FE0F
.label fp_fsub = $FE12       // FAC = mem(A,Y) - FAC
.label fp_fsubt = $FE15       // FAC = ARG - FAC
.label fp_fadd = $FE18       // FAC = FAC + mem(A,Y)
.label fp_faddt = $FE1B       // FAC = FAC + ARG
.label fp_fmult = $FE1E       // FAC = FAC * mem(A,Y)
.label fp_fmultt = $FE21       // FAC = FAC * ARG
.label fp_fdiv = $FE24       // FAC = mem(A,Y) / FAC
.label fp_fdivt = $FE27       // FAC = ARG / FAC
.label fp_log = $FE2A       // FAC = ln(FAC)
.label fp_int = $FE2D       // FAC = int(FAC)
.label fp_sqr = $FE30       // FAC = sqrt(FAC)
.label fp_negop = $FE33       // FAC = -FAC  (the real unary minus)
.label fp_fpwr = $FE36       // FAC = mem(A,Y) ^ FAC
.label fp_fpwrt = $FE39       // FAC = ARG ^ FAC
.label fp_exp = $FE3C       // FAC = e ^ FAC
.label fp_cos = $FE3F       // destroys ARG
.label fp_sin = $FE42       // destroys ARG
.label fp_tan = $FE45       // destroys ARG
.label fp_atn = $FE48       // destroys ARG
.label fp_round = $FE4B
.label fp_abs = $FE4E       // FAC = |FAC|
.label fp_sign = $FE51       // A = sgn(FAC): $FF, 0 or 1
.label fp_fcomp = $FE54       // A = compare FAC with mem(A,Y): $FF, 0 or 1
.label fp_rnd = $FE57
.label fp_conupk = $FE5A       // ARG = mem(A,Y)
.label fp_movfm = $FE60       // FAC = mem(A,Y)
.label fp_movmf = $FE66       // mem(X,Y) = round(FAC)  (X = low, Y = high)
.label fp_movfa = $FE69       // FAC = ARG
.label fp_movaf = $FE6C       // ARG = round(FAC)
.label fp_faddh = $FE6F       // FAC += 0.5
.label fp_zerofc = $FE72       // FAC = 0
.label fp_normal = $FE75
.label fp_negfac = $FE78       // CAUTION: not a negate. Internal helper of the
                        // add/subtract path: two's-complements the FAC
                        // mantissa in place, denormalising a normal FAC.
                        // Use fp_negop for -FAC.
.label fp_mul10 = $FE7B       // FAC *= 10
.label fp_div10 = $FE7E       // FAC /= 10
.label fp_movef = $FE81       // ARG = FAC
.label fp_sgn = $FE84       // FAC = sgn(FAC)
.label fp_float = $FE87       // FAC = (s8)A -- SIGNED: 200 comes out -56.
                        // For an unsigned byte go through fp_givayf
                        // with a zero high byte (util/float.asm does).
.label fp_floats = $FE8A       // FAC = (s16) facho:facho+1
.label fp_qint = $FE8D       // facho..faclo = (u32)FAC, most significant first
.label fp_finlog = $FE90       // FAC += (s8)A
.label fp_foutc = $FE93
.label fp_polyx = $FE96
.label fp_poly = $FE99
// (end addr)

// ---------------------------------------------------------------------
// The floating accumulator and argument, in BASIC's zero page.
//
// A float packed in memory is 5 bytes; unpacked in FAC it is 6, with the
// sign broken out into its own byte. Safe to disturb from a SYSed
// program, because BASIC is dormant while it runs.
// ---------------------------------------------------------------------
// (!addr block: .const assignments in KickAssembler)
.label FP_FAC = $C3
.label FP_FACEXP = $C3
.label FP_FACHO = $C4         // mantissa, most significant byte
.label FP_FACMOH = $C5
.label FP_FACMO = $C6
.label FP_FACLO = $C7         // mantissa, least significant byte
.label FP_FACSGN = $C8
.label FP_ARG = $CA
.label FP_ARGEXP = $CA
.label FP_ARGSGN = $CF
.label FP_FACOV = $D1
.label FP_FBUFFR = $0100       // fp_fout writes its ASCIIZ result here
// (end addr)

.label FP_SIZE = 5             // bytes of a packed float in memory

// ---------------------------------------------------------------------
// BANK_GRAPH entry points (x16-rom-r49/inc/graphics.inc).
// Most of these are also reachable through the $FFxx stubs in
// core/const_kernal.asm, which is the preferred route.
// ---------------------------------------------------------------------
// (!addr block: .const assignments in KickAssembler)
.label gr_GRAPH_clear = $C000
.label gr_GRAPH_draw_image = $C003
.label gr_GRAPH_draw_line = $C006
.label gr_GRAPH_draw_oval = $C009
.label gr_GRAPH_draw_rect = $C00C
.label gr_GRAPH_init = $C00F
.label gr_GRAPH_move_rect = $C012
.label gr_GRAPH_set_colors = $C015
.label gr_GRAPH_set_window = $C018
.label gr_GRAPH_get_char_size = $C01B
.label gr_GRAPH_put_char = $C01E
.label gr_GRAPH_set_font = $C021
.label gr_font_init = $C024
.label gr_console_init = $C027
.label gr_console_put_char = $C02A
.label gr_console_get_char = $C02D
.label gr_console_put_image = $C030
.label gr_console_set_paging_message = $C033
.label gr_set_window_fullscreen = $C036
.label gr_FB_init = $C039
.label gr_FB_get_info = $C03C
.label gr_FB_set_palette = $C03F
.label gr_default_palette = $C063
// (end addr)
