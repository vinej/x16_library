//ACME
// =====================================================================
// x16lib :: core/const_kernal.asm -- the $FExx/$FFxx KERNAL jump table
// =====================================================================
// Pure symbol file. Safe to !source any number of times.
//
// Transcribed from x16-rom-r49/kernal/vectors.s (segment JMPTBL, which
// cfg/kernal-x16.cfgtpl places at $FEA8). These are the *stable public*
// entry points -- do not call the implementation addresses in the const_kernal_sym
// files, they move between ROM revisions.
//
// Every ROM bank carries a bridge stub for this table (see the ROM's
// kernsup/ directory), so `jsr CHROUT` works whatever ROM bank is active.
// =====================================================================

#importonce

// (!addr block: .const assignments in KickAssembler)
// --- X16 extensions ($FEA8-$FF7D) ----------------------------------
.label EXTAPI16 = $FEA8
.label EXTAPI = $FEAB
.label MCIOUT = $FEB1
.label I2C_BATCH_READ = $FEB4
.label I2C_BATCH_WRITE = $FEB7
.label SAVEHL = $FEBA
.label KBDBUF_PEEK = $FEBD
.label KBDBUF_GET_MODIFIERS = $FEC0
.label KBDBUF_PUT = $FEC3
.label I2C_READ_BYTE = $FEC6
.label I2C_WRITE_BYTE = $FEC9
.label MONITOR = $FECC
.label ENTROPY_GET = $FECF
.label KEYMAP = $FED2
.label CONSOLE_SET_PAGING_MESSAGE = $FED5
.label CONSOLE_PUT_IMAGE = $FED8
.label CONSOLE_INIT = $FEDB
.label CONSOLE_PUT_CHAR = $FEDE
.label CONSOLE_GET_CHAR = $FEE1
.label MEMORY_FILL = $FEE4
.label MEMORY_COPY = $FEE7
.label MEMORY_CRC = $FEEA
.label MEMORY_DECOMPRESS = $FEED
.label SPRITE_SET_IMAGE = $FEF0
.label SPRITE_SET_POSITION = $FEF3

// Framebuffer API
.label FB_INIT = $FEF6
.label FB_GET_INFO = $FEF9
.label FB_SET_PALETTE = $FEFC
.label FB_CURSOR_POSITION = $FEFF
.label FB_CURSOR_NEXT_LINE = $FF02
.label FB_GET_PIXEL = $FF05
.label FB_GET_PIXELS = $FF08
.label FB_SET_PIXEL = $FF0B
.label FB_SET_PIXELS = $FF0E
.label FB_SET_8_PIXELS = $FF11
.label FB_SET_8_PIXELS_OPAQUE = $FF14
.label FB_FILL_PIXELS = $FF17
.label FB_FILTER_PIXELS = $FF1A
.label FB_MOVE_PIXELS = $FF1D

// Graphics API (lives in BANK_GRAPH, reached through these stubs)
.label GRAPH_INIT = $FF20
.label GRAPH_CLEAR = $FF23
.label GRAPH_SET_WINDOW = $FF26
.label GRAPH_SET_COLORS = $FF29
.label GRAPH_DRAW_LINE = $FF2C
.label GRAPH_DRAW_RECT = $FF2F
.label GRAPH_MOVE_RECT = $FF32
.label GRAPH_DRAW_OVAL = $FF35
.label GRAPH_DRAW_IMAGE = $FF38
.label GRAPH_SET_FONT = $FF3B
.label GRAPH_GET_CHAR_SIZE = $FF3E
.label GRAPH_PUT_CHAR = $FF41

.label MACPTR = $FF44
.label ENTER_BASIC = $FF47
.label CLOSE_ALL = $FF4A
.label CLOCK_SET_DATE_TIME = $FF4D
.label CLOCK_GET_DATE_TIME = $FF50
.label JOYSTICK_SCAN = $FF53
.label JOYSTICK_GET = $FF56
.label LKUPLA = $FF59
.label LKUPSA = $FF5C
.label SCREEN_MODE = $FF5F
.label SCREEN_SET_CHARSET = $FF62
.label MOUSE_CONFIG = $FF68
.label MOUSE_GET = $FF6B
.label JSRFAR = $FF6E   // jsr JSRFAR : !word addr : !byte bank
.label MOUSE_SCAN = $FF71
.label INDFET = $FF74
.label STASH = $FF77
.label PRIMM = $FF7D

// --- classic C64-compatible table ($FF81-$FFF3) --------------------
.label CINT = $FF81   // restore default text mode
.label IOINIT = $FF84
.label RAMTAS = $FF87
.label RESTOR = $FF8A
.label VECTOR = $FF8D
.label SETMSG = $FF90
.label SECOND = $FF93
.label TKSA = $FF96
.label MEMTOP = $FF99
.label MEMBOT = $FF9C
.label SCNKEY = $FF9F
.label SETTMO = $FFA2
.label ACPTR = $FFA5
.label CIOUT = $FFA8
.label UNTLK = $FFAB
.label UNLSN = $FFAE
.label LISTEN = $FFB1
.label TALK = $FFB4
.label READST = $FFB7
.label SETLFS = $FFBA
.label SETNAM = $FFBD
.label OPEN = $FFC0
.label CLOSE = $FFC3
.label CHKIN = $FFC6
.label CHKOUT = $FFC9
.label CLRCHN = $FFCC
.label CHRIN = $FFCF
.label CHROUT = $FFD2
.label LOAD = $FFD5
.label SAVE = $FFD8
.label SETTIM = $FFDB
.label RDTIM = $FFDE
.label STOP = $FFE1
.label GETIN = $FFE4
.label CLALL = $FFE7
.label UDTIM = $FFEA
.label SCREEN = $FFED
.label PLOT = $FFF0
.label IOBASE = $FFF3
// (end addr)

// ---------------------------------------------------------------------
// KERNAL editor variables.
//
// NOT part of the jump table -- these are internal addresses, verified
// against x16-rom-r49 (kernal/cbm/editor.s, kernal.sym). They can move
// between ROM revisions, unlike everything above.
// ---------------------------------------------------------------------
// (!addr block: .const assignments in KickAssembler)
.label KERNAL_COLOR = $0376    // active text colour: fg | bg<<4
// (end addr)

// ---------------------------------------------------------------------
// KERNAL indirect vectors.
// ---------------------------------------------------------------------
// (!addr block: .const assignments in KickAssembler)
.label CINV = $0314           // IRQ handler vector
.label CBINV = $0316           // BRK handler vector
.label NMINV = $0318           // NMI handler vector
// (end addr)

// ---------------------------------------------------------------------
// Selected PETSCII / control codes.
// ---------------------------------------------------------------------
.label PETSCII_WHITE = $05
.label PETSCII_RETURN = $0D
.label PETSCII_LOWERCASE = $0E
.label PETSCII_CLS = $93
.label PETSCII_HOME = $13
.label PETSCII_UPPERCASE = $8E
