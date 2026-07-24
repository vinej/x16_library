; 64tass
; =====================================================================
; x16lib :: x16_code.asm -- the library routines (64tass edition)
; =====================================================================
; GENERATED from src_acme/x16_code.asm by tools/acme2tass.py -- do
; not edit by hand. 64tass selects modules by VALUE, not .ifdef
; definedness: each gate gets a .weak = 0 default, then xuse_*
; folds in the same dependency closure the ACME !ifdef gates
; encode. Add a gate in src_acme and it appears here on regen.
; =====================================================================

.weak
X16_USE_VERA = 0
X16_USE_VIDEO = 0
X16_USE_VERA_DC = 0
X16_USE_SCREEN = 0
X16_USE_PALETTE = 0
X16_USE_TILE = 0
X16_USE_SPRITE = 0
X16_USE_GRAPHICS = 0
X16_USE_BITMAP8L = 0
X16_USE_BITMAP8H = 0
X16_USE_BITMAP2H = 0
X16_USE_BITMAP2L = 0
X16_USE_BITMAP4L = 0
X16_USE_BITMAP4H = 0
X16_USE_FB = 0
X16_USE_GRAPH = 0
X16_USE_CONSOLE = 0
X16_USE_SHAPES = 0
X16_USE_SHAPES_POLY = 0
X16_USE_SHAPES_RRECT = 0
X16_USE_SHAPES_ARC = 0
X16_USE_SHAPES_PIE = 0
X16_USE_SHAPES_BEZIER = 0
X16_USE_VERAFX = 0
X16_USE_VERAFX_UTILS = 0
X16_USE_AUDIO = 0
X16_USE_PSG = 0
X16_USE_YM = 0
X16_USE_AUDIO_ROM = 0
X16_USE_ZSM = 0
X16_USE_ZSM_PCM = 0
X16_USE_PCM = 0
X16_USE_PCM_STREAM = 0
X16_USE_ADPCM = 0
X16_USE_WAV = 0
X16_USE_INPUT_DEVICES = 0
X16_USE_INPUT = 0
X16_USE_KEYBOARD = 0
X16_USE_MOUSE = 0
X16_USE_COMMUNICATIONS = 0
X16_USE_I2C = 0
X16_USE_VERA_SPI = 0
X16_USE_SERIAL = 0
X16_USE_SERIAL_ZIMODEM = 0
X16_USE_STORAGE = 0
X16_USE_BANK = 0
X16_USE_BANKALLOC = 0
X16_USE_STACK = 0
X16_USE_RINGBUFFER = 0
X16_USE_MEM = 0
X16_USE_FILEIO = 0
X16_USE_IEC = 0
X16_USE_LOAD = 0
X16_USE_DOS = 0
X16_USE_BMX = 0
X16_USE_UTILITIES = 0
X16_USE_MATH = 0
X16_USE_CLIP = 0
X16_USE_BUFFERS = 0
X16_USE_ZX0 = 0
X16_USE_TSC = 0
X16_USE_FIXED = 0
X16_USE_BCD = 0
X16_USE_COLLIDE = 0
X16_USE_BITS = 0
X16_USE_NUMBER = 0
X16_USE_INT16 = 0
X16_USE_INT32 = 0
X16_USE_FLOAT = 0
X16_USE_DOUBLE = 0
X16_USE_SORT = 0
X16_USE_STRINGS = 0
X16_USE_STRING = 0
X16_USE_STRING_CTYPE = 0
X16_USE_STRING_CASE = 0
X16_USE_STRING_FIND = 0
X16_USE_STRING_SLICE = 0
X16_USE_STRING_SORT = 0
X16_USE_SYSTEM = 0
X16_USE_IRQ = 0
X16_USE_CLOCK = 0
X16_USE_SHP_LINE = 0
X16_USE_VERAFX_FILL = 0
X16_USE_VERAFX_MULT = 0
X16_USE_VERAFX_COPY = 0
X16_USE_VERAFX_TRANSP = 0
X16_USE_VERAFX_AFFINE = 0
X16_USE_VERAFX_LINE = 0
X16_USE_VERAFX_TRI = 0
X16_USE_VERAFX_LINETRI = 0
X16_USE_VERA_CORE = 0
X16_USE_VERA_COPY = 0
X16_USE_VERA_ADDR = 0
X16_USE_VERA_FILL = 0
X16_USE_VERA_FXPROBE = 0
X16_USE_IRQ_CORE = 0
X16_USE_IRQ_REMOVE = 0
X16_USE_IRQ_VSYNC = 0
X16_USE_IRQ_SPRCOL = 0
X16_USE_IRQ_SPRCOL_API = 0
X16_USE_INPUT_CORE = 0
X16_USE_INPUT_KEYWAIT = 0
X16_USE_SCREEN_CORE = 0
X16_USE_SCREEN_EXTRA = 0
X16_BITMAP2L_NO_INIT = 0
X16_BITMAP4L_MIN = 0
X16_BITMAP4L_NO_INIT = 0
X16_BITMAP8L_MIN = 0
X16_BITMAP8L_NO_INIT = 0
X16_SKIP_BASE = 0
X16_SKIP_MATH = 0
X16_SKIP_SHAPES = 0
.endweak

; --- the dependency closure (generated from the ACME gates) ---
xuse_video = X16_USE_VIDEO != 0
xuse_graphics = X16_USE_GRAPHICS != 0
xuse_audio = X16_USE_AUDIO != 0
xuse_input_devices = X16_USE_INPUT_DEVICES != 0
xuse_communications = X16_USE_COMMUNICATIONS != 0
xuse_storage = X16_USE_STORAGE != 0
xuse_utilities = X16_USE_UTILITIES != 0
xuse_strings = X16_USE_STRINGS != 0
xuse_system = X16_USE_SYSTEM != 0
xuse_vera_dc = xuse_video || X16_USE_VERA_DC != 0
xuse_palette = xuse_video || X16_USE_PALETTE != 0
xuse_tile = xuse_video || X16_USE_TILE != 0
xuse_sprite = xuse_video || X16_USE_SPRITE != 0
xuse_bitmap8l = xuse_graphics || X16_USE_BITMAP8L != 0
xuse_bitmap8h = xuse_graphics || X16_USE_BITMAP8H != 0
xuse_bitmap2l = xuse_graphics || X16_USE_BITMAP2L != 0
xuse_bitmap4l = xuse_graphics || X16_USE_BITMAP4L != 0
xuse_bitmap4h = xuse_graphics || X16_USE_BITMAP4H != 0
xuse_fb = xuse_graphics || X16_USE_FB != 0
xuse_graph = xuse_graphics || X16_USE_GRAPH != 0
xuse_console = xuse_graphics || X16_USE_CONSOLE != 0
xuse_shapes_poly = xuse_graphics || X16_USE_SHAPES_POLY != 0
xuse_shapes_rrect = xuse_graphics || X16_USE_SHAPES_RRECT != 0
xuse_shapes_pie = xuse_graphics || X16_USE_SHAPES_PIE != 0
xuse_shapes_bezier = xuse_graphics || X16_USE_SHAPES_BEZIER != 0
xuse_verafx = xuse_graphics || X16_USE_VERAFX != 0
xuse_verafx_utils = xuse_graphics || X16_USE_VERAFX_UTILS != 0
xuse_psg = xuse_audio || X16_USE_PSG != 0
xuse_ym = xuse_audio || X16_USE_YM != 0
xuse_audio_rom = xuse_audio || X16_USE_AUDIO_ROM != 0
xuse_zsm_pcm = xuse_audio || X16_USE_ZSM_PCM != 0
xuse_adpcm = xuse_audio || X16_USE_ADPCM != 0
xuse_wav = xuse_audio || X16_USE_WAV != 0
xuse_input = xuse_input_devices || X16_USE_INPUT != 0
xuse_keyboard = xuse_input_devices || X16_USE_KEYBOARD != 0
xuse_mouse = xuse_input_devices || X16_USE_MOUSE != 0
xuse_i2c = xuse_communications || X16_USE_I2C != 0
xuse_vera_spi = xuse_communications || X16_USE_VERA_SPI != 0
xuse_serial_zimodem = xuse_communications || X16_USE_SERIAL_ZIMODEM != 0
xuse_bank = xuse_storage || X16_USE_BANK != 0
xuse_bankalloc = xuse_storage || X16_USE_BANKALLOC != 0
xuse_stack = xuse_storage || X16_USE_STACK != 0
xuse_ringbuffer = xuse_storage || X16_USE_RINGBUFFER != 0
xuse_mem = xuse_storage || X16_USE_MEM != 0
xuse_fileio = xuse_storage || X16_USE_FILEIO != 0
xuse_iec = xuse_storage || X16_USE_IEC != 0
xuse_load = xuse_storage || X16_USE_LOAD != 0
xuse_dos = xuse_storage || X16_USE_DOS != 0
xuse_bmx = xuse_storage || X16_USE_BMX != 0
xuse_clip = xuse_utilities || X16_USE_CLIP != 0
xuse_buffers = xuse_utilities || X16_USE_BUFFERS != 0
xuse_zx0 = xuse_utilities || X16_USE_ZX0 != 0
xuse_tsc = xuse_utilities || X16_USE_TSC != 0
xuse_fixed = xuse_utilities || X16_USE_FIXED != 0
xuse_bcd = xuse_utilities || X16_USE_BCD != 0
xuse_collide = xuse_utilities || X16_USE_COLLIDE != 0
xuse_bits = xuse_utilities || X16_USE_BITS != 0
xuse_int16 = xuse_utilities || X16_USE_INT16 != 0
xuse_int32 = xuse_utilities || X16_USE_INT32 != 0
xuse_float = xuse_utilities || X16_USE_FLOAT != 0
xuse_double = xuse_utilities || X16_USE_DOUBLE != 0
xuse_sort = xuse_utilities || X16_USE_SORT != 0
xuse_string_ctype = xuse_strings || X16_USE_STRING_CTYPE != 0
xuse_string_case = xuse_strings || X16_USE_STRING_CASE != 0
xuse_string_find = xuse_strings || X16_USE_STRING_FIND != 0
xuse_string_slice = xuse_strings || X16_USE_STRING_SLICE != 0
xuse_string_sort = xuse_strings || X16_USE_STRING_SORT != 0
xuse_clock = xuse_system || X16_USE_CLOCK != 0
xuse_screen = xuse_video || X16_USE_SCREEN != 0 || xuse_bitmap8l
xuse_shapes_arc = xuse_graphics || X16_USE_SHAPES_ARC != 0 || xuse_shapes_pie
xuse_zsm = xuse_audio || X16_USE_ZSM != 0 || xuse_zsm_pcm
xuse_pcm_stream = xuse_audio || X16_USE_PCM_STREAM != 0 || xuse_zsm_pcm
xuse_serial = xuse_communications || X16_USE_SERIAL != 0 || xuse_serial_zimodem
xuse_number = xuse_utilities || X16_USE_NUMBER != 0 || xuse_int16
xuse_string = xuse_strings || X16_USE_STRING != 0 || xuse_string_sort
xuse_verafx_mult = xuse_verafx || X16_USE_VERAFX_MULT != 0
xuse_verafx_copy = xuse_verafx || X16_USE_VERAFX_COPY != 0
xuse_verafx_transp = xuse_verafx || X16_USE_VERAFX_TRANSP != 0
xuse_verafx_affine = xuse_verafx || X16_USE_VERAFX_AFFINE != 0
xuse_verafx_line = xuse_verafx || X16_USE_VERAFX_LINE != 0
xuse_verafx_tri = xuse_verafx || X16_USE_VERAFX_TRI != 0
xuse_input_core = xuse_input || X16_USE_INPUT_CORE != 0
xuse_input_keywait = xuse_input || X16_USE_INPUT_KEYWAIT != 0
xuse_pcm = xuse_audio || X16_USE_PCM != 0 || xuse_pcm_stream
xuse_math = xuse_utilities || X16_USE_MATH != 0 || xuse_shapes_poly || xuse_shapes_arc
xuse_irq = xuse_system || X16_USE_IRQ != 0 || xuse_pcm_stream
xuse_shp_line = xuse_shapes_arc || X16_USE_SHP_LINE != 0 || xuse_shapes_bezier
xuse_verafx_linetri = xuse_verafx_line || X16_USE_VERAFX_LINETRI != 0 || xuse_verafx_tri
xuse_input_any = xuse_input_core || xuse_input_keywait
xuse_screen_core = xuse_screen || X16_USE_SCREEN_CORE != 0
xuse_screen_extra = xuse_screen || X16_USE_SCREEN_EXTRA != 0
xuse_shapes = xuse_graphics || X16_USE_SHAPES != 0 || xuse_shapes_poly || xuse_shapes_pie || xuse_shapes_arc || xuse_shapes_rrect || xuse_shapes_bezier || xuse_shp_line
xuse_irq_core = xuse_irq || X16_USE_IRQ_CORE != 0
xuse_irq_remove = xuse_irq || X16_USE_IRQ_REMOVE != 0
xuse_irq_vsync = xuse_irq || X16_USE_IRQ_VSYNC != 0
xuse_irq_sprcol_api = xuse_irq || X16_USE_IRQ_SPRCOL_API != 0
xuse_screen_any = xuse_screen_core || xuse_screen_extra
xuse_bitmap2h = xuse_graphics || X16_USE_BITMAP2H != 0 || xuse_shapes
xuse_irq_sprcol = xuse_irq || X16_USE_IRQ_SPRCOL != 0 || xuse_irq_sprcol_api
xuse_vera = xuse_video || X16_USE_VERA != 0 || xuse_sprite || xuse_psg || xuse_bitmap8l || xuse_bitmap2h || xuse_bitmap2l || xuse_bitmap4l
xuse_verafx_fill = xuse_bitmap2h || X16_USE_VERAFX_FILL != 0 || xuse_bitmap2l || xuse_verafx
xuse_irq_any = xuse_irq_core || xuse_irq_remove || xuse_irq_vsync || xuse_irq_sprcol
xuse_verafx_any = xuse_verafx_mult || xuse_verafx_fill || xuse_verafx_copy || xuse_verafx_transp || xuse_verafx_affine || xuse_verafx_line || xuse_verafx_tri
xuse_vera_core = xuse_vera || X16_USE_VERA_CORE != 0
xuse_vera_copy = xuse_vera || X16_USE_VERA_COPY != 0
xuse_vera_addr = xuse_vera_core || X16_USE_VERA_ADDR != 0
xuse_vera_fill = xuse_vera_core || X16_USE_VERA_FILL != 0
xuse_vera_fxprobe = xuse_vera_core || X16_USE_VERA_FXPROBE != 0
xuse_vera_any = xuse_vera_addr || xuse_vera_fill || xuse_vera_fxprobe || xuse_vera_copy

; --- modules (the ACME tree's order) ---
.if xuse_vera_any
.include "video/vera.asm"
.endif
.if xuse_vera_dc
.include "video/vdc.asm"
.endif
.if xuse_screen_any
.include "video/screen.asm"
.endif
.if xuse_palette
.include "video/palette.asm"
.endif
.if xuse_tile
.include "video/tile.asm"
.endif
.if xuse_sprite
.include "sprite/sprite.asm"
.endif
.if xuse_bitmap8l
.include "gfx/bitmap8l.asm"
.endif
.if xuse_bitmap8h
.include "gfx/bitmap8h.asm"
.endif
.if xuse_bitmap2h
.include "gfx/bitmap2h.asm"
.endif
.if xuse_bitmap2l
.include "gfx/bitmap2l.asm"
.endif
.if xuse_bitmap4l
.include "gfx/bitmap4l.asm"
.endif
.if xuse_bitmap4h
.include "gfx/bitmap4h.asm"
.endif
.if xuse_fb
.include "gfx/fb.asm"
.endif
.if xuse_graph
.include "gfx/graph.asm"
.endif
.if xuse_console
.include "gfx/console.asm"
.endif
.if xuse_shapes && X16_SKIP_SHAPES == 0
.include "gfx/shapes.asm"
.endif
.if xuse_verafx_any
.include "gfx/verafx.asm"
.endif
.if xuse_verafx_utils
.include "gfx/verafx_utils.asm"
.endif
.if xuse_clock
.include "system/clock.asm"
.endif
.if xuse_irq_any
.include "system/irq.asm"
.endif
.if xuse_psg
.include "audio/psg.asm"
.endif
.if xuse_ym
.include "audio/ym.asm"
.endif
.if xuse_audio_rom
.include "audio/rom.asm"
.endif
.if xuse_zsm
.include "audio/zsm.asm"
.endif
.if xuse_pcm
.include "audio/pcm.asm"
.endif
.if xuse_input_any
.include "input/input.asm"
.endif
.if xuse_keyboard
.include "input/keyboard.asm"
.endif
.if xuse_mouse
.include "input/mouse.asm"
.endif
.if xuse_i2c
.include "comms/i2c.asm"
.endif
.if xuse_vera_spi
.include "comms/spi.asm"
.endif
.if xuse_serial
.include "comms/serial.asm"
.endif
.if xuse_serial_zimodem
.include "comms/zimodem.asm"
.endif
.if xuse_bank
.include "storage/bank.asm"
.endif
.if xuse_bankalloc
.include "storage/bankalloc.asm"
.endif
.if xuse_stack
.include "storage/stack.asm"
.endif
.if xuse_ringbuffer
.include "storage/ringbuffer.asm"
.endif
.if xuse_mem
.include "storage/mem.asm"
.endif
.if xuse_fileio
.include "storage/fileio.asm"
.endif
.if xuse_iec
.include "storage/iec.asm"
.endif
.if xuse_load
.include "storage/load.asm"
.endif
.if xuse_dos
.include "storage/dos.asm"
.endif
.if xuse_bmx
.include "storage/bmx.asm"
.endif
.if xuse_math && X16_SKIP_MATH == 0
.include "util/math.asm"
.endif
.if xuse_clip
.include "util/clip.asm"
.endif
.if xuse_buffers
.include "util/buffers.asm"
.endif
.if xuse_adpcm
.include "audio/adpcm.asm"
.endif
.if xuse_wav
.include "audio/wavfile.asm"
.endif
.if xuse_zx0
.include "util/zx0.asm"
.endif
.if xuse_tsc
.include "util/tscrunch.asm"
.endif
.if xuse_fixed
.include "util/fixed.asm"
.endif
.if xuse_bcd
.include "util/bcd.asm"
.endif
.if xuse_collide
.include "util/collide.asm"
.endif
.if xuse_bits
.include "util/bits.asm"
.endif
.if xuse_number
.include "util/number.asm"
.endif
.if xuse_sort
.include "util/sort.asm"
.endif
.if xuse_int16
.include "util/int16.asm"
.endif
.if xuse_int32
.include "util/int32.asm"
.endif
.if xuse_float
.include "util/float.asm"
.endif
.if xuse_double
.include "util/double.asm"
.endif
.if xuse_string
.include "string/string.asm"
.endif
.if xuse_string_ctype
.include "string/ctype.asm"
.endif
.if xuse_string_case
.include "string/case.asm"
.endif
.if xuse_string_find
.include "string/find.asm"
.endif
.if xuse_string_slice
.include "string/slice.asm"
.endif
.if xuse_string_sort
.include "string/strsort.asm"
.endif
