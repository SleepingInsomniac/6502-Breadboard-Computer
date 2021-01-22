; LCD display MPU interface
LCD_EN = %10000000 ; enable
LCD_RW = %01000000 ; read/write
LCD_RS = %00100000 ; register select

  .include "lcd/init_lcd.s"
  .include "lcd/print_char.s"
  .include "lcd/send_lcd_instruction.s"
  .include "lcd/lcd_wait.s"
