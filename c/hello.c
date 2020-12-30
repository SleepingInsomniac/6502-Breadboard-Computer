extern void __fastcall__ init_lcd();
extern void __fastcall__ lcd_print(char *str);

void main(void)
{
  init_lcd();
  lcd_print("Hello, World!");
}
