; $0200 - $3FFF - [RAM] hm62256b
; $6000 - $600F - [interface adapter] w65c22s
;   $6000 - $6001 - [LCD] HD44780
PORTA = $6001 ; LCD MPU interface top 3 bits
PORTB = $6000 ; LEDs / LCD located on port B
DDRA  = $6003 ; Data direction for port b
DDRB  = $6002 ; Data direction for port a
; $6010 - $6FFF x Unused
; $8000 - $8FFF - [ROM] 28c256

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

  .org $FFFC      ; CPU reads this address for where to start execution
  .word reset     ; reset vector - ROM address begins
  .word $0000     ; EEPROM padding
