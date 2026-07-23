# Serial Macros

Detailed reference for the `X16_USE_SERIAL` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_SERIAL = 1
!source "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `base / divisor`

| Field | Details |
|---|---|
| Macro | `base` / `divisor` |
| Purpose | `base` is from `ser_detect` or `$9F60`; `divisor` is a `SER_BAUD_*` constant |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL = 1
!source "x16.asm"

main
    ; see macro listing above
    rts
```

## `+xm_ser_detect`

| Field | Details |
|---|---|
| Macro | `+xm_ser_detect` |
| Purpose | scan for UARTs |
| Input parameters | No macro arguments. |
| Output parameters | A = count, `ser_u0`/`ser_u1` = bases) |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL = 1
!source "x16.asm"

main
    +xm_ser_detect
    rts
```

## `+xm_ser_init base, divisor`

| Field | Details |
|---|---|
| Macro | `+xm_ser_init base, divisor` |
| Purpose | 8N1, FIFOs, auto-flow; selects that UART |
| Input parameters | `base, divisor` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL = 1
!source "x16.asm"

main
    +xm_ser_init base, divisor
    rts
```

## `+xm_ser_avail`

| Field | Details |
|---|---|
| Macro | `+xm_ser_avail` |
| Purpose | -> carry set if a byte is waiting |
| Input parameters | No macro arguments. |
| Output parameters | carry set if a byte is waiting |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL = 1
!source "x16.asm"

main
    +xm_ser_avail
    rts
```

## `+xm_ser_get`

| Field | Details |
|---|---|
| Macro | `+xm_ser_get` |
| Purpose | non-blocking read |
| Input parameters | No macro arguments. |
| Output parameters | carry set = empty, else A = byte) |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL = 1
!source "x16.asm"

main
    +xm_ser_get
    rts
```

## `+xm_ser_get_wait`

| Field | Details |
|---|---|
| Macro | `+xm_ser_get_wait` |
| Purpose | blocking read |
| Input parameters | No macro arguments. |
| Output parameters | A = byte) |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL = 1
!source "x16.asm"

main
    +xm_ser_get_wait
    rts
```

## `+xm_ser_put byte`

| Field | Details |
|---|---|
| Macro | `+xm_ser_put byte` |
| Purpose | send one byte |
| Input parameters | `byte` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL = 1
!source "x16.asm"

main
    +xm_ser_put byte
    rts
```

## `+xm_ser_puts addr`

| Field | Details |
|---|---|
| Macro | `+xm_ser_puts addr` |
| Purpose | send a NUL-terminated string |
| Input parameters | `addr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL = 1
!source "x16.asm"

main
    +xm_ser_puts addr
    rts
```

## `+xm_ser_write addr, len`

| Field | Details |
|---|---|
| Macro | `+xm_ser_write addr, len` |
| Purpose | send `len` bytes (binary-safe) |
| Input parameters | `addr, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL = 1
!source "x16.asm"

main
    +xm_ser_write addr, len
    rts
```

## `+xm_ser_read_until match, buffer, max`

| Field | Details |
|---|---|
| Macro | `+xm_ser_read_until match, buffer, max` |
| Purpose | read into buffer until `match` |
| Input parameters | `match, buffer, max` |
| Output parameters | P4/5 = count) |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL = 1
!source "x16.asm"

main
    +xm_ser_read_until match, buffer, max
    rts
```

## `+xm_ser_discard_until match`

| Field | Details |
|---|---|
| Macro | `+xm_ser_discard_until match` |
| Purpose | read and discard until `match` |
| Input parameters | `match` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL = 1
!source "x16.asm"

main
    +xm_ser_discard_until match
    rts
```

