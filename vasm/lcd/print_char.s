print_char:
  jsr lcd_wait
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA
  rts
