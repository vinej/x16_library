;ACME
; =====================================================================
; x16lib example :: bounce.asm
; =====================================================================
; A frame-locked sprite bouncing around the screen, driven by 8.8
; fixed-point velocity, with collision against a target box.
;
; Exercises: VSYNC frame lock, sprites, palette, 8.8 fixed point, AABB
; collision, tilemap text, and number formatting.
;
;   .\build.ps1 -Source examples\bounce.asm -Run
;
; Press any key to stop.
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

SPRITE_VRAM = $13000            ; the KERNAL's sprite image area
SPRITE_SIZE = 16                ; 16x16 pixels

; The position is one 8.8 word per axis, so its integer part only spans
; 0..255. That is enough for a demo; a full 320-wide field would need a
; 24-bit position (8 fractional bits plus a 16-bit pixel coordinate).
PLAY_W = 256
PLAY_H = 240

; The target box the sprite collides with, in pixels.
BOX_X = 150
BOX_Y = 100
BOX_W = 40
BOX_H = 40

* = $0801
    +basic_stub

; ---------------------------------------------------------------------
main
    jsr screen_cls
    jsr sprite_init_all
    jsr build_sprite_image

    ; Make palette entry 2 a bright green so the sprite stands out.
    ldx #2
    lda #$F0                    ; green<<4 | blue
    ldy #$00                    ; red
    jsr pal_set

    ; Point sprite 0 at the image, 16x16, in front of everything.
    lda #<SPRITE_VRAM
    sta X16_P0
    lda #>SPRITE_VRAM
    sta X16_P1
    lda #^SPRITE_VRAM
    sta X16_P2
    ldx #0
    lda #SPRITE_MODE_8BPP
    jsr sprite_image

    ldx #0
    lda #SPRITE_SIZE_16         ; width
    ldy #SPRITE_SIZE_16         ; height
    stz X16_P0                  ; palette offset
    jsr sprite_size

    ldx #0
    lda #SPRITE_Z_FRONT
    jsr sprite_flags

    jsr sprites_on
    jsr irq_install

; ---------------------------------------------------------------------
loop
    jsr vsync_wait              ; frame-locked: exactly 60 Hz

    jsr move_sprite
    jsr draw_sprite
    jsr check_collision

    jsr key_get                 ; non-blocking
    beq loop

; ---------------------------------------------------------------------
done
    jsr irq_remove
    jsr sprites_off
    jsr screen_cls
    rts

; ---------------------------------------------------------------------
; Advance the 8.8 position by the 8.8 velocity, bouncing at the edges.
; The integer part (the high byte) is the pixel coordinate.
; ---------------------------------------------------------------------
move_sprite
    clc                         ; x += vx
    lda pos_x
    adc vel_x
    sta pos_x
    lda pos_x+1
    adc vel_x+1
    sta pos_x+1

    lda pos_x+1                 ; bounce off the left and right edges
    beq @bounce_x
    cmp #(PLAY_W - SPRITE_SIZE)
    bcc @y
@bounce_x
    jsr negate_vx

@y
    clc                         ; y += vy
    lda pos_y
    adc vel_y
    sta pos_y
    lda pos_y+1
    adc vel_y+1
    sta pos_y+1

    lda pos_y+1
    beq @bounce_y
    cmp #(PLAY_H - SPRITE_SIZE)
    bcc @done
@bounce_y
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
    rts

negate_vy
    sec
    lda #0
    sbc vel_y
    sta vel_y
    lda #0
    sbc vel_y+1
    sta vel_y+1
    rts

; ---------------------------------------------------------------------
draw_sprite
    lda pos_x+1                 ; integer part of the 8.8 position
    sta X16_P0
    stz X16_P1
    lda pos_y+1
    sta X16_P2
    stz X16_P3
    ldx #0
    jmp sprite_pos

; ---------------------------------------------------------------------
; Software AABB against the target box. Print HIT or --- at the top
; left, plus the frame counter, so the frame lock is visible.
; ---------------------------------------------------------------------
check_collision
    lda pos_x+1
    sta X16_P0
    lda pos_y+1
    sta X16_P1
    lda #SPRITE_SIZE
    sta X16_P2
    sta X16_P3
    lda #BOX_X
    sta X16_P4
    lda #BOX_Y
    sta X16_P5
    lda #BOX_W
    sta X16_P6
    lda #BOX_H
    sta X16_P7
    jsr collide8

    ; Capture the result NOW. screen_locate does clc before jumping into
    ; PLOT, so the carry collide8 returned would be gone by the time we
    ; branched on it.
    lda #0
    rol                         ; A = 1 when the boxes overlap
    sta hit

    ldx #0                      ; home the cursor without clearing
    ldy #0
    jsr screen_locate

    lda hit
    beq @miss
    lda #<msg_hit
    ldx #>msg_hit
    bra @print
@miss
    lda #<msg_miss
    ldx #>msg_miss
@print
    jsr screen_puts

    jsr irq_frames              ; and the live frame counter
    sta X16_P0
    stz X16_P1
    jsr u16_to_dec
    jsr screen_puts
    lda #' '                    ; scrub any digit left by a longer number
    jsr screen_chrout
    lda #' '
    jmp screen_chrout

; ---------------------------------------------------------------------
; Paint a filled 16x16 block of colour 2 into the sprite image area.
; ---------------------------------------------------------------------
build_sprite_image
    +vera_addr 0, SPRITE_VRAM, VERA_INC_1
    lda #2                      ; palette index
    ldx #<(SPRITE_SIZE * SPRITE_SIZE)
    ldy #>(SPRITE_SIZE * SPRITE_SIZE)
    jmp vera_fill

; ---------------------------------------------------------------------
; 8.8 fixed point: the low byte is the fraction, the high byte the pixel.
; vel_x = $0180 = 1.5 px/frame, vel_y = $00C0 = 0.75 px/frame.
; ---------------------------------------------------------------------
pos_x !word $2000               ; 32.0
pos_y !word $1000               ; 16.0
vel_x !word $0180
vel_y !word $00C0
hit   !byte 0

msg_hit  !text "HIT  FRAME ", $00
msg_miss !text "---  FRAME ", $00

; ---------------------------------------------------------------------
!source "x16_code.asm"
