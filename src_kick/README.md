# x16lib -- KickAssembler edition

Native KickAssembler port: coming next. Until then, KickAssembler
programs use the prebuilt binary + bindings from `dist.ps1` (see the
main README).

The port will follow the ca65 pattern: `src_acme/` stays the reference
implementation, a converter produces this tree, and `test_kick/` must
pass the same 132-test suite on the emulator before it ships.
