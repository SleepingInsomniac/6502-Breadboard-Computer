  .org $8000      ; rom is enabled for address line 15

reset:
  ; Initialize interface adapter, all datapins will be set to output
  lda #$ff 
  sta $6002 
  ldx #%00000000  ; Pattern of LEDs to blink
  stx $6000       ; location of leds

loop:
  inx
  stx $6000
  ;lda #%01010101  ; Pattern of LEDs to blink
  ;sta $6000
  ;ror             ; rotate the a register to the right
  ;sta $6000       ; store the updated register to the LEDs
  jmp loop

  .org $fffc      ; CPU reads this address for where to start execution
  .word reset     ; ROM address begins
  .word $0000     ; padding
