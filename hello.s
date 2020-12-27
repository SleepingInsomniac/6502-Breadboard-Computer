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

init_lcd:
  ; lcd function set 001 DL N F * *
  lda #%00111000  ; LCD: 8bit mode, 1 line display, 5x8 char mode - p.40 of datasheet
  jsr send_lcd_instr

  ; display control 00001 D C B
  lda #%00001100  ; display on, cursor on, blink off
  jsr send_lcd_instr

  ; entry mode set 0000 01 i/d s
  lda #%00000110  ; inc & shift cursor, do not shift display
  jsr send_lcd_instr

  lda #%00000001  ; clear display
  jsr send_lcd_instr

  lda #%00000010  ; return home
  jsr send_lcd_instr

  ldx #0
print_message:
  lda message, x
  beq loop
  jsr print_char
  inx
  jmp print_message

loop:             ; blink and loop forever
  lda #%01010101
  sta PORTB

  lda #$08        ; sleep
  jsr sleep

  lda #%10101010
  sta PORTB

  lda #$08        ; sleep
  jsr sleep

;  lda #%10000000 ; sweep this pattern across the leds
;  ldx #8         ; rotate x times
;sweep:
;  sta PORTB      ; put A into LEDs
;  rol            ; rotate a register
;  pha            ; store a on the stack

 ; lda #$01       ; sleep
;  jsr sleep

;  pla            ; pull stack onto a, this should be led pattern
;  dex            ; decrement x
;  cpx #0         ; set zero flag if x is 0
;  bne sweep      ; if x is not 0 jmp to sweep

  jmp loop ; loop forever

print_char:
  jsr lcd_wait
  sta PORTB

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA

  lda #(LCD_RS | LCD_EN) ; make lcd update
  sta PORTA

  lda #LCD_RS     ; clear LCD MPU bits, except LCD data register select
  sta PORTA
  rts

  ; LCD instructions page 24
send_lcd_instr:
  jsr lcd_wait
  sta PORTB
  lda #0          ; clear LCD MPU bits
  sta PORTA
  lda #LCD_EN     ; make lcd update
  sta PORTA
  lda #0          ; clear LCD MPU bits
  sta PORTA
  rts

  ; LCD busy flag check page 32
lcd_wait:
  pha             ; store a on stack, since we will modify it
  lda #%00000000  ; set port b to input
  sta DDRB
lcdbusy:          ; page 9 of datasheet
  lda #LCD_RW     ; set r/w for lcd
  sta PORTA
  lda #(LCD_RW | LCD_EN) ; rs low, rw high, enable high
  sta PORTA       ; store to lcd mpu
  lda PORTB       ; read port b db7 is 1 when busy
  and #%10000000  ; and reg a with high order bit
  bne lcdbusy     ; z flag set if portb db7 was 0, loop if not zero

  lda #LCD_RW     ; clear mpu enable bit
  sta PORTA
  lda #%11111111  ; set port b back to output
  sta DDRB
  pla             ; get prev a back off stack
  rts

sleep:
  pha
  txa
  pha
  tya
  pha
  tax             ; transfer a to x
sleeping:
  dex             ; decrement x
  ldy #$FF
delay:
  dey
  tya
  bne delay

  txa             ; get x back in a
  bne sleeping    ; zero flag not set yet
  pla
  tay
  pla
  tax
  pla
  rts             ; done sleeping

message: .asciiz "Merry Christmas!"

  .org ROMADDR    ; CPU reads this address for where to start execution
  .word reset     ; ROM address begins
  .word $0000     ; EEPROM padding