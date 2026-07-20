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
X16_USE_ALL        = 0
X16_USE_VERA = 0
X16_USE_SCREEN = 0
X16_USE_PALETTE = 0
X16_USE_TILE = 0
X16_USE_SPRITE = 0
X16_USE_BITMAP = 0
X16_USE_BITMAP2 = 0
X16_USE_VERAFX = 0
X16_USE_IRQ = 0
X16_USE_PSG = 0
X16_USE_YM = 0
X16_USE_PCM = 0
X16_USE_PCM_STREAM = 0
X16_USE_INPUT = 0
X16_USE_BANK = 0
X16_USE_BANKALLOC = 0
X16_USE_MEM = 0
X16_USE_LOAD = 0
X16_USE_DOS = 0
X16_USE_BMX = 0
X16_USE_MATH = 0
X16_USE_CLIP = 0
X16_USE_BUFFERS = 0
X16_USE_ADPCM = 0
X16_USE_ZX0 = 0
X16_USE_TSC = 0
X16_USE_FIXED = 0
X16_USE_COLLIDE = 0
X16_USE_BITS = 0
X16_USE_NUMBER = 0
X16_USE_INT16 = 0
X16_USE_INT32 = 0
X16_USE_FLOAT = 0
X16_USE_SHAPES_POLY = 0
X16_USE_SHAPES = 0
X16_USE_DOUBLE = 0
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
X16_USE_IRQ_CORE = 0
X16_USE_IRQ_VSYNC = 0
X16_USE_IRQ_SPRCOL = 0
X16_USE_IRQ_SPRCOL_API = 0
X16_USE_INPUT_CORE = 0
X16_USE_INPUT_KEYWAIT = 0
X16_USE_SCREEN_CORE = 0
X16_USE_SCREEN_EXTRA = 0
X16_BITMAP_MIN = 0
.endweak

; --- the dependency closure (generated from the ACME gates) ---
xuse_all = X16_USE_ALL != 0
xuse_palette = xuse_all || X16_USE_PALETTE != 0
xuse_tile = xuse_all || X16_USE_TILE != 0
xuse_sprite = xuse_all || X16_USE_SPRITE != 0
xuse_bitmap = xuse_all || X16_USE_BITMAP != 0
xuse_verafx = xuse_all || X16_USE_VERAFX != 0
xuse_psg = xuse_all || X16_USE_PSG != 0
xuse_ym = xuse_all || X16_USE_YM != 0
xuse_pcm_stream = xuse_all || X16_USE_PCM_STREAM != 0
xuse_input = xuse_all || X16_USE_INPUT != 0
xuse_bank = xuse_all || X16_USE_BANK != 0
xuse_bankalloc = xuse_all || X16_USE_BANKALLOC != 0
xuse_mem = xuse_all || X16_USE_MEM != 0
xuse_load = xuse_all || X16_USE_LOAD != 0
xuse_dos = xuse_all || X16_USE_DOS != 0
xuse_bmx = xuse_all || X16_USE_BMX != 0
xuse_clip = xuse_all || X16_USE_CLIP != 0
xuse_buffers = xuse_all || X16_USE_BUFFERS != 0
xuse_adpcm = xuse_all || X16_USE_ADPCM != 0
xuse_zx0 = xuse_all || X16_USE_ZX0 != 0
xuse_tsc = xuse_all || X16_USE_TSC != 0
xuse_fixed = xuse_all || X16_USE_FIXED != 0
xuse_collide = xuse_all || X16_USE_COLLIDE != 0
xuse_bits = xuse_all || X16_USE_BITS != 0
xuse_int16 = xuse_all || X16_USE_INT16 != 0
xuse_int32 = xuse_all || X16_USE_INT32 != 0
xuse_float = xuse_all || X16_USE_FLOAT != 0
xuse_shapes_poly = X16_USE_SHAPES_POLY != 0
xuse_double = X16_USE_DOUBLE != 0
xuse_screen = xuse_all || X16_USE_SCREEN != 0 || xuse_bitmap
xuse_irq = xuse_all || X16_USE_IRQ != 0 || xuse_pcm_stream
xuse_pcm = xuse_all || X16_USE_PCM != 0 || xuse_pcm_stream
xuse_math = xuse_all || X16_USE_MATH != 0 || xuse_shapes_poly
xuse_number = xuse_all || X16_USE_NUMBER != 0 || xuse_int16
xuse_shapes = xuse_shapes_poly || X16_USE_SHAPES != 0
xuse_verafx_mult = xuse_verafx || X16_USE_VERAFX_MULT != 0
xuse_verafx_copy = xuse_verafx || X16_USE_VERAFX_COPY != 0
xuse_verafx_transp = xuse_verafx || X16_USE_VERAFX_TRANSP != 0
xuse_verafx_affine = xuse_verafx || X16_USE_VERAFX_AFFINE != 0
xuse_verafx_line = xuse_verafx || X16_USE_VERAFX_LINE != 0
xuse_verafx_tri = xuse_verafx || X16_USE_VERAFX_TRI != 0
xuse_input_core = xuse_input || X16_USE_INPUT_CORE != 0
xuse_input_keywait = xuse_input || X16_USE_INPUT_KEYWAIT != 0
xuse_bitmap2 = xuse_all || X16_USE_BITMAP2 != 0 || xuse_shapes
xuse_verafx_linetri = xuse_verafx_line || X16_USE_VERAFX_LINETRI != 0 || xuse_verafx_tri
xuse_irq_core = xuse_irq || X16_USE_IRQ_CORE != 0
xuse_irq_vsync = xuse_irq || X16_USE_IRQ_VSYNC != 0
xuse_irq_sprcol_api = xuse_irq || X16_USE_IRQ_SPRCOL_API != 0
xuse_input_any = xuse_input_core || xuse_input_keywait
xuse_screen_core = xuse_screen || X16_USE_SCREEN_CORE != 0
xuse_screen_extra = xuse_screen || X16_USE_SCREEN_EXTRA != 0
xuse_vera = xuse_all || X16_USE_VERA != 0 || xuse_sprite || xuse_psg || xuse_bitmap || xuse_bitmap2
xuse_verafx_fill = xuse_bitmap2 || X16_USE_VERAFX_FILL != 0 || xuse_verafx
xuse_irq_sprcol = xuse_irq || X16_USE_IRQ_SPRCOL != 0 || xuse_irq_sprcol_api
xuse_screen_any = xuse_screen_core || xuse_screen_extra
xuse_verafx_any = xuse_verafx_mult || xuse_verafx_fill || xuse_verafx_copy || xuse_verafx_transp || xuse_verafx_affine || xuse_verafx_line || xuse_verafx_tri
xuse_vera_core = xuse_vera || X16_USE_VERA_CORE != 0
xuse_vera_copy = xuse_vera || X16_USE_VERA_COPY != 0
xuse_irq_any = xuse_irq_core || xuse_irq_vsync || xuse_irq_sprcol
xuse_vera_any = xuse_vera_core || xuse_vera_copy

; --- modules (the ACME tree's order) ---
.if xuse_vera_any
.include "video/vera.asm"
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
.if xuse_bitmap
.include "gfx/bitmap.asm"
.endif
.if xuse_bitmap2
.include "gfx/bitmap2.asm"
.endif
.if xuse_shapes
.include "gfx/shapes.asm"
.endif
.if xuse_verafx_any
.include "gfx/verafx.asm"
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
.if xuse_pcm
.include "audio/pcm.asm"
.endif
.if xuse_input_any
.include "input/input.asm"
.endif
.if xuse_bank
.include "storage/bank.asm"
.endif
.if xuse_bankalloc
.include "storage/bankalloc.asm"
.endif
.if xuse_mem
.include "storage/mem.asm"
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
.if xuse_math
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
.if xuse_zx0
.include "util/zx0.asm"
.endif
.if xuse_tsc
.include "util/tscrunch.asm"
.endif
.if xuse_fixed
.include "util/fixed.asm"
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
