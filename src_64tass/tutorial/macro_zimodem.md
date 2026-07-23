# ZiModem Macros

> Generated 64tass edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_SERIAL_ZIMODEM` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_SERIAL_ZIMODEM = 1
.include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `Scope`

| Field | Details |
|---|---|
| Macro | Scope |
| Purpose | ESP32 WiFi modem helpers on top of Serial; most block on real hardware replies |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL_ZIMODEM = 1
.include "x16.asm"

main
  ; see macro listing above
    rts
```

## `#xm_zi_init base, divisor`

| Field | Details |
|---|---|
| Macro | `#xm_zi_init base, divisor` |
| Purpose | reset the modem to a known state |
| Input parameters | `base, divisor` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL_ZIMODEM = 1
.include "x16.asm"

main
    #xm_zi_init base, divisor
    rts
```

## `#xm_zi_cmd addr`

| Field | Details |
|---|---|
| Macro | `#xm_zi_cmd addr` |
| Purpose | send an `AT...` command line (+ CR/LF) |
| Input parameters | `addr` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL_ZIMODEM = 1
.include "x16.asm"

main
    #xm_zi_cmd addr
    rts
```

## `#xm_zi_wait_ok`

| Field | Details |
|---|---|
| Macro | `#xm_zi_wait_ok` |
| Purpose | read/discard the reply up to `OK\r\n` |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL_ZIMODEM = 1
.include "x16.asm"

main
    #xm_zi_wait_ok
    rts
```

## `#xm_zi_reset`

| Field | Details |
|---|---|
| Macro | `#xm_zi_reset` |
| Purpose | `ATZ` |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL_ZIMODEM = 1
.include "x16.asm"

main
    #xm_zi_reset
    rts
```

## `#xm_zi_get_ip buffer`

| Field | Details |
|---|---|
| Macro | `#xm_zi_get_ip buffer` |
| Purpose | IPv4 address into buffer (via `ATI2`) |
| Input parameters | `buffer` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL_ZIMODEM = 1
.include "x16.asm"

main
    #xm_zi_get_ip buffer
    rts
```

## `#xm_zi_hex_open filename`

| Field | Details |
|---|---|
| Macro | `#xm_zi_hex_open filename` |
| Purpose | begin a hex-mode download |
| Input parameters | `filename` |
| Output parameters | carry set = not found) |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL_ZIMODEM = 1
.include "x16.asm"

main
    #xm_zi_hex_open filename
    rts
```

## `#xm_zi_hex_chunk buffer`

| Field | Details |
|---|---|
| Macro | `#xm_zi_hex_chunk buffer` |
| Purpose | next payload chunk |
| Input parameters | `buffer` |
| Output parameters | A = bytes, 0 = done) |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL_ZIMODEM = 1
.include "x16.asm"

main
    #xm_zi_hex_chunk buffer
    rts
```

## `#xm_zi_hex_close`

| Field | Details |
|---|---|
| Macro | `#xm_zi_hex_close` |
| Purpose | swallow the trailing `OK` |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL_ZIMODEM = 1
.include "x16.asm"

main
    #xm_zi_hex_close
    rts
```

## `#xm_zi_hexdecode src, digits, dest`

| Field | Details |
|---|---|
| Macro | `#xm_zi_hexdecode src, digits, dest` |
| Purpose | pack ASCII hex -> bytes |
| Input parameters | `src, digits, dest` |
| Output parameters | bytes (-> A = `digits`/2) |
| More info | Available when `X16_USE_SERIAL_ZIMODEM` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_SERIAL_ZIMODEM = 1
.include "x16.asm"

main
    #xm_zi_hexdecode src, digits, dest
    rts
```
