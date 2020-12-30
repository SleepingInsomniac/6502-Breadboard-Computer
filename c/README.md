`brew install cc65`

# compilation:

```
cc65 -t none -O --cpu 65sc02 hello.c
ca65 --cpu 65sc02 hello.s
ca65 --cpu 65sc02 interrupt.s
ca65 --cpu 65sc02 vectors.s
ca65 --cpu 65sc02 wait.s
ca65 --cpu 65sc02 lcd.s
ld65 -C breadboard.cfg -m hello.map interrupt.o vectors.o wait.o lcd.o hello.o sbc.lib
```
