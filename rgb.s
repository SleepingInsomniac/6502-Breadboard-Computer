; Blink an rgb led on port a

; 65c02 CPU
ROMADDR = $fffc ; 65c02 ROM initial intstruction location address

; 65C22 interface adapter
PORTA = $6001 ; LCD MPU interface top 3 bits
PORTB = $6000 ; LEDs / LCD located on port B

DDRA = $6003 ; Data direction for port b
DDRB = $6002 ; Data direction for port a

; LED
L_R = %00000001
L_G = %00000010
L_B = %00000100

  .org $8000      ; rom is enabled for address line 15

reset:
  ; Initialize 65c22 interface adapter to interface
  lda #%00000111  ; LEDs on output
  sta DDRA

loop:             ; blink and loop forever
  lda #L_R
  sta PORTA

  lda #L_G
  sta PORTA

  lda #L_B
  sta PORTA

  jmp loop

  .org ROMADDR    ; CPU reads this address for where to start execution
  .word reset     ; ROM address begins
  .word $0000     ; EEPROM padding
