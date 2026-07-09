;ACME
; =====================================================================
; x16lib :: system/irq.asm -- VSYNC frame counter and IRQ hook
; =====================================================================
; This file EMITS CODE. Source it exactly once (x16_code.asm does).
;
; Chains onto the KERNAL's IRQ vector (CINV, $0314) rather than taking
; the interrupt over. Our handler bumps a frame counter and then jumps
; to whatever was there before, so the KERNAL still scans the keyboard,
; moves the mouse, blinks the cursor, and acknowledges the VERA VSYNC
; interrupt. We deliberately do NOT ack it ourselves.
;
; The KERNAL's stub has already pushed A/X/Y by the time it reaches
; CINV, and restores them on the way out, so a chained handler is free
; to clobber the registers.
;
; If you add work of your own to the per-frame path, keep it short and
; save/restore any VERA address port you touch -- an interrupt landing
; between a +vera_addr and its DATA access will otherwise move the port
; out from under you.
; =====================================================================

!zone x16_irq {

irq_old_vector  !word 0
irq_frame_count !byte 0
irq_armed       !byte 0

; ---------------------------------------------------------------------
; irq_handler -- runs once per frame, then chains
; ---------------------------------------------------------------------
irq_handler
    lda VERA_ISR
    and #VERA_IRQ_VSYNC
    beq @chain                  ; not a VSYNC: someone else's interrupt
    inc irq_frame_count
@chain
    jmp (irq_old_vector)

; ---------------------------------------------------------------------
; irq_install -- start counting frames. Idempotent.
; ---------------------------------------------------------------------
irq_install
    lda irq_armed
    bne @done

    sei
    lda CINV
    sta irq_old_vector
    lda CINV+1
    sta irq_old_vector+1
    lda #<irq_handler
    sta CINV
    lda #>irq_handler
    sta CINV+1
    stz irq_frame_count
    lda #VERA_IRQ_VSYNC
    tsb VERA_IEN                ; the KERNAL already enables it; harmless
    lda #1
    sta irq_armed
    cli
@done
    rts

; ---------------------------------------------------------------------
; irq_remove -- restore the previous handler
; ---------------------------------------------------------------------
irq_remove
    lda irq_armed
    beq @done
    sei
    lda irq_old_vector
    sta CINV
    lda irq_old_vector+1
    sta CINV+1
    stz irq_armed
    cli
@done
    rts

; ---------------------------------------------------------------------
; irq_frames
;   out: A = the frame counter (wraps at 256)
;
; Byte subtraction wraps correctly, so deltas are valid across the wrap:
;       jsr irq_frames : sta start
;       ... work ...
;       jsr irq_frames : sec : sbc start   ; = frames elapsed
; ---------------------------------------------------------------------
irq_frames
    lda irq_frame_count
    rts

; ---------------------------------------------------------------------
; vsync_wait -- block until the next frame boundary.
;
; Frame-locked: it waits for the counter to change rather than polling
; VERA, so it cannot miss a frame or spin twice within one. Requires
; irq_install, and interrupts enabled -- it will hang otherwise.
; ---------------------------------------------------------------------
vsync_wait
    lda irq_frame_count
@wait
    cmp irq_frame_count
    beq @wait
    rts

}   ; !zone x16_irq
