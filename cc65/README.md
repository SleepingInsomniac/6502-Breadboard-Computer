`brew install cc65`

# compilation:

## Long
```
cc65 -t none -O --cpu 65sc02 hello.c
ca65 --cpu 65sc02 hello.s
ca65 --cpu 65sc02 interrupt.s
ca65 --cpu 65sc02 vectors.s
ca65 --cpu 65sc02 wait.s
ca65 --cpu 65sc02 lcd.s
ld65 -C breadboard.cfg -m hello.map interrupt.o vectors.o wait.o lcd.o hello.o none.lib
```

## Short
```
cl65 -C breadboard.cfg -t none -O --cpu 65sc02 hello.c interrupt.s vectors.s wait.s lcd.s none.lib -o hello.out
```

## Editing the initialization for none.lib

```
ca65 crt0.s
ar65 a none.lib crt0.o
```
