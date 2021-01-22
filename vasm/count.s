; Counts in binary output on port b

; 65c02 CPU
ROMADDR = $fffc ; 65c02 ROM initial intstruction location address

; 65C22 interface adapter
PORTA = $6001 ; LCD MPU interface top 3 bits
PORTB = $6000 ; LEDs / LCD located on port B

DDRA = $6003 ; Data direction for port b
DDRB = $6002 ; Data direction for port a

  .org $8000      ; rom is enabled for address line 15

reset:
  ; Initialize interface adapter, all datapins will be set to output
  lda #%11111111
  sta DDRB

  ldx #%00000000  ; Pattern of LEDs to blink
  stx PORTB       ; location of leds

loop:
  inx
  stx PORTB
  jmp loop

  .org ROMADDR    ; CPU reads this address for where to start execution
  .word reset     ; ROM address begins
  .word $0000     ; EEPROM padding
