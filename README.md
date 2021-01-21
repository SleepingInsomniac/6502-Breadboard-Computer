# 6502 Breadboard computer

This repo is for the code related to my homebrew 6502 computer

## Minipro

minipro interfaces with the TL866ii programmer used to write to the EEPROM

- install: `brew install minipro`
- upload: `minipro -p AT28C256 -w a.out`

## Hardware

- wdc65c02s MPU
- AT28C256 EEPROM
- HM26256 SRAM
- wdc65c22s Interface adapter
