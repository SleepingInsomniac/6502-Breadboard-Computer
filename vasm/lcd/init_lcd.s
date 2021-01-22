init_lcd:
  pha ; save a on the stack

  ; lcd function set 001 DL N F * *
  lda #%00111000  ; LCD: 8bit mode, 1 line display, 5x8 char mode - p.40 of datasheet
  jsr send_lcd_instruction

  ; display control 00001 D C B
  lda #%00001100  ; display on, cursor on, blink off
  jsr send_lcd_instruction

  ; entry mode set 0000 01 i/d s
  lda #%00000110  ; inc & shift cursor, do not shift display
  jsr send_lcd_instruction

  lda #%00000001  ; clear display
  jsr send_lcd_instruction

  lda #%00000010  ; return home
  jsr send_lcd_instruction

  pla ; get a back off the stack
  rts ; return subroutine
