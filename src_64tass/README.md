# x16lib -- 64tass edition

Native 64tass port: coming next. Until then, 64tass programs use the
prebuilt binary + bindings from `dist.ps1` (see the main README).

The port will follow the ca65 pattern: `src_acme/` stays the reference
implementation, `tools/acme2ca65.py`'s sibling converter produces this
tree, and `test_64tass/` must pass the same 132-test suite on the
emulator before it ships.
