; Instructions
lcd_clear_display               = %00000001
lcd_return_home                 = %00000010

lcd_entry_mode_decrement        = %00000100
lcd_entry_mode_decrement_shift  = %00000101
lcd_entry_mode_increment        = %00000110
lcd_entry_mode_increment_shift  = %00000111

; lcd_display = %00001 Display Cursor Blink
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
