.export  _init_lcd, _send_lcd_instr, _lcd_wait, _lcd_print
.import  __DDRA__, __DDRB__, __PORTA__, __PORTB__ ; Defined in breadboard.cfg

.zeropage
_lcd_print_data:    .res 2, $00      ;  Reserve a local zero page pointer

.segment "CODE"

; LCD display MPU interface
LCD_EN = %10000000 ; enable
LCD_RW = %01000000 ; read/write
LCD_RS = %00100000 ; register select

; Initialize 65c22 interface adapter to interface with lcd
  lda #%11111111  ; Set Data pins to output for port b
  sta __DDRB__
  lda #%11100000  ; Set LCD MPU pins to output on 65c22
  sta __DDRA__

_init_lcd:
  ; lcd function set 001 DL N F * *
  lda #%00111000  ; LCD: 8bit mode, 1 line display, 5x8 char mode - p.40 of datasheet
  jsr _send_lcd_instr

  ; display control 00001 D C B
  lda #%00001100  ; display on, cursor on, blink off
  jsr _send_lcd_instr

  ; entry mode set 0000 01 i/d s
  lda #%00000110  ; inc & shift cursor, do not shift display
  jsr _send_lcd_instr

  lda #%00000001  ; clear display
  jsr _send_lcd_instr

  lda #%00000010  ; return home
  jsr _send_lcd_instr

; LCD instructions page 24
_send_lcd_instr:
  jsr _lcd_wait
  sta __PORTB__
  lda #0          ; clear LCD MPU bits
  sta __PORTA__
  lda #LCD_EN     ; make lcd update
  sta __PORTA__
  lda #0          ; clear LCD MPU bits
  sta __PORTA__
  rts

; LCD busy flag check page 32
_lcd_wait:
  pha             ; store a on stack, since we will modify it
  lda #%00000000  ; set port b to input
  sta __DDRB__
lcdbusy:          ; page 9 of datasheet
  lda #LCD_RW     ; set r/w for lcd
  sta __PORTA__
  lda #(LCD_RW | LCD_EN) ; rs low, rw high, enable high
  sta __PORTA__   ; store to lcd mpu
  lda __PORTB__   ; read port b db7 is 1 when busy
  and #%10000000  ; and reg a with high order bit
  bne lcdbusy     ; z flag set if portb db7 was 0, loop if not zero

  lda #LCD_RW     ; clear mpu enable bit
  sta __PORTA__
  lda #%11111111  ; set port b back to output
  sta __DDRB__
  pla             ; get prev a back off stack
  rts

_lcd_print:
  ldx #0          ; load x with index 0
printing:
  sta _lcd_print_data      ; reg a has pointer to data
  lda _lcd_print_data, x   ; load a with character at offset x
  beq message_ended        ; return if null byte
  jsr print_char
  inx                      ; increment x to next character
  jmp printing
message_ended:
  rts

print_char:
  jsr _lcd_wait
  sta __PORTB__
  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta __PORTA__
  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta __PORTA__
  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta __PORTA__
  rts
