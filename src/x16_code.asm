;ACME
; =====================================================================
; x16lib :: x16_code.asm -- the library routines
; =====================================================================
; Source this EXACTLY ONCE, at the point in your program where you want
; the library's machine code to sit (normally after your own code).
;
; ACME has no linker, so unused routines cannot be stripped for you.
; Instead, pick the modules you need by defining X16_USE_* before
; sourcing this file -- or define X16_USE_ALL to pull in everything.
;
;       X16_USE_VERA = 1
;       !source "x16_code.asm"
;
; or from the build script:  acme -DX16_USE_ALL=1 ...
;
; These gates must be resolvable on the FIRST pass, so always define
; them ahead of this !source, never after it.
; ---------------------------------------------------------------------
; Module            Provides
;   X16_USE_VERA      vera_set_addr0/1, vera_fill, vera_copy, vera_has_fx
;   X16_USE_SCREEN    screen_set_mode/get_mode/reset/cls/color/border,
;                     screen_locate, screen_get_cursor, screen_charset,
;                     screen_puts
;   X16_USE_PALETTE   pal_set, pal_load
; =====================================================================

!ifdef X16_USE_ALL {
    X16_USE_VERA    = 1
    X16_USE_SCREEN  = 1
    X16_USE_PALETTE = 1
}

; screen and palette both reach for VERA constants and macros (always
; available), but only palette needs no code from video/vera.asm.
!ifdef X16_USE_VERA {
    !source "video/vera.asm"
}
!ifdef X16_USE_SCREEN {
    !source "video/screen.asm"
}
!ifdef X16_USE_PALETTE {
    !source "video/palette.asm"
}
