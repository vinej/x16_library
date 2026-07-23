# Clock Macros

> Generated ca65 edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_CLOCK` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_CLOCK = 1
.include "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_clock_update`

| Field | Details |
|---|---|
| Macro | `xm_clock_update` |
| Purpose | update clock state |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CLOCK` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_CLOCK = 1
.include "x16.asm"

main
    xm_clock_update
    rts
```

## `xm_clock_get_timer / xm_clock_set_timer ticks`

| Field | Details |
|---|---|
| Macro | `xm_clock_get_timer` / `xm_clock_set_timer ticks` |
| Purpose | jiffy timer helpers |
| Input parameters | `ticks` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CLOCK` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_CLOCK = 1
.include "x16.asm"

main
    xm_clock_get_timer
    rts
```

## `xm_clock_get_date_time`

| Field | Details |
|---|---|
| Macro | `xm_clock_get_date_time` |
| Purpose | read date/time |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CLOCK` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_CLOCK = 1
.include "x16.asm"

main
    xm_clock_get_date_time
    rts
```

## `xm_clock_set_date_time_raw year1900, month, day, hours, minutes, seconds, jiffies, weekday`

| Field | Details |
|---|---|
| Macro | `xm_clock_set_date_time_raw year1900, month, day, hours, minutes, seconds, jiffies, weekday` |
| Purpose | set raw date/time |
| Input parameters | `year1900, month, day, hours, minutes, seconds, jiffies, weekday` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CLOCK` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_CLOCK = 1
.include "x16.asm"

main
    xm_clock_set_date_time_raw year1900, month, day, hours, minutes, seconds, jiffies, weekday
    rts
```

## `xm_clock_set_date_time year, month, day, hours, minutes, seconds, weekday`

| Field | Details |
|---|---|
| Macro | `xm_clock_set_date_time year, month, day, hours, minutes, seconds, weekday` |
| Purpose | set date/time |
| Input parameters | `year, month, day, hours, minutes, seconds, weekday` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_CLOCK` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_CLOCK = 1
.include "x16.asm"

main
    xm_clock_set_date_time year, month, day, hours, minutes, seconds, weekday
    rts
```
