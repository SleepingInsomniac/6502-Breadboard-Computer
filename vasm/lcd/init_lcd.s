init_lcd:
  pha ; save a on the stack

  ; Initialize 65c22 interface adapter to interface with lcd
  lda #%11111111  ; Set Data pins to output for port b
  sta DDRB
  lda #%11100000  ; Set LCD MPU pins to output on 65c22
  sta DDRA

  ; lcd function set 001 DL N F * *
  lda #%00111000  ; LCD: 8bit mode, 1 line display, 5x8 char mode - p.40 of datasheet
  jsr send_lcd_instruction

  ; display control 00001 D C B
  lda #%00001100  ; display on, cursor off, blink off
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
