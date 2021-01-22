; $0200 - $3FFF - [RAM] hm62256b
; $6000 - $600F - [interface adapter] w65c22s
;   $6000 - $6001 - [LCD] HD44780
PORTA = $6001 ; LCD MPU interface top 3 bits
PORTB = $6000 ; LEDs / LCD located on port B
DDRA  = $6003 ; Data direction for port b
DDRB  = $6002 ; Data direction for port a
; $6010 - $6FFF x Unused
; $8000 - $8FFF - [ROM] 28c256

value     = $0200   ; 2 bytes
mod10     = $0202   ; 2 bytes
message   = $0204   ; 6 bytes

  .org $8000       ; rom is enabled for address line 15

reset:
  ; stack will begin at $FF
  ldx #$FF        ; Value to initialize the stack pointer at
  txs             ; transfer the x register value to the stack pointer

  jsr init_lcd

  ; Initialize message string with null byte
  lda #0
  sta message

print_number:
  ; Load the number into ram
  lda number
  sta value
  lda number + 1
  sta value + 1

divide:
  ; initialize remainder to 0
  lda #0
  sta mod10
  sta mod10 + 1

  ldx #16
divloop:
  ; rotate quotient and remainder
  rol value
  rol value + 1
  rol mod10
  rol mod10 + 1

  sec                ; set the carry bit of the Processor Status Register (P)
  lda mod10
  sbc #10            ; subtract 10 from a register with borrow (2 bytes)
  tay                ; save low byte in y
  lda mod10 + 1
  sbc #0             ; finalize subtraction with high order byte
  bcc ignore_result  ; branch if the carry is clear
  sty mod10          ; store result
  sta mod10 + 1
ignore_result:
  dex
  bne divloop        ; loop if x is 0 (loop 16 times in total for 16 bit number)
  rol value          ; shift in the last bit of the quotient
  rol value + 1

  lda mod10          ; load the digit into a
  clc                ; clear carry bit
  adc #"0"           ; Add a to 0 to get the ascii representation of the digit
  jsr shift_char

  ; check if value is 0, otherwise keep finding digits
  lda value          ; load a with our value
  ora value + 1      ; bitwise or a with second byte
  bne divide         ; branch if value not zero

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

; Add the character in the A register to the message string
shift_char:
  pha              ; push char onto stack
  ldy #0           ; initialize index into message
char_loop:
  lda message, y   ; get char on string at y
  tax              ; take character from y offset and store in x
  pla              ; pull stored caracter from stack
  sta message, y   ; add the character back
  iny              ; next char
  txa              ; get original char back to a
  pha              ; store it on the stack
  bne char_loop
  pla              ; pull null terminator off stack
  sta message, y   ; terminate string
  rts

  .include "lcd.s" ; include lcd functions

number: .word 1989

  .org $FFFC      ; CPU reads this address for where to start execution
  .word reset     ; reset vector - ROM address begins
  .word $0000     ; EEPROM padding
