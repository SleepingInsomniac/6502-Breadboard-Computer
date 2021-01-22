  ; LCD busy flag check page 32
lcd_wait:
  pha             ; store a on stack, since we will modify it
  lda #%00000000  ; set port b to input
  sta DDRB
lcdbusy:          ; page 9 of datasheet
  lda #LCD_RW     ; set r/w for lcd
  sta PORTA
  lda #(LCD_RW | LCD_EN) ; rs low, rw high, enable high
  sta PORTA       ; store to lcd mpu
  lda PORTB       ; read port b db7 is 1 when busy
  and #%10000000  ; and reg a with high order bit
  bne lcdbusy     ; z flag set if portb db7 was 0, loop if not zero

  lda #LCD_RW     ; clear mpu enable bit
  sta PORTA
  lda #%11111111  ; set port b back to output
  sta DDRB
  pla             ; get prev a back off stack
  rts
