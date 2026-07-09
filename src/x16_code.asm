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
;   X16_USE_SPRITE    sprites_on/off, sprite_pos, sprite_get_pos,
;                     sprite_image, sprite_flags, sprite_z, sprite_size,
;                     sprite_init_all          (requires X16_USE_VERA)
;   X16_USE_FIXED     umul16, mul88
;   X16_USE_COLLIDE   collide8
; =====================================================================

; Gates are set with !ifndef so that asking for a module twice -- say via
; X16_USE_ALL and again through a dependency -- is not a redefinition
; error, and so an explicit X16_USE_* in your program still works.
!ifdef X16_USE_ALL {
    !ifndef X16_USE_VERA    { X16_USE_VERA    = 1 }
    !ifndef X16_USE_SCREEN  { X16_USE_SCREEN  = 1 }
    !ifndef X16_USE_PALETTE { X16_USE_PALETTE = 1 }
    !ifndef X16_USE_SPRITE  { X16_USE_SPRITE  = 1 }
    !ifndef X16_USE_FIXED   { X16_USE_FIXED   = 1 }
    !ifndef X16_USE_COLLIDE { X16_USE_COLLIDE = 1 }
}

; Dependencies. sprite_init_all calls vera_fill, so pulling in sprites
; pulls in the VERA module too.
!ifdef X16_USE_SPRITE {
    !ifndef X16_USE_VERA { X16_USE_VERA = 1 }
}

!ifdef X16_USE_VERA {
    !source "video/vera.asm"
}
!ifdef X16_USE_SCREEN {
    !source "video/screen.asm"
}
!ifdef X16_USE_PALETTE {
    !source "video/palette.asm"
}
!ifdef X16_USE_SPRITE {
    !source "sprite/sprite.asm"
}
!ifdef X16_USE_FIXED {
    !source "util/fixed.asm"
}
!ifdef X16_USE_COLLIDE {
    !source "util/collide.asm"
}
