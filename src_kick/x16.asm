// KickAssembler
// ====================================================================
// x16lib :: x16.asm -- constants and macros (KickAssembler edition)
// ====================================================================
// The KickAssembler port mirrors the ACME tree file for file;
// src_acme/ is the reference implementation and this tree must behave
// identically -- the same test suite proves it.
//
//      #import "x16.asm"
//      #define X16_USE_VERA            // pick modules (#define
//      #define X16_USE_ALL             // X16_USE_ALL for everything)
//      .pc = $0801 "code"
//      ...your code...
//      #import "x16_code.asm"          // library routines land here
//
// Assemble:
//      java -jar kickass\KickAss.jar -libdir src_kick prog.asm -o PROG.PRG
//
// Module gates are PREPROCESSOR symbols here (#define X16_USE_*),
// mirroring ACME's definedness semantics; define them before the
// x16_code.asm import. The .encoding below makes .text and character
// literals emit raw ASCII bytes, exactly like ACME's !text.
// ====================================================================

#importonce

.cpu _65c02
.encoding "ascii"

#import "core/const_zp.asm"
#import "core/const_vera.asm"
#import "core/const_kernal.asm"
#import "core/const_rom.asm"
#import "core/macros.asm"
