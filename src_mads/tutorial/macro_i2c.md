# I2C Macros

> Generated MADS edition from `src_acme/tutorial`. Do not edit this copy by hand.

Detailed reference for the `X16_USE_I2C` macro gate.

Set the gate before sourcing the library:

```asm
X16_USE_I2C = 1
    icl "x16.asm"
```

This page expands the compact listing from `macroguide.md`. Macro arguments are immediate values unless the entry says to pass an address, pointer, buffer, or preloaded state.

## `xm_i2c_read_byte device, offset`

| Field | Details |
|---|---|
| Macro | `xm_i2c_read_byte device, offset` |
| Purpose | read one byte |
| Input parameters | `device, offset` |
| Output parameters | read one byte |
| More info | Available when `X16_USE_I2C` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_I2C = 1
    icl "x16.asm"

main
    xm_i2c_read_byte device, offset
    rts
```

## `xm_i2c_write_byte value, device, offset`

| Field | Details |
|---|---|
| Macro | `xm_i2c_write_byte value, device, offset` |
| Purpose | write one byte |
| Input parameters | `value, device, offset` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_I2C` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_I2C = 1
    icl "x16.asm"

main
    xm_i2c_write_byte value, device, offset
    rts
```

## `xm_i2c_batch_read device, buffer, count`

| Field | Details |
|---|---|
| Macro | `xm_i2c_batch_read device, buffer, count` |
| Purpose | read a sequence |
| Input parameters | `device, buffer, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_I2C` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_I2C = 1
    icl "x16.asm"

main
    xm_i2c_batch_read device, buffer, count
    rts
```

## `xm_i2c_batch_read_fixed device, buffer, count`

| Field | Details |
|---|---|
| Macro | `xm_i2c_batch_read_fixed device, buffer, count` |
| Purpose | read from a fixed register |
| Input parameters | `device, buffer, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_I2C` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_I2C = 1
    icl "x16.asm"

main
    xm_i2c_batch_read_fixed device, buffer, count
    rts
```

## `xm_i2c_batch_write device, buffer, count`

| Field | Details |
|---|---|
| Macro | `xm_i2c_batch_write device, buffer, count` |
| Purpose | write a sequence |
| Input parameters | `device, buffer, count` |
| Output parameters | No direct return documented. Expect normal routine register/flag clobbers unless the macro description says otherwise. |
| More info | Available when `X16_USE_I2C` is enabled. Related macros shown on the same line share the same purpose and calling pattern. |
| Example | See below. |

```asm
X16_USE_I2C = 1
    icl "x16.asm"

main
    xm_i2c_batch_write device, buffer, count
    rts
```
