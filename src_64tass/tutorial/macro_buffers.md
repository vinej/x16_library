# Buffers Macros

> Generated 64tass edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_BUFFERS` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_BUFFERS = 1
.include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `#xm_rb_init / #xm_rb_count`

| Field | Details |
|---|---|
| Macro | `#xm_rb_init` / `#xm_rb_count` |
| Purpose | ring buffer init / count |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BUFFERS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_BUFFERS = 1
.include "x16.asm"

main
    #xm_rb_init
    rts
```

## `#xm_rb_put byte`

| Field | Details |
|---|---|
| Macro | `#xm_rb_put byte` |
| Purpose | ring buffer put; -> carry set = full |
| Input parameters | `byte` |
| Output parameters | carry set = full |
| More info | Available when `X16_USE_BUFFERS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_BUFFERS = 1
.include "x16.asm"

main
    #xm_rb_put byte
    rts
```

## `#xm_rb_get`

| Field | Details |
|---|---|
| Macro | `#xm_rb_get` |
| Purpose | ring buffer get; -> A = byte, carry set = empty |
| Input parameters | No macro arguments. |
| Output parameters | A = byte, carry set = empty |
| More info | Available when `X16_USE_BUFFERS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_BUFFERS = 1
.include "x16.asm"

main
    #xm_rb_get
    rts
```

## `#xm_stk_init / #xm_stk_push byte / #xm_stk_pop / #xm_stk_depth`

| Field | Details |
|---|---|
| Macro | `#xm_stk_init` / `#xm_stk_push byte` / `#xm_stk_pop` / `#xm_stk_depth` |
| Purpose | byte stack helpers |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_BUFFERS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_BUFFERS = 1
.include "x16.asm"

main
    #xm_stk_init
    rts
```
