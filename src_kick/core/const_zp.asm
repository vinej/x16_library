//ACME
// =====================================================================
// x16lib :: core/const_zp.asm -- zero page and bank registers
// =====================================================================
// Pure symbol file. Safe to !source any number of times.
//
// X16 zero page (Programmer's Reference / x16-rom-r49 inc/regs.inc):
//   $00       RAM_BANK   - bank visible at $A000-$BFFF
//   $01       ROM_BANK   - bank visible at $C000-$FFFF
//   $02-$21   r0..r15    - KERNAL virtual registers (argument passing)
//   $22-$7F   free for user programs   <-- we claim 16 bytes here
//   $80-$FF   KERNAL / BASIC / DOS     <-- never touch
// =====================================================================

#importonce

// (!addr block: .const assignments in KickAssembler)
.label RAM_BANK = $00
.label ROM_BANK = $01

// KERNAL virtual registers. Caller-save: the library uses r0..r5 freely.
.label r0 = $02
.label r0L = $02
.label r0H = $03
.label r1 = $04
.label r1L = $04
.label r1H = $05
.label r2 = $06
.label r2L = $06
.label r2H = $07
.label r3 = $08
.label r3L = $08
.label r3H = $09
.label r4 = $0A
.label r4L = $0A
.label r4H = $0B
.label r5 = $0C
.label r5L = $0C
.label r5H = $0D
.label r6 = $0E
.label r6L = $0E
.label r6H = $0F
.label r7 = $10
.label r7L = $10
.label r7H = $11
.label r8 = $12
.label r8L = $12
.label r8H = $13
.label r9 = $14
.label r9L = $14
.label r9H = $15
.label r10 = $16
.label r10L = $16
.label r10H = $17
.label r11 = $18
.label r11L = $18
.label r11H = $19
.label r12 = $1A
.label r12L = $1A
.label r12H = $1B
.label r13 = $1C
.label r13L = $1C
.label r13H = $1D
.label r14 = $1E
.label r14L = $1E
.label r14H = $1F
.label r15 = $20
.label r15L = $20
.label r15H = $21
// (end addr)

// ---------------------------------------------------------------------
// Library scratch block.
//
// Define X16_ZP yourself *before* sourcing x16.asm to relocate it, e.g.
//       X16_ZP = $60
//       #import "x16.asm"
// It must sit inside $22-$7F and needs X16_ZP_SIZE bytes.
// ---------------------------------------------------------------------
#if !X16_ZP_SET
.label X16_ZP = $22
#endif

.label X16_ZP_SIZE = 16

// (!addr block: .const assignments in KickAssembler)
// P0..P7: routine parameters (for calls that need more than A/X/Y).
.label X16_P0 = X16_ZP + 0
.label X16_P1 = X16_ZP + 1
.label X16_P2 = X16_ZP + 2
.label X16_P3 = X16_ZP + 3
.label X16_P4 = X16_ZP + 4
.label X16_P5 = X16_ZP + 5
.label X16_P6 = X16_ZP + 6
.label X16_P7 = X16_ZP + 7

// T0..T7: private scratch. Never live across a library call boundary.
.label X16_T0 = X16_ZP + 8
.label X16_T1 = X16_ZP + 9
.label X16_T2 = X16_ZP + 10
.label X16_T3 = X16_ZP + 11
.label X16_T4 = X16_ZP + 12
.label X16_T5 = X16_ZP + 13
.label X16_T6 = X16_ZP + 14
.label X16_T7 = X16_ZP + 15
// (end addr)

// 16-bit aliases over the same bytes.
// (!addr block: .const assignments in KickAssembler)
.label X16_PTR0 = X16_P0       // P0/P1 as a pointer
.label X16_PTR1 = X16_P2       // P2/P3 as a pointer
.label X16_PTR2 = X16_P4
.label X16_PTR3 = X16_P6
.label X16_TPTR0 = X16_T0
.label X16_TPTR1 = X16_T2
.label X16_TPTR2 = X16_T4
.label X16_TPTR3 = X16_T6
// (end addr)

.if (X16_ZP < $22) {
    .error "X16_ZP must be >= $22 (below that is KERNAL r0..r15)"
}
.if ((X16_ZP + X16_ZP_SIZE) > $80) {
    .error "X16_ZP block runs past $7F into KERNAL/BASIC zero page"
}
