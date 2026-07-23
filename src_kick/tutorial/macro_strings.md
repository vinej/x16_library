# Strings Macros

> Generated KickAssembler edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_STRING and friends` macro gate.

Set the gate before sourcing the library:

```asm
#define X16_USE_STRING
#import "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `Gates / arguments`

| Field | Details |
|---|---|
| Macro | Gates / arguments |
| Purpose | each string gate is separate; `str`/`src`/`dst` are addresses, `ch` and lengths are immediates |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
 // see macro listing above
    rts
```

## `xm_str_length(str)`

| Field | Details |
|---|---|
| Macro | `xm_str_length(str)` |
| Purpose | -> Y = length |
| Input parameters | `str` |
| Output parameters | Y = length |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
    xm_str_length(str)
    rts
```

## `xm_str_copy(src, dst)`

| Field | Details |
|---|---|
| Macro | `xm_str_copy(src, dst)` |
| Purpose | copy |
| Input parameters | `src, dst` |
| Output parameters | Y = length) |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
    xm_str_copy(src, dst)
    rts
```

## `xm_str_ncopy(src, dst, max)`

| Field | Details |
|---|---|
| Macro | `xm_str_ncopy(src, dst, max)` |
| Purpose | copy, capped |
| Input parameters | `src, dst, max` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
    xm_str_ncopy(src, dst, max)
    rts
```

## `xm_str_append(tgt, suffix)`

| Field | Details |
|---|---|
| Macro | `xm_str_append(tgt, suffix)` |
| Purpose | -> A = new length |
| Input parameters | `tgt, suffix` |
| Output parameters | A = new length |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
    xm_str_append(tgt, suffix)
    rts
```

## `xm_str_nappend(tgt, suffix, max)`

| Field | Details |
|---|---|
| Macro | `xm_str_nappend(tgt, suffix, max)` |
| Purpose | append, capped |
| Input parameters | `tgt, suffix, max` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
    xm_str_nappend(tgt, suffix, max)
    rts
```

## `xm_str_compare(s1, s2)`

| Field | Details |
|---|---|
| Macro | `xm_str_compare(s1, s2)` |
| Purpose | -> A = -1 / 0 / 1 |
| Input parameters | `s1, s2` |
| Output parameters | A = -1 / 0 / 1 |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
    xm_str_compare(s1, s2)
    rts
```

## `xm_str_hash(str)`

| Field | Details |
|---|---|
| Macro | `xm_str_hash(str)` |
| Purpose | -> A = hash |
| Input parameters | `str` |
| Output parameters | A = hash |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
    xm_str_hash(str)
    rts
```

## `xm_str_lower str / xm_str_lower_iso str`

| Field | Details |
|---|---|
| Macro | `xm_str_lower(str)` / `xm_str_lower_iso(str)` |
| Purpose | lower-case in place |
| Input parameters | `str` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
    xm_str_lower(str)
    rts
```

## `xm_str_upper str / xm_str_upper_iso str`

| Field | Details |
|---|---|
| Macro | `xm_str_upper(str)` / `xm_str_upper_iso(str)` |
| Purpose | upper-case in place |
| Input parameters | `str` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
    xm_str_upper(str)
    rts
```

## `xm_str_compare_nocase s1, s2 (+ _iso)`

| Field | Details |
|---|---|
| Macro | `xm_str_compare_nocase(s1, s2)` (+ `_iso`) |
| Purpose | case-insensitive compare |
| Input parameters | `s1, s2` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
    xm_str_compare_nocase(s1, s2)
    rts
```

## `xm_str_find str, ch / xm_str_rfind str, ch`

| Field | Details |
|---|---|
| Macro | `xm_str_find(str, ch)` / `xm_str_rfind(str, ch)` |
| Purpose | -> carry + A = index |
| Input parameters | `str, ch` |
| Output parameters | carry + A = index |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
    xm_str_find(str, ch)
    rts
```

## `xm_str_find_eol(str)`

| Field | Details |
|---|---|
| Macro | `xm_str_find_eol(str)` |
| Purpose | first CR/LF |
| Input parameters | `str` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
    xm_str_find_eol(str)
    rts
```

## `xm_str_contains(str, ch)`

| Field | Details |
|---|---|
| Macro | `xm_str_contains(str, ch)` |
| Purpose | -> carry set if present |
| Input parameters | `str, ch` |
| Output parameters | carry set if present |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
    xm_str_contains(str, ch)
    rts
```

## `xm_str_pattern_match(str, pattern)`

| Field | Details |
|---|---|
| Macro | `xm_str_pattern_match(str, pattern)` |
| Purpose | `?`/`*` match -> carry |
| Input parameters | `str, pattern` |
| Output parameters | carry |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
    xm_str_pattern_match(str, pattern)
    rts
```

## `xm_str_left src, dst, len / xm_str_right ...`

| Field | Details |
|---|---|
| Macro | `xm_str_left(src, dst, len)` / `xm_str_right(...)` |
| Purpose | copy an end |
| Input parameters | `src, dst, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
    xm_str_left(src, dst, len)
    rts
```

## `xm_str_slice(src, dst, start, len)`

| Field | Details |
|---|---|
| Macro | `xm_str_slice(src, dst, start, len)` |
| Purpose | copy a middle run |
| Input parameters | `src, dst, start, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
    xm_str_slice(src, dst, start, len)
    rts
```

## `xm_str_ltrim str / xm_str_rtrim str / xm_str_trim str`

| Field | Details |
|---|---|
| Macro | `xm_str_ltrim(str)` / `xm_str_rtrim(str)` / `xm_str_trim(str)` |
| Purpose | trim whitespace in place |
| Input parameters | `str` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
    xm_str_ltrim(str)
    rts
```

## `str_isdigit, str_lowerchar, ...`

| Field | Details |
|---|---|
| Macro | `str_isdigit`, `str_lowerchar`, ... |
| Purpose | character already in `A`; call directly |
| Input parameters | No macro arguments. |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
#define X16_USE_STRING
#import "x16.asm"

main
 // see macro listing above
    rts
```
