# DOS Macros

Detailed reference for the `X16_USE_DOS` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_DOS = 1
!source "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `+xm_dos_cmd cmd, len`

| Field | Details |
|---|---|
| Macro | `+xm_dos_cmd cmd, len` |
| Purpose | execute command; -> A = status |
| Input parameters | `cmd, len` |
| Output parameters | A = status |
| More info | Available when `X16_USE_DOS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_DOS = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; execute command; -> A = status
    +xm_dos_cmd 1, 16
    rts

!source "x16_code.asm"
```

## `+xm_dos_status`

| Field | Details |
|---|---|
| Macro | `+xm_dos_status` |
| Purpose | read DOS status |
| Input parameters | No macro arguments. |
| Output parameters | read DOS status |
| More info | Available when `X16_USE_DOS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_DOS = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; read DOS status
    +xm_dos_status
    rts

!source "x16_code.asm"
```

## `+xm_dos_delete name, len`

| Field | Details |
|---|---|
| Macro | `+xm_dos_delete name, len` |
| Purpose | delete file |
| Input parameters | `name, len` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_DOS` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
!cpu 65c02
!source "x16.asm"

X16_USE_DOS = 1
!source "core/sugar.asm"

* = $0801
    +basic_stub

main
    ; delete file
    +xm_dos_delete file_name, 16
    rts

file_name   !text "SAVEGAME,S,R", 0

!source "x16_code.asm"
```

<!-- generated: friendly macros for previously unwrapped routines -->

## More of dos

These routines were always in the library; what they lacked was a
friendly macro, so this is how to call them without writing the
register set-up by hand. Most of them work on their module's own
accumulator rather than on arguments.

## `+xm_dos_mkdir name, len`

| Field | Details |
|---|---|
| Macro | `+xm_dos_mkdir name, len` |
| Purpose | make a directory |
| Input parameters | `name`, `len` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOS` is enabled. |

## `+xm_dos_rmdir name, len`

| Field | Details |
|---|---|
| Macro | `+xm_dos_rmdir name, len` |
| Purpose | remove a directory |
| Input parameters | `name`, `len` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOS` is enabled. |

## `+xm_dos_chdir name, len`

| Field | Details |
|---|---|
| Macro | `+xm_dos_chdir name, len` |
| Purpose | change directory ("//" is the root) |
| Input parameters | `name`, `len` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOS` is enabled. |

## `+xm_dos_rename newname, newlen, oldname, oldlen`

| Field | Details |
|---|---|
| Macro | `+xm_dos_rename newname, newlen, oldname, oldlen` |
| Purpose | One-call wrappers. Each takes A = name low, X = name high, |
| Input parameters | `newname`, `newlen`, `oldname`, `oldlen` |
| Output parameters | Nothing the macro can hand back; see the routine's header. |
| More info | Available when `X16_USE_DOS` is enabled. |

## Reference: routines not covered above

Taken from each routine's own header in the source, so this
stays true as the module changes.

| Routine | Purpose | In | Out |
|---|---|---|---|
| `dos_lasterr` | the status code the last dos_* call came back with | -- | A = the code (0-19 success, 20-99 error, 255 = no channel) Every routine here reports twice: the carry says pass or fail, and A says why. A caller that can only see one of those -- a generated high-level binding, say, which will not guess a type for a routine that documents both -- can call this afterwards and get the code. |
