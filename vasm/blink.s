  .org $8000      ; rom is enabled for address line 15

reset:
  ; Initialize interface adapter, all datapins will be set to output
  lda #$ff
  sta $6002

  lda #%01010101  ; Pattern of LEDs to blink
loop:
  sta $6000       ; store pattern on port b where leds are located
  ror             ; rotate the a register to the right
  jmp loop

  .org $fffc      ; CPU reads this address for where to start execution
  .word reset     ; ROM address begins
  .word $0000     ; padding
