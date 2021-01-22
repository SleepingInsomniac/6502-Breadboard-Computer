; $0000 - $00FF - STACK
; $0100 - $3FFF - RAM
; $6000 - $6FFF - 65c22
; $8000 - $8FFF - ROM

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

; RAM              ; enabled for addr LL-- ---- ---- ----
RAM_START = $0100  ; stack is ram from 00 - FF
SLEEP_COUNTER = $0100 ; 2 bytes

  .org $8000       ; rom is enabled for address line 15

reset:
  ; stack will begin at $FF
  ldx #$FF        ; Value to initialize the stack pointer at
  txs             ; transfer the x register value to the stack pointer

  ; Initialize 65c22 interface adapter to interface with lcd
  lda #%11111111  ; Set Data pins to output for port b
  sta DDRB
  lda #%11100000  ; Set LCD MPU pins to output on 65c22
  sta DDRA

  jsr init_lcd

print_string:
  ldx #0 ; initialize x as counter
printing:
  lda message, x      ; load the char into a
  beq done_printing   ; if the 0 flag is set due to null byte, string has ended
  jsr print_char      ; print the character in the a register
  inx                 ; step to next byte
  jmp printing        ; loop
done_printing:

main:
  jmp main ; loop forever

  .include "lcd.s" ; include lcd functions

message: .asciiz "Merry Christmas!"

  .org ROMADDR    ; CPU reads this address for where to start execution
  .word reset     ; ROM address begins
  .word $0000     ; EEPROM padding
