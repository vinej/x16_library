# Collision Macros

> Generated MADS edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_COLLIDE` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_COLLIDE = 1
    icl "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_collide8 ax, ay, aw, ah, bx, by, bw, bh`

| Field | Details |
|---|---|
| Macro | `xm_collide8 ax, ay, aw, ah, bx, by, bw, bh` |
| Purpose | 8-bit AABB test; -> carry set if overlap |
| Input parameters | `ax, ay, aw, ah, bx, by, bw, bh` |
| Output parameters | carry set if overlap |
| More info | Available when `X16_USE_COLLIDE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_COLLIDE = 1
    icl "x16.asm"

main
    xm_collide8 ax, ay, aw, ah, bx, by, bw, bh
    rts
```

## `xm_collide16 ...`

| Field | Details |
|---|---|
| Macro | `xm_collide16 ...` |
| Purpose | 16-bit AABB test; -> carry set if overlap |
| Input parameters | No macro arguments. |
| Output parameters | carry set if overlap |
| More info | Available when `X16_USE_COLLIDE` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_COLLIDE = 1
    icl "x16.asm"

main
    xm_collide16
    rts
```
