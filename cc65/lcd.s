.export  _init_lcd, _send_lcd_instr, _lcd_wait, _lcd_print
.import  __DDRA__, __DDRB__, __PORTA__, __PORTB__ ; Defined in breadboard.cfg

.zeropage
_lcd_print_data:    .res 2 ;  Reserve a local zero page pointer

.segment "CODE"

; LCD display MPU interface
LCD_EN = %10000000 ; enable
LCD_RW = %01000000 ; read/write
LCD_RS = %00100000 ; register select

_init_lcd:
  ; Initialize 65c22 interface adapter to interface with lcd
  lda #%11111111  ; Set Data pins to output for port b
  sta __DDRB__
  lda #%11100000  ; Set LCD MPU pins to output on 65c22
  sta __DDRA__

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
  rts

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

; Pointer to data passed in on a, x
_lcd_print:
  sta _lcd_print_data        ; store low order byte pointer address
  stx _lcd_print_data + 1    ; high order byte
  ldy #0                     ; reset counter
printing:
  lda (_lcd_print_data), y   ; get 8bit char data at 16bit address stored at _lcd_print_data with offset
  stx __PORTB__
  beq message_ended          ; return if null byte
  jsr _print_char            ; wait for lcd, store to port b, enable lcd read, etc.
  iny                        ; increment counter to next character
  jmp printing
message_ended:
  rts

; Print char on reg a to lcd
_print_char:
  jsr _lcd_wait
  sta __PORTB__
  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta __PORTA__
  lda #(LCD_RS | LCD_EN) ; select lcd data register, r/w low (read), enable lcd
  sta __PORTA__
  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta __PORTA__
  rts
