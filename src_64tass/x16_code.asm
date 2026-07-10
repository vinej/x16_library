; 64tass
; =====================================================================
; x16lib :: x16_code.asm -- the library routines (64tass edition)
; =====================================================================
; Include this EXACTLY ONCE, where the machine code should sit.
;
; Module selection works like the ACME tree: define X16_USE_* = 1 (or
; X16_USE_ALL = 1) anywhere in your program -- 64tass is multi-pass,
; so before or after this include both work. Gates you don't mention
; default to 0 through the .weak block below; the dependency closure
; (SPRITE pulls in VERA, PCM_STREAM pulls in PCM and IRQ, ...) is
; computed in the xuse_* values.
;
; The module list and order are identical to src_acme/x16_code.asm.
; =====================================================================

.weak
X16_USE_ALL        = 0
X16_USE_VERA       = 0
X16_USE_SCREEN     = 0
X16_USE_PALETTE    = 0
X16_USE_TILE       = 0
X16_USE_SPRITE     = 0
X16_USE_BITMAP     = 0
X16_USE_VERAFX     = 0
X16_USE_IRQ        = 0
X16_USE_PSG        = 0
X16_USE_YM         = 0
X16_USE_PCM        = 0
X16_USE_PCM_STREAM = 0
X16_USE_INPUT      = 0
X16_USE_BANK       = 0
X16_USE_BANKALLOC  = 0
X16_USE_MEM        = 0
X16_USE_LOAD       = 0
X16_USE_DOS        = 0
X16_USE_BMX        = 0
X16_USE_FIXED      = 0
X16_USE_COLLIDE    = 0
X16_USE_BITS       = 0
X16_USE_NUMBER     = 0
X16_USE_INT16      = 0
X16_USE_INT32      = 0
X16_USE_FLOAT      = 0
X16_USE_MATH       = 0
X16_USE_CLIP       = 0
X16_USE_BUFFERS    = 0
X16_USE_ADPCM      = 0
X16_USE_ZX0        = 0
X16_USE_TSC        = 0
.endweak

; --- the dependency closure (same rules as the ACME tree) -------------
xuse_all        = X16_USE_ALL != 0
xuse_pcm_stream = xuse_all || X16_USE_PCM_STREAM != 0
xuse_bitmap     = xuse_all || X16_USE_BITMAP != 0
xuse_sprite     = xuse_all || X16_USE_SPRITE != 0
xuse_psg        = xuse_all || X16_USE_PSG != 0
xuse_vera       = xuse_all || X16_USE_VERA != 0 || xuse_sprite || xuse_psg || xuse_bitmap
xuse_screen     = xuse_all || X16_USE_SCREEN != 0 || xuse_bitmap
xuse_int16      = xuse_all || X16_USE_INT16 != 0
xuse_number     = xuse_all || X16_USE_NUMBER != 0 || xuse_int16
xuse_pcm        = xuse_all || X16_USE_PCM != 0 || xuse_pcm_stream
xuse_irq        = xuse_all || X16_USE_IRQ != 0 || xuse_pcm_stream
xuse_palette    = xuse_all || X16_USE_PALETTE != 0
xuse_tile       = xuse_all || X16_USE_TILE != 0
xuse_verafx     = xuse_all || X16_USE_VERAFX != 0
xuse_ym         = xuse_all || X16_USE_YM != 0
xuse_input      = xuse_all || X16_USE_INPUT != 0
xuse_bank       = xuse_all || X16_USE_BANK != 0
xuse_bankalloc  = xuse_all || X16_USE_BANKALLOC != 0
xuse_mem        = xuse_all || X16_USE_MEM != 0
xuse_load       = xuse_all || X16_USE_LOAD != 0
xuse_dos        = xuse_all || X16_USE_DOS != 0
xuse_bmx        = xuse_all || X16_USE_BMX != 0
xuse_fixed      = xuse_all || X16_USE_FIXED != 0
xuse_collide    = xuse_all || X16_USE_COLLIDE != 0
xuse_bits       = xuse_all || X16_USE_BITS != 0
xuse_int32      = xuse_all || X16_USE_INT32 != 0
xuse_float      = xuse_all || X16_USE_FLOAT != 0
xuse_math       = xuse_all || X16_USE_MATH != 0
xuse_clip       = xuse_all || X16_USE_CLIP != 0
xuse_buffers    = xuse_all || X16_USE_BUFFERS != 0
xuse_adpcm      = xuse_all || X16_USE_ADPCM != 0
xuse_zx0        = xuse_all || X16_USE_ZX0 != 0
xuse_tsc        = xuse_all || X16_USE_TSC != 0

; --- modules (the ACME tree's order, byte for byte) --------------------
.if xuse_vera
.include "video/vera.asm"
.endif
.if xuse_screen
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
.if xuse_verafx
.include "gfx/verafx.asm"
.endif
.if xuse_irq
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
.if xuse_input
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
