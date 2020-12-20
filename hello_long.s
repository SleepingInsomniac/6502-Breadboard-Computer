; 65c02 CPU
ROMADDR = $fffc ; 65c02 ROM initial intstruction location address

; 65C22 interface adapter
PORTA = $6000 ; LEDs / LCD located on port a
PORTB = $6001

DDRA = $6002 ; Data direction for port a
DDRB = $6003 ; Data direction for port b

  .org $8000      ; rom is enabled for address line 15

reset:
  ; Initialize interface adapter, all datapins will be set to output
  lda #%11111111 
  sta DDRA

  ldx #%00000000  ; Pattern of LEDs to blink
  stx PORTA       ; location of leds

loop:
  inx
  stx PORTA
  jmp loop

  .org ROMADDR    ; CPU reads this address for where to start execution
  .word reset     ; ROM address begins
  .word $0000     ; EEPROM padding
