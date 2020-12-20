# 6502 Breadboard computer

## Minipro

macOS:

install: `brew install minipro`

program eeprom: `minipro -p AT28C256 -w a.out`

## vasm

`http://www.compilers.de/vasm.html`

build:

`make CPU=6502 SYNTAX=oldstyle`

## blink

build:

`vasm6502_oldstyle -Fbin -dotdir blink.s`
