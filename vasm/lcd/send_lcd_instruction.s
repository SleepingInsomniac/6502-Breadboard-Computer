  ; LCD instructions page 24
send_lcd_instruction:
  jsr lcd_wait
  sta PORTB
  lda #0          ; clear LCD MPU bits
  sta PORTA
  lda #LCD_EN     ; make lcd update
  sta PORTA
  lda #0          ; clear LCD MPU bits
  sta PORTA
  rts
