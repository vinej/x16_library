//ACME
// =====================================================================
// x16lib :: core/const_vera.asm -- VERA registers, VRAM map, bitfields
// =====================================================================
// Pure symbol file. Safe to !source any number of times.
//
// Sources of truth:
//   doc/X16 Reference - 09 - VERA Programmer's Reference.md
//   doc/X16 Reference - 10 - VERA FX Reference.md
//   x16-rom-r49/inc/io.inc
// =====================================================================

#importonce

.label VERA_BASE = $9F20

// (!addr block: .const assignments in KickAssembler)
.label VERA_ADDR_L = VERA_BASE + $00
.label VERA_ADDR_M = VERA_BASE + $01
.label VERA_ADDR_H = VERA_BASE + $02   // bank + increment index + DECR
.label VERA_DATA0 = VERA_BASE + $03
.label VERA_DATA1 = VERA_BASE + $04
.label VERA_CTRL = VERA_BASE + $05   // RESET | DCSEL(6) | ADDRSEL
.label VERA_IEN = VERA_BASE + $06
.label VERA_ISR = VERA_BASE + $07   // bits 7:4 = sprite collisions
.label VERA_IRQ_LINE_L = VERA_BASE + $08

// --- $9F29-$9F2C are banked by DCSEL -------------------------------
// DCSEL = 0
.label VERA_DC_VIDEO = VERA_BASE + $09
.label VERA_DC_HSCALE = VERA_BASE + $0A
.label VERA_DC_VSCALE = VERA_BASE + $0B
.label VERA_DC_BORDER = VERA_BASE + $0C
// DCSEL = 1
.label VERA_DC_HSTART = VERA_BASE + $09
.label VERA_DC_HSTOP = VERA_BASE + $0A
.label VERA_DC_VSTART = VERA_BASE + $0B
.label VERA_DC_VSTOP = VERA_BASE + $0C
// DCSEL = 2  (FX core)
.label VERA_FX_CTRL = VERA_BASE + $09   // R/W
.label VERA_FX_TILEBASE = VERA_BASE + $0A   // W
.label VERA_FX_MAPBASE = VERA_BASE + $0B   // W
.label VERA_FX_MULT = VERA_BASE + $0C   // W
// DCSEL = 3  (line/poly increments)
.label VERA_FX_X_INCR_L = VERA_BASE + $09   // W
.label VERA_FX_X_INCR_H = VERA_BASE + $0A   // W
.label VERA_FX_Y_INCR_L = VERA_BASE + $0B   // W
.label VERA_FX_Y_INCR_H = VERA_BASE + $0C   // W
// DCSEL = 4  (line/poly positions)
.label VERA_FX_X_POS_L = VERA_BASE + $09   // W
.label VERA_FX_X_POS_H = VERA_BASE + $0A   // W
.label VERA_FX_Y_POS_L = VERA_BASE + $0B   // W
.label VERA_FX_Y_POS_H = VERA_BASE + $0C   // W
// DCSEL = 5
.label VERA_FX_X_POS_S = VERA_BASE + $09   // W
.label VERA_FX_Y_POS_S = VERA_BASE + $0A   // W
.label VERA_FX_POLY_FILL_L = VERA_BASE + $0B // R
.label VERA_FX_POLY_FILL_H = VERA_BASE + $0C // R
// DCSEL = 6  (32-bit cache / accumulator)
.label VERA_FX_CACHE_L = VERA_BASE + $09 // W
.label VERA_FX_ACCUM_RESET = VERA_BASE + $09 // R
.label VERA_FX_CACHE_M = VERA_BASE + $0A // W
.label VERA_FX_ACCUM = VERA_BASE + $0A // R
.label VERA_FX_CACHE_H = VERA_BASE + $0B // W
.label VERA_FX_CACHE_U = VERA_BASE + $0C // W
// DCSEL = 63 (version probe; DC_VER0 reads ASCII 'V')
.label VERA_DC_VER0 = VERA_BASE + $09   // R
.label VERA_DC_VER1 = VERA_BASE + $0A   // R  major
.label VERA_DC_VER2 = VERA_BASE + $0B   // R  minor
.label VERA_DC_VER3 = VERA_BASE + $0C   // R  build
// -------------------------------------------------------------------

.label VERA_L0_CONFIG = VERA_BASE + $0D
.label VERA_L0_MAPBASE = VERA_BASE + $0E
.label VERA_L0_TILEBASE = VERA_BASE + $0F
.label VERA_L0_HSCROLL_L = VERA_BASE + $10
.label VERA_L0_HSCROLL_H = VERA_BASE + $11
.label VERA_L0_VSCROLL_L = VERA_BASE + $12
.label VERA_L0_VSCROLL_H = VERA_BASE + $13

.label VERA_L1_CONFIG = VERA_BASE + $14
.label VERA_L1_MAPBASE = VERA_BASE + $15
.label VERA_L1_TILEBASE = VERA_BASE + $16
.label VERA_L1_HSCROLL_L = VERA_BASE + $17
.label VERA_L1_HSCROLL_H = VERA_BASE + $18
.label VERA_L1_VSCROLL_L = VERA_BASE + $19
.label VERA_L1_VSCROLL_H = VERA_BASE + $1A

.label VERA_AUDIO_CTRL = VERA_BASE + $1B
.label VERA_AUDIO_RATE = VERA_BASE + $1C
.label VERA_AUDIO_DATA = VERA_BASE + $1D

.label VERA_SPI_DATA = VERA_BASE + $1E
.label VERA_SPI_CTRL = VERA_BASE + $1F

// YM2151 FM chip. NOT at $9FE0 -- see x16-rom-r49/inc/io.inc.
.label YM_REG = $9F40
.label YM_DATA = $9F41
// (end addr)

// ---------------------------------------------------------------------
// CTRL bitfields.  DCSEL is SIX bits at 6:1, ADDRSEL is bit 0.
// Writing DCSEL naively clobbers ADDRSEL -- always use +vera_dcsel.
// Never set bit 7: it resets the whole chip.
// ---------------------------------------------------------------------
.label VERA_CTRL_ADDRSEL = %00000001
.label VERA_CTRL_DCSEL = %01111110
.label VERA_CTRL_RESET = %10000000

// ---------------------------------------------------------------------
// ADDR_H bitfields.  The increment field is an INDEX, not an amount.
// ---------------------------------------------------------------------
.label VERA_ADDR_H_BANK = %00000001   // VRAM address bit 16
.label VERA_ADDR_H_DECR = %00001000   // decrement instead of increment
.label VERA_ADDR_H_INCR = %11110000   // increment index, bits 7:4

.label VERA_INC_0 = 0
.label VERA_INC_1 = 1
.label VERA_INC_2 = 2
.label VERA_INC_4 = 3
.label VERA_INC_8 = 4
.label VERA_INC_16 = 5
.label VERA_INC_32 = 6
.label VERA_INC_64 = 7
.label VERA_INC_128 = 8
.label VERA_INC_256 = 9
.label VERA_INC_512 = 10
.label VERA_INC_40 = 11   // one 40-column text row
.label VERA_INC_80 = 12   // one 80-column text row
.label VERA_INC_160 = 13
.label VERA_INC_320 = 14   // one 320-pixel bitmap row
.label VERA_INC_640 = 15

// ---------------------------------------------------------------------
// DC_VIDEO (DCSEL=0) bitfields.
// ---------------------------------------------------------------------
.label VERA_VIDEO_MODE_OFF = 0
.label VERA_VIDEO_MODE_VGA = 1
.label VERA_VIDEO_MODE_NTSC = 2
.label VERA_VIDEO_MODE_RGB = 3
.label VERA_VIDEO_CHROMA_DIS = %00000100
.label VERA_VIDEO_240P = %00001000
.label VERA_VIDEO_LAYER0_EN = %00010000
.label VERA_VIDEO_LAYER1_EN = %00100000
.label VERA_VIDEO_SPRITES_EN = %01000000
.label VERA_VIDEO_FIELD = %10000000   // read-only

// ---------------------------------------------------------------------
// ISR / IEN bitfields.  ISR bits 7:4 report sprite collision groups.
// ---------------------------------------------------------------------
.label VERA_IRQ_VSYNC = %00000001
.label VERA_IRQ_LINE = %00000010
.label VERA_IRQ_SPRCOL = %00000100
.label VERA_IRQ_AFLOW = %00001000
.label VERA_ISR_COLLISION = %11110000

// ---------------------------------------------------------------------
// FX_CTRL (DCSEL=2) bitfields.
// ---------------------------------------------------------------------
.label VERA_FX_ADDR1_NORMAL = 0
.label VERA_FX_ADDR1_LINE = 1
.label VERA_FX_ADDR1_POLY = 2
.label VERA_FX_ADDR1_AFFINE = 3
.label VERA_FX_4BIT_MODE = %00000100
.label VERA_FX_16BIT_HOP = %00001000
.label VERA_FX_CACHE_CYCLE = %00010000
.label VERA_FX_CACHE_FILL = %00100000
.label VERA_FX_CACHE_WRITE = %01000000
.label VERA_FX_TRANSPARENT = %10000000

// FX_MULT (DCSEL=2) bitfields.
.label VERA_FX_MULT_2BYTE_INCR = %00000001
.label VERA_FX_MULT_NIB_INDEX = %00000010
.label VERA_FX_MULT_BYTE_INDEX = %00001100
.label VERA_FX_MULT_ENABLE = %00010000
.label VERA_FX_MULT_SUBTRACT = %00100000
.label VERA_FX_MULT_ACCUMULATE = %01000000
.label VERA_FX_MULT_RESET_ACC = %10000000

.label VERA_DCSEL_FX_VERSION = 63
.label VERA_VERSION_MAGIC = $56          // 'V' in DC_VER0

// ---------------------------------------------------------------------
// Layer CONFIG bitfields.
// ---------------------------------------------------------------------
.label VERA_LAYER_BPP_1 = 0
.label VERA_LAYER_BPP_2 = 1
.label VERA_LAYER_BPP_4 = 2
.label VERA_LAYER_BPP_8 = 3
.label VERA_LAYER_T256C = %00001000    // 256-colour text
.label VERA_LAYER_BITMAP = %00000100    // bitmap instead of tile mode
// Map size, bits 7:6 = height, 5:4 = width (0=32,1=64,2=128,3=256 tiles)
.label VERA_LAYER_MAPW_32 = %00000000
.label VERA_LAYER_MAPW_64 = %00010000
.label VERA_LAYER_MAPW_128 = %00100000
.label VERA_LAYER_MAPW_256 = %00110000
.label VERA_LAYER_MAPH_32 = %00000000
.label VERA_LAYER_MAPH_64 = %01000000
.label VERA_LAYER_MAPH_128 = %10000000
.label VERA_LAYER_MAPH_256 = %11000000

// ---------------------------------------------------------------------
// VRAM map.  17-bit addresses: bit 16 is the "bank" in ADDR_H.
//
// NOTE: $1F9C0-$1FFFF (PSG, palette, sprite attributes) is WRITE-ONLY.
// Reads return the last value the host wrote, not the register's real
// state.  Reading back your own writes is fine; inferring hardware state
// after a reset is not.
// ---------------------------------------------------------------------
.label VRAM_BITMAP = $00000       // default 320x240x256 framebuffer
.label VRAM_SPRITE_DATA = $13000       // KERNAL's sprite image area
.label VRAM_TEXT = $1B000       // default text-mode tilemap
.label VRAM_CHARSET = $1F000
.label VRAM_PSG = $1F9C0       // 16 voices x 4 bytes
.label VRAM_PALETTE = $1FA00       // 256 entries x 2 bytes
.label VRAM_SPRITE_ATTR = $1FC00       // 128 sprites x 8 bytes

// The FX multiplier writes its 32-bit result to VRAM rather than to a
// register, so it needs four scratch bytes. $1F800-$1F9BF is unused in
// the VERA memory map. Redefine before sourcing x16.asm to relocate.
#if !VRAM_FX_SCRATCH_SET
.label VRAM_FX_SCRATCH = $1F800
#endif

.label VERA_PSG_VOICE_SIZE = 4
.label VERA_SPRITE_ATTR_SIZE = 8

// Sprite attribute byte offsets (see VERA reference "Sprite attributes").
.label SPRITE_ATTR_ADDR_L = 0    // image address bits 12:5
.label SPRITE_ATTR_ADDR_H = 1    // bit7 = mode (0=4bpp,1=8bpp), bits 3:0 = addr 16:13
.label SPRITE_ATTR_X_L = 2
.label SPRITE_ATTR_X_H = 3    // bits 1:0 = X 9:8
.label SPRITE_ATTR_Y_L = 4
.label SPRITE_ATTR_Y_H = 5    // bits 1:0 = Y 9:8
.label SPRITE_ATTR_FLAGS = 6    // collision mask 7:4 | Z 3:2 | vflip 1 | hflip 0
.label SPRITE_ATTR_SIZE_PAL = 7    // height 7:6 | width 5:4 | palette offset 3:0

.label SPRITE_MODE_4BPP = %00000000
.label SPRITE_MODE_8BPP = %10000000

.label SPRITE_Z_DISABLED = %00000000
.label SPRITE_Z_BEHIND = %00000100   // between background and layer 0
.label SPRITE_Z_MIDDLE = %00001000   // between layer 0 and layer 1
.label SPRITE_Z_FRONT = %00001100   // in front of layer 1
.label SPRITE_HFLIP = %00000001
.label SPRITE_VFLIP = %00000010

.label SPRITE_SIZE_8 = 0
.label SPRITE_SIZE_16 = 1
.label SPRITE_SIZE_32 = 2
.label SPRITE_SIZE_64 = 3
