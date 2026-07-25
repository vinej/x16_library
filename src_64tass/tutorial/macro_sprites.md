# Sprites Macros

> Generated 64tass edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_SPRITE` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_SPRITE = 1
.include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `#xm_sprites_on / #xm_sprites_off`

| Field | Details |
|---|---|
| Macro | `#xm_sprites_on` / `#xm_sprites_off` |
| Purpose | the sprite renderer as a whole |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SPRITE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_SPRITE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Place sprite 0 over a player start position.
    #xm_sprites_on
    #xm_sprites_off
    rts

.include "x16_code.asm"
```

## `#xm_sprite_init_all`

| Field | Details |
|---|---|
| Macro | `#xm_sprite_init_all` |
| Purpose | zero all 128 attribute records |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SPRITE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_SPRITE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Place sprite 0 over a player start position.
    #xm_sprite_init_all
    rts

.include "x16_code.asm"
```

## `#xm_sprite_pos sprite, x, y`

| Field | Details |
|---|---|
| Macro | `#xm_sprite_pos sprite, x, y` |
| Purpose | set a sprite's 10-bit position |
| Input parameters | `sprite, x, y` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SPRITE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_SPRITE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Place sprite 0 over a player start position.
    #xm_sprite_pos 1, 32, 40
    rts

.include "x16_code.asm"
```

## `#xm_sprite_get_pos sprite`

| Field | Details |
|---|---|
| Macro | `#xm_sprite_get_pos sprite` |
| Purpose | read it back |
| Input parameters | `sprite` |
| Output parameters | P0/1 = x, P2/3 = y) |
| More info | Available when `X16_USE_SPRITE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_SPRITE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Place sprite 0 over a player start position.
    #xm_sprite_get_pos 1
    rts

.include "x16_code.asm"
```

## `#xm_sprite_image sprite, vaddr, mode`

| Field | Details |
|---|---|
| Macro | `#xm_sprite_image sprite, vaddr, mode` |
| Purpose | point at pixels; `mode` = `SPRITE_MODE_4BPP`/`8BPP` |
| Input parameters | `sprite, vaddr, mode` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SPRITE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_SPRITE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Place sprite 0 over a player start position.
    #xm_sprite_image 1, $10000, 0
    rts

.include "x16_code.asm"
```

## `#xm_sprite_image_at sprite, vbank, vaddr, mode`

| Field | Details |
|---|---|
| Macro | `#xm_sprite_image_at sprite, vbank, vaddr, mode` |
| Purpose | the same as `#xm_sprite_image`, with the VRAM address already split |
| Input parameters | `sprite, vbank, vaddr, mode` -- `vbank` is address bit 16, `vaddr` the low 16 bits |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SPRITE` is enabled. |
| Example | See below. |

`#xm_sprite_image` shifts its address at assemble time, so every
argument must be a constant. Use this one when the image address is
computed at run time -- a program building N sprite images into VRAM
in a loop knows the address only as a variable.

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_SPRITE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; $10000 written out as bank 1, offset $0000
    #xm_sprite_image_at 1, 1, $0000, SPRITE_MODE_4BPP
    rts

.include "x16_code.asm"
```

## `#xm_sprite_flags sprite, flags`

| Field | Details |
|---|---|
| Macro | `#xm_sprite_flags sprite, flags` |
| Purpose | byte 6: collision mask, Z, flips |
| Input parameters | `sprite, flags` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SPRITE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_SPRITE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Place sprite 0 over a player start position.
    #xm_sprite_flags 1, 1
    rts

.include "x16_code.asm"
```

## `#xm_sprite_z sprite, z`

| Field | Details |
|---|---|
| Macro | `#xm_sprite_z sprite, z` |
| Purpose | change only the Z-depth |
| Input parameters | `sprite, z` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SPRITE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_SPRITE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Place sprite 0 over a player start position.
    #xm_sprite_z 1, 1
    rts

.include "x16_code.asm"
```

## `#xm_sprite_size sprite, wcode, hcode, paloff`

| Field | Details |
|---|---|
| Macro | `#xm_sprite_size sprite, wcode, hcode, paloff` |
| Purpose | size codes + palette offset |
| Input parameters | `sprite, wcode, hcode, paloff` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SPRITE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_SPRITE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Place sprite 0 over a player start position.
    #xm_sprite_size 1, 1, 1, 0
    rts

.include "x16_code.asm"
```
