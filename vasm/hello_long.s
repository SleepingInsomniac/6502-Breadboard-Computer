; Does not require a stack, (no subroutines are possible)

; 65c02 CPU
ROMADDR = $fffc ; 65c02 ROM initial intstruction location address

; 65C22 interface adapter
PORTA = $6001 ; LCD MPU interface top 3 bits
PORTB = $6000 ; LEDs / LCD located on port B

DDRA = $6003 ; Data direction for port b
DDRB = $6002 ; Data direction for port a

; LCD display MPU interface
LCD_EN = %10000000 ; enable
LCD_RW = %01000000 ; read/write
LCD_RS = %00100000 ; register select

  .org $8000      ; rom is enabled for address line 15

reset:
  ; Initialize 65c22 interface adapter to interface with lcd
  lda #%11111111  ; Set Data pins to output for port b
  sta DDRB
  lda #%11100000  ; Set LCD MPU pins to output on 65c22
  sta DDRA

  ; initialize lcd
  lda #%00111000  ; LCD: 8bit mode, 1 line display, 5x8 char mode - p.40 of datasheet
  sta PORTB

  lda #0          ; clear LCD MPU bits
  sta PORTA

  lda #LCD_EN     ; make lcd update
  sta PORTA

  lda #0          ; clear LCD MPU bits
  sta PORTA


  lda #%00001110  ; display on, cursor on, blink off
  sta PORTB

  lda #0          ; clear LCD MPU bits
  sta PORTA

  lda #LCD_EN     ; make lcd update
  sta PORTA

  lda #0          ; clear LCD MPU bits
  sta PORTA


  lda #%00000110  ; inc & shift cursor, do not shift display
  sta PORTB

  lda #0          ; clear LCD MPU bits
  sta PORTA

  lda #LCD_EN     ; make lcd update
  sta PORTA

  lda #0          ; clear LCD MPU bits
  sta PORTA


  lda #"M"        ; Load H into a register
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA


  lda #"e"        ; Load H into a register
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA


  lda #"r"        ; Load H into a register
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA


  lda #"r"        ; Load H into a register
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA


  lda #"y"        ; Load H into a register
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA


  lda #" "        ; Load H into a register
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA


  lda #"C"        ; Load H into a register
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA


  lda #"h"        ; Load H into a register
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA


  lda #"r"        ; Load H into a register
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA


  lda #"i"        ; Load H into a register
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA


  lda #"s"        ; Load H into a register
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA


  lda #"t"        ; Load H into a register
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA


  lda #"m"        ; Load H into a register
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA


  lda #"a"        ; Load H into a register
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA


  lda #"s"        ; Load H into a register
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA


  lda #"!"        ; Load H into a register
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

loop:             ; blink and loop forever
  lda #%01010101
  sta PORTB

  NOP
  NOP
  NOP
  NOP
  NOP

  lda #%10101010
  sta PORTB
  jmp loop

  .org ROMADDR    ; CPU reads this address for where to start execution
  .word reset     ; ROM address begins
  .word $0000     ; EEPROM padding
