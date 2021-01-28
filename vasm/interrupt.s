; $0200 - $3FFF - [RAM] hm62256b
; $6000 - $600F - [interface adapter] w65c22s
;   $6000 - $6001 - [LCD] HD44780
PORTB = $6000 ; LEDs / LCD located on port B
PORTA = $6001 ; LCD MPU interface top 3 bits
DDRB  = $6002 ; Data direction for port a
DDRA  = $6003 ; Data direction for port b
T1C_L = $6004 ; T1 Low-order latches / counter
TIC_H = $6005 ; T1 High-order counter
T1L_L = $6006 ; T1 Low-order latches
TIL_H = $6007 ; T1 High-order latches
T2C_L = $6008 ; T2 Low-order latches / counter
T2C_H = $6009 ; T2 High-order counter
SR    = $600A ; Shift register
ACR   = $600B ; Auxiliary Control Register
PCR   = $600C ; Peripheral Control Register
IFR   = $600D ; Interrupt Flag register
IER   = $600E ; Interrupt Enable Register
; $6010 - $6FFF x Unused
; $8000 - $8FFF - [ROM] 28c256

; Interrupt register flags
ifr_irq = %10000000 ; Any interrupt
ifr_t1  = %01000000 ; timer 1
ifr_t2  = %00100000 ; timer 2
ifr_cb1 = %00010000 ; CB1
ifr_cb2 = %00001000 ; CB2
ifr_sr  = %00000100 ; Shift register
ifr_ca1 = %00000010 ; CA1
ifr_ca2 = %00000001 ; CA2

; Variables
value     = $0200   ; 2 bytes
mod10     = $0202   ; 2 bytes
message   = $0204   ; 6 bytes
counter   = $020A   ; 2 bytes

  .org $8000 ; rom is enabled for address line 15

reset:
  ; stack will begin at $FF
  ldx #$FF        ; Value to initialize the stack pointer at
  txs             ; transfer the x register value to the stack pointer

  ; set up interrupt handling
  cli ; clear interrupt disable bit 6502
  lda %10000010 ; set CA1 interrupt enable on 6522
  sta IER
  lda #0
  sta PCR ; set CA1 control (bit 0) - negative active edge

  jsr init_lcd

  ; Initialize counter to 0
  lda #0
  sta counter
  sta counter + 1

main:
  lda lcd_clear_display
  jsr send_lcd_instruction

  ; Initialize message string with null byte
  lda #0
  sta message

print_number:
  ; Load the number into ram
  lda counter
  sta value
  lda counter + 1
  sta value + 1

divide:
  ; initialize remainder to 0
  lda #0
  sta mod10
  sta mod10 + 1

  ldx #16 ; count 16 bytes
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

nmi:
  rti

irq:
  inc counter
  bne exit_irq
  inc counter + 1
exit_irq:
  bit PORTA ; bit test (reads port a which clears the interrupt)
  rti

vectors:          ; Page 12
  .org $FFFA
  .word nmi       ; Non-maskable interrupt
  .word reset     ; reset vector - ROM address begins
  .word irq       ; interrupt request
