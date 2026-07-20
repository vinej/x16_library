;ACME
; =====================================================================
; x16lib example :: m_bounce.asm  (the macro edition of bounce.asm)
; =====================================================================
; The same bouncing-sprite demo as bounce.asm -- VSYNC lock, sprites,
; palette, 8.8 fixed point, AABB collision, PSG, YM2151 FM, tilemap text,
; number formatting -- rewritten to call the library through the optional
; friendly macro layer (core/sugar.asm).
;
; It is the honest showcase: the SETUP (one-shot, constant arguments) is
; nearly all one-line +xm_* macros, while the per-frame work on RUN-TIME
; values -- the sprite's live position, the decaying envelope volume, the
; collision boxes, the frame counter -- stays hand-written, because the
; macros load immediates. Both styles sit side by side.
;
;   .\build.ps1 -Source examples\m_bounce.asm -Run
;
; Needs real VSYNC -- run it windowed. Press any key to stop.
; =====================================================================

!cpu 65c02
!source "x16.asm"

X16_USE_VERA    = 1
X16_USE_SCREEN  = 1
X16_USE_SPRITE  = 1
X16_USE_PALETTE = 1
X16_USE_IRQ     = 1
X16_USE_FIXED   = 1
X16_USE_COLLIDE = 1
X16_USE_INPUT   = 1
X16_USE_NUMBER  = 1
X16_USE_PSG     = 1
X16_USE_YM      = 1
X16_USE_TILE    = 1

!source "core/sugar.asm"        ; the +xm_* macros (gated by the above)

SPRITE_VRAM = $13000            ; the KERNAL's sprite image area
SPRITE_SIZE = 16                ; 16x16 pixels

PLAY_W = 640
PLAY_H = 480

BOX_X = 304                     ; the target box, in display pixels
BOX_Y = 200
BOX_W = 80
BOX_H = 80

BOX_COL  = BOX_X / 8
BOX_ROW  = BOX_Y / 8
BOX_COLS = BOX_W / 8
BOX_ROWS = BOX_H / 8

BOX_CHAR = $A0                  ; reverse space, a solid cell
BOX_ATTR = $0E                  ; light blue on black

BLIP_VOICE  = 0
BLIP_FREQ   = 2362              ; ~880 Hz (A5)
BLIP_FRAMES = 15                ; envelope length; volume = frames * 4

FM_CHANNEL = 0
FM_PATCH   = 1                  ; a ROM instrument patch
FM_NOTE    = $44                ; (octave 4 << 4) | note 4, packed FMNOTE

* = $0801
    +basic_stub

; ---------------------------------------------------------------------
main
    +xm_screen_cls
    jsr draw_box
    +xm_sprite_init_all
    jsr build_sprite_image

    +xm_pal_set 2, $00F0        ; entry 2 = bright green (the sprite)

    ; sprite 0: the image, 16x16, 8bpp, in front of everything
    +xm_sprite_image 0, SPRITE_VRAM, SPRITE_MODE_8BPP
    +xm_sprite_size  0, SPRITE_SIZE_16, SPRITE_SIZE_16, 0
    +xm_sprite_flags 0, SPRITE_Z_FRONT

    +xm_sprites_on
    jsr init_audio
    +xm_irq_install

; ---------------------------------------------------------------------
loop
    +xm_vsync_wait              ; frame-locked: exactly 60 Hz

    jsr move_sprite
    jsr draw_sprite
    jsr check_collision
    jsr update_blip             ; advance the PSG envelope, once a frame

    +xm_key_get                 ; non-blocking
    beq loop

; ---------------------------------------------------------------------
done
    +xm_irq_remove
    jsr silence_audio
    +xm_sprites_off
    +xm_screen_cls
    rts

; =====================================================================
; Audio  (setup is constant -> macros)
; =====================================================================
init_audio
    +xm_psg_init                ; all 16 PSG voices to zero volume

    +xm_ym_init
    bcs @no_fm                  ; no YM present: run silently

    +xm_ym_patch_rom FM_CHANNEL, FM_PATCH
    +xm_ym_vol FM_CHANNEL, 0    ; attenuation 0 = the patch's own volume
    +xm_ym_pan FM_CHANNEL, 3    ; both speakers
@no_fm
    rts

silence_audio
    +xm_psg_init
    +xm_ym_release_note FM_CHANNEL
    rts

; start_blip -- retrigger the bounce sound (pitch + waveform are constant)
start_blip
    +xm_psg_set_freq BLIP_VOICE, BLIP_FREQ
    +xm_psg_set_wave BLIP_VOICE, PSG_WAVE_PULSE, 32   ; 50% duty
    lda #BLIP_FRAMES
    sta blip_timer
    rts

; update_blip -- one envelope step. The volume is COMPUTED each frame, so
; psg_set_vol is called by hand.
update_blip
    lda blip_timer
    beq @silent
    dec blip_timer
    lda blip_timer
    asl
    asl                         ; frames * 4, at most 60
    ldx #BLIP_VOICE
    ldy #PSG_PAN_BOTH
    jmp psg_set_vol
@silent
    lda #0
    ldx #BLIP_VOICE
    ldy #PSG_PAN_BOTH
    jmp psg_set_vol

; ---------------------------------------------------------------------
; Advance the position by the velocity, bouncing at the edges. Pure
; arithmetic on run-time state -- no library calls to wrap.
; ---------------------------------------------------------------------
move_sprite
    clc                         ; x += vx, 24-bit
    lda pos_x
    adc vel_x
    sta pos_x
    lda pos_x+1
    adc vel_x+1
    sta pos_x+1
    lda vel_x+1                 ; sign-extend the velocity's integer byte
    bmi @vx_neg
    lda #$00
    bra @vx_hi
@vx_neg
    lda #$FF
@vx_hi
    adc pos_x+2
    sta pos_x+2

    lda pos_x+2
    bmi @clamp_x_lo             ; gone negative
    lda pos_x+1                 ; pixel >= PLAY_W - SPRITE_SIZE ?
    cmp #<(PLAY_W - SPRITE_SIZE)
    lda pos_x+2
    sbc #>(PLAY_W - SPRITE_SIZE)
    bcc @y                      ; still inside
    lda #<(PLAY_W - SPRITE_SIZE - 1)
    sta pos_x+1
    lda #>(PLAY_W - SPRITE_SIZE - 1)
    sta pos_x+2
    stz pos_x
    jsr negate_vx
    bra @y
@clamp_x_lo
    stz pos_x
    stz pos_x+1
    stz pos_x+2
    jsr negate_vx

@y
    clc                         ; y += vy, 24-bit
    lda pos_y
    adc vel_y
    sta pos_y
    lda pos_y+1
    adc vel_y+1
    sta pos_y+1
    lda vel_y+1
    bmi @vy_neg
    lda #$00
    bra @vy_hi
@vy_neg
    lda #$FF
@vy_hi
    adc pos_y+2
    sta pos_y+2

    lda pos_y+2
    bmi @clamp_y_lo
    lda pos_y+1
    cmp #<(PLAY_H - SPRITE_SIZE)
    lda pos_y+2
    sbc #>(PLAY_H - SPRITE_SIZE)
    bcc @done                   ; still inside
    lda #<(PLAY_H - SPRITE_SIZE - 1)
    sta pos_y+1
    lda #>(PLAY_H - SPRITE_SIZE - 1)
    sta pos_y+2
    stz pos_y
    jsr negate_vy
    bra @done
@clamp_y_lo
    stz pos_y
    stz pos_y+1
    stz pos_y+2
    jsr negate_vy
@done
    rts

negate_vx
    sec
    lda #0
    sbc vel_x
    sta vel_x
    lda #0
    sbc vel_x+1
    sta vel_x+1
    jmp start_blip              ; every wall hit retriggers the blip

negate_vy
    sec
    lda #0
    sbc vel_y
    sta vel_y
    lda #0
    sbc vel_y+1
    sta vel_y+1
    jmp start_blip

; ---------------------------------------------------------------------
; draw_sprite -- the position is live, so sprite_pos is set by hand.
; ---------------------------------------------------------------------
draw_sprite
    lda pos_x+1                 ; the 16-bit pixel part, above the fraction
    sta X16_P0
    lda pos_x+2
    sta X16_P1
    lda pos_y+1
    sta X16_P2
    lda pos_y+2
    sta X16_P3
    ldx #0
    jmp sprite_pos

; ---------------------------------------------------------------------
; Software AABB against the target box. The A box is the sprite's live
; position, so collide16's operands are filled by hand; the text output
; uses macros for its constant parts.
; ---------------------------------------------------------------------
check_collision
    lda pos_x+1
    sta cl_ax
    lda pos_x+2
    sta cl_ax+1
    lda pos_y+1
    sta cl_ay
    lda pos_y+2
    sta cl_ay+1
    lda #SPRITE_SIZE
    sta cl_aw
    stz cl_aw+1
    lda #SPRITE_SIZE
    sta cl_ah
    stz cl_ah+1

    lda #<BOX_X
    sta cl_bx
    lda #>BOX_X
    sta cl_bx+1
    lda #<BOX_Y
    sta cl_by
    lda #>BOX_Y
    sta cl_by+1
    lda #<BOX_W
    sta cl_bw
    lda #>BOX_W
    sta cl_bw+1
    lda #<BOX_H
    sta cl_bh
    lda #>BOX_H
    sta cl_bh+1
    jsr collide16

    lda #0
    rol                         ; A = 1 when the boxes overlap
    sta hit

    jsr update_fm_note

    +xm_screen_locate 0, 0      ; home the cursor without clearing

    lda hit
    beq @miss
    +xm_screen_puts msg_hit
    bra @frames
@miss
    +xm_screen_puts msg_miss
@frames
    jsr irq_frames             ; the live frame counter (run-time)
    sta X16_P0
    stz X16_P1
    jsr u16_to_dec
    jsr screen_puts            ; A/X here is u16_to_dec's buffer, not a const
    +xm_screen_chrout ' '      ; scrub any digit left by a longer number
    +xm_screen_chrout ' '
    rts

; ---------------------------------------------------------------------
; update_fm_note -- play on the EDGE, not the level. Constant channel/note.
; ---------------------------------------------------------------------
update_fm_note
    lda hit
    cmp hit_prev
    beq @done                   ; no change: leave the note alone
    sta hit_prev
    lda hit_prev
    beq @release                ; just left the box
    +xm_ym_note_bas FM_CHANNEL, FM_NOTE
    rts
@release
    +xm_ym_release_note FM_CHANNEL
@done
    rts

; ---------------------------------------------------------------------
; draw_box -- the cell coordinates step at run time (box_i), so tile_put
; is called by hand inside the loops.
; ---------------------------------------------------------------------
draw_box
    lda #BOX_CHAR
    sta X16_P0
    lda #BOX_ATTR
    sta X16_P1

    lda #BOX_COL                ; top and bottom edges
    sta box_i
@horiz
    ldx box_i
    ldy #BOX_ROW
    jsr tile_put
    ldx box_i
    ldy #(BOX_ROW + BOX_ROWS - 1)
    jsr tile_put
    inc box_i
    lda box_i
    cmp #(BOX_COL + BOX_COLS)
    bne @horiz

    lda #BOX_ROW                ; left and right edges
    sta box_i
@vert
    ldx #BOX_COL
    ldy box_i
    jsr tile_put
    ldx #(BOX_COL + BOX_COLS - 1)
    ldy box_i
    jsr tile_put
    inc box_i
    lda box_i
    cmp #(BOX_ROW + BOX_ROWS)
    bne @vert
    rts

; ---------------------------------------------------------------------
; Paint a filled 16x16 block of colour 2 into the sprite image area.
; ---------------------------------------------------------------------
build_sprite_image
    +vera_addr 0, SPRITE_VRAM, VERA_INC_1
    +xm_vera_fill 2, SPRITE_SIZE * SPRITE_SIZE
    rts

; ---------------------------------------------------------------------
pos_x !byte $00
      !word 64                  ; 64.0 pixels
pos_y !byte $00
      !word 48                  ; 48.0 pixels
vel_x !word $0180               ; 1.5 px/frame
vel_y !word $00C0               ; 0.75 px/frame

hit        !byte 0
hit_prev   !byte 0
blip_timer !byte 0
box_i      !byte 0

msg_hit  !text "HIT  FRAME ", $00
msg_miss !text "---  FRAME ", $00

; ---------------------------------------------------------------------
!source "x16_code.asm"
