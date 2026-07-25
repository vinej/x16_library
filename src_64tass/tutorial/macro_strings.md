# Strings Macros

> Generated 64tass edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_STRING and friends` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_STRING = 1
.include "x16.asm"
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
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; String macro arguments that name strings are addresses; lengths and
  ; characters are immediate values.
    #xm_str_copy source_text, work_buffer
    #xm_str_nappend work_buffer, suffix_text, 32
    rts

source_text .text "LEVEL/01", 0
suffix_text .text ".SEQ", 0
work_buffer .fill 64, 0

.include "x16_code.asm"
```

## `#xm_str_length str`

| Field | Details |
|---|---|
| Macro | `#xm_str_length str` |
| Purpose | -> Y = length |
| Input parameters | `str` |
| Output parameters | Y = length |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING_SLICE = 1
X16_USE_STRING_FIND = 1
X16_USE_STRING_CASE = 1
X16_USE_STRING_CTYPE = 1
X16_USE_STRING_CASE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Prepare a short filename in a work buffer.
    #xm_str_length source_text
    rts

source_text .text "LEVEL/01", 0

.include "x16_code.asm"
```

## `#xm_str_copy src, dst`

| Field | Details |
|---|---|
| Macro | `#xm_str_copy src, dst` |
| Purpose | copy |
| Input parameters | `src, dst` |
| Output parameters | Y = length) |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING_SLICE = 1
X16_USE_STRING_FIND = 1
X16_USE_STRING_CASE = 1
X16_USE_STRING = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Prepare a short filename in a work buffer.
    #xm_str_copy source_text, work_buffer
    rts

source_text .text "LEVEL/01", 0
work_buffer .fill 64, 0

.include "x16_code.asm"
```

## `#xm_str_ncopy src, dst, max`

| Field | Details |
|---|---|
| Macro | `#xm_str_ncopy src, dst, max` |
| Purpose | copy, capped |
| Input parameters | `src, dst, max` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING_SLICE = 1
X16_USE_STRING_FIND = 1
X16_USE_STRING_CASE = 1
X16_USE_STRING = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Prepare a short filename in a work buffer.
    #xm_str_ncopy source_text, work_buffer, 32
    rts

source_text .text "LEVEL/01", 0
work_buffer .fill 64, 0

.include "x16_code.asm"
```

## `#xm_str_append tgt, suffix`

| Field | Details |
|---|---|
| Macro | `#xm_str_append tgt, suffix` |
| Purpose | -> A = new length |
| Input parameters | `tgt, suffix` |
| Output parameters | A = new length |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING_SLICE = 1
X16_USE_STRING_FIND = 1
X16_USE_STRING_CASE = 1
X16_USE_STRING = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Prepare a short filename in a work buffer.
    #xm_str_append work_buffer, suffix_text
    rts

work_buffer .fill 64, 0
suffix_text .text ".SEQ", 0

.include "x16_code.asm"
```

## `#xm_str_nappend tgt, suffix, max`

| Field | Details |
|---|---|
| Macro | `#xm_str_nappend tgt, suffix, max` |
| Purpose | append, capped |
| Input parameters | `tgt, suffix, max` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING_SLICE = 1
X16_USE_STRING_FIND = 1
X16_USE_STRING_CASE = 1
X16_USE_STRING = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Prepare a short filename in a work buffer.
    #xm_str_nappend work_buffer, suffix_text, 32
    rts

work_buffer .fill 64, 0
suffix_text .text ".SEQ", 0

.include "x16_code.asm"
```

## `#xm_str_compare s1, s2`

| Field | Details |
|---|---|
| Macro | `#xm_str_compare s1, s2` |
| Purpose | -> A = -1 / 0 / 1 |
| Input parameters | `s1, s2` |
| Output parameters | A = -1 / 0 / 1 |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING_SLICE = 1
X16_USE_STRING_FIND = 1
X16_USE_STRING_CASE = 1
X16_USE_STRING = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Prepare a short filename in a work buffer.
    #xm_str_compare name_a, name_b
    rts

name_a .text "laser", 0
name_b .text "LASER", 0

.include "x16_code.asm"
```

## `#xm_str_hash str`

| Field | Details |
|---|---|
| Macro | `#xm_str_hash str` |
| Purpose | -> A = hash |
| Input parameters | `str` |
| Output parameters | A = hash |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING_SLICE = 1
X16_USE_STRING_FIND = 1
X16_USE_STRING_CASE = 1
X16_USE_STRING = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Prepare a short filename in a work buffer.
    #xm_str_hash source_text
    rts

source_text .text "LEVEL/01", 0

.include "x16_code.asm"
```

## `#xm_str_lower str / #xm_str_lower_iso str`

| Field | Details |
|---|---|
| Macro | `#xm_str_lower str` / `#xm_str_lower_iso str` |
| Purpose | lower-case in place |
| Input parameters | `str` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING_SLICE = 1
X16_USE_STRING_FIND = 1
X16_USE_STRING = 1
X16_USE_STRING_CASE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Normalize a command before comparing it.
    #xm_str_lower source_text
    #xm_str_lower_iso source_text
    rts

source_text .text "LEVEL/01", 0

.include "x16_code.asm"
```

## `#xm_str_upper str / #xm_str_upper_iso str`

| Field | Details |
|---|---|
| Macro | `#xm_str_upper str` / `#xm_str_upper_iso str` |
| Purpose | upper-case in place |
| Input parameters | `str` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING_SLICE = 1
X16_USE_STRING_FIND = 1
X16_USE_STRING = 1
X16_USE_STRING_CASE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Normalize a command before comparing it.
    #xm_str_upper source_text
    #xm_str_upper_iso source_text
    rts

source_text .text "LEVEL/01", 0

.include "x16_code.asm"
```

## `#xm_str_compare_nocase s1, s2 (+ _iso)`

| Field | Details |
|---|---|
| Macro | `#xm_str_compare_nocase s1, s2` (+ `_iso`) |
| Purpose | case-insensitive compare |
| Input parameters | `s1, s2` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING_SLICE = 1
X16_USE_STRING_FIND = 1
X16_USE_STRING = 1
X16_USE_STRING_CASE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Normalize a command before comparing it.
    #xm_str_compare_nocase name_a, name_b
    rts

name_a .text "laser", 0
name_b .text "LASER", 0

.include "x16_code.asm"
```

## `#xm_str_find str, ch / #xm_str_rfind str, ch`

| Field | Details |
|---|---|
| Macro | `#xm_str_find str, ch` / `#xm_str_rfind str, ch` |
| Purpose | -> carry + A = index |
| Input parameters | `str, ch` |
| Output parameters | carry + A = index |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING_SLICE = 1
X16_USE_STRING_CASE = 1
X16_USE_STRING = 1
X16_USE_STRING_FIND = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Inspect a typed command line.
    #xm_str_find source_text, '/'
    #xm_str_rfind source_text, '/'
    rts

source_text .text "LEVEL/01", 0

.include "x16_code.asm"
```

## `#xm_str_find_eol str`

| Field | Details |
|---|---|
| Macro | `#xm_str_find_eol str` |
| Purpose | first CR/LF |
| Input parameters | `str` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING_SLICE = 1
X16_USE_STRING_CASE = 1
X16_USE_STRING = 1
X16_USE_STRING_FIND = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Inspect a typed command line.
    #xm_str_find_eol source_text
    rts

source_text .text "LEVEL/01", 0

.include "x16_code.asm"
```

## `#xm_str_contains str, ch`

| Field | Details |
|---|---|
| Macro | `#xm_str_contains str, ch` |
| Purpose | -> carry set if present |
| Input parameters | `str, ch` |
| Output parameters | carry set if present |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING_SLICE = 1
X16_USE_STRING_CASE = 1
X16_USE_STRING = 1
X16_USE_STRING_FIND = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Inspect a typed command line.
    #xm_str_contains source_text, '/'
    rts

source_text .text "LEVEL/01", 0

.include "x16_code.asm"
```

## `#xm_str_pattern_match str, pattern`

| Field | Details |
|---|---|
| Macro | `#xm_str_pattern_match str, pattern` |
| Purpose | `?`/`*` match -> carry |
| Input parameters | `str, pattern` |
| Output parameters | carry |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING_SLICE = 1
X16_USE_STRING_CASE = 1
X16_USE_STRING = 1
X16_USE_STRING_FIND = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Inspect a typed command line.
    #xm_str_pattern_match source_text, pattern_bits
    rts

source_text .text "LEVEL/01", 0
pattern_bits .byte %11110000, %10010000, %10010000, %11110000, %10000000, %10000000, %10000000, %00000000

.include "x16_code.asm"
```

## `#xm_str_left src, dst, len / #xm_str_right ...`

| Field | Details |
|---|---|
| Macro | `#xm_str_left src, dst, len` / `#xm_str_right ...` |
| Purpose | copy an end |
| Input parameters | `src, dst, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING_FIND = 1
X16_USE_STRING_CASE = 1
X16_USE_STRING = 1
X16_USE_STRING_SLICE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Copy the useful part of a padded command.
    #xm_str_left source_text, work_buffer, 16
    #xm_str_right source_text, work_buffer, 16
    rts

source_text .text "LEVEL/01", 0
work_buffer .fill 64, 0

.include "x16_code.asm"
```

## `#xm_str_slice src, dst, start, len`

| Field | Details |
|---|---|
| Macro | `#xm_str_slice src, dst, start, len` |
| Purpose | copy a middle run |
| Input parameters | `src, dst, start, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING_FIND = 1
X16_USE_STRING_CASE = 1
X16_USE_STRING = 1
X16_USE_STRING_SLICE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Copy the useful part of a padded command.
    #xm_str_slice source_text, work_buffer, 4, 16
    rts

source_text .text "LEVEL/01", 0
work_buffer .fill 64, 0

.include "x16_code.asm"
```

## `#xm_str_ltrim str / #xm_str_rtrim str / #xm_str_trim str`

| Field | Details |
|---|---|
| Macro | `#xm_str_ltrim str` / `#xm_str_rtrim str` / `#xm_str_trim str` |
| Purpose | trim whitespace in place |
| Input parameters | `str` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_STRING and friends` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING_FIND = 1
X16_USE_STRING_CASE = 1
X16_USE_STRING = 1
X16_USE_STRING_SLICE = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Copy the useful part of a padded command.
    #xm_str_ltrim source_text
    #xm_str_rtrim source_text
    #xm_str_trim source_text
    rts

source_text .text "LEVEL/01", 0

.include "x16_code.asm"
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
.cpu "65c02"
.include "x16.asm"

X16_USE_STRING = 1
.include "core/sugar.asm"

* = $0801
    #basic_stub

main
  ; Character helpers use A directly, so call the routine instead of a macro.
    lda #'7'
    jsr str_isdigit
    bcc .not_digit
    lda #'Q'
    jsr str_lowerchar
.not_digit
    rts

.include "x16_code.asm"
```

<!-- generated: friendly macros for previously unwrapped routines -->

## Single characters: classification and case folding

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `#xm_str_isdigit ch`

| Field | Details |
|---|---|
| Macro | `#xm_str_isdigit ch` |
| Purpose | carry set if A is '0'..'9' |
| Input parameters | `ch` |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_STRING_CTYPE` is enabled. |

## `#xm_str_isxdigit ch`

| Field | Details |
|---|---|
| Macro | `#xm_str_isxdigit ch` |
| Purpose | carry set if A is a hex digit (0-9, A-F, a-f) |
| Input parameters | `ch` |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_STRING_CTYPE` is enabled. |

## `#xm_str_islower ch`

| Field | Details |
|---|---|
| Macro | `#xm_str_islower ch` |
| Purpose | carry set if A is 'a'..'z' (97-122) |
| Input parameters | `ch` |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_STRING_CTYPE` is enabled. |

## `#xm_str_isupper ch`

| Field | Details |
|---|---|
| Macro | `#xm_str_isupper ch` |
| Purpose | PETSCII: the two upper-case ranges, 97-122 and 193-218 |
| Input parameters | `ch` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_STRING_CTYPE` is enabled. |

## `#xm_str_isupper_iso ch`

| Field | Details |
|---|---|
| Macro | `#xm_str_isupper_iso ch` |
| Purpose | ISO: 'A'..'Z' (65-90) |
| Input parameters | `ch` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_STRING_CTYPE` is enabled. |

## `#xm_str_isletter ch`

| Field | Details |
|---|---|
| Macro | `#xm_str_isletter ch` |
| Purpose | PETSCII: a lower- or upper-case letter |
| Input parameters | `ch` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_STRING_CTYPE` is enabled. |

## `#xm_str_isletter_iso ch`

| Field | Details |
|---|---|
| Macro | `#xm_str_isletter_iso ch` |
| Purpose | ISO: a lower- or upper-case letter |
| Input parameters | `ch` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_STRING_CTYPE` is enabled. |

## `#xm_str_isspace ch`

| Field | Details |
|---|---|
| Macro | `#xm_str_isspace ch` |
| Purpose | carry set if A is space, CR, LF, TAB, shift-CR or |
| Input parameters | `ch` |
| Output parameters | Returns the carry flag. |
| More info | Available when `X16_USE_STRING_CTYPE` is enabled. |

## `#xm_str_isprint ch`

| Field | Details |
|---|---|
| Macro | `#xm_str_isprint ch` |
| Purpose | PETSCII printable: 32-127 or 160-255 |
| Input parameters | `ch` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_STRING_CTYPE` is enabled. |

## `#xm_str_isprint_iso ch`

| Field | Details |
|---|---|
| Macro | `#xm_str_isprint_iso ch` |
| Purpose | ISO printable: 32-126 or 160-255 |
| Input parameters | `ch` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_STRING_CTYPE` is enabled. |

## `#xm_str_lowerchar ch`

| Field | Details |
|---|---|
| Macro | `#xm_str_lowerchar ch` |
| Purpose | fold one character to lower case |
| Input parameters | `ch` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_STRING_CASE` is enabled. |

## `#xm_str_upperchar ch`

| Field | Details |
|---|---|
| Macro | `#xm_str_upperchar ch` |
| Purpose | ...to upper case |
| Input parameters | `ch` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_STRING_CASE` is enabled. |
