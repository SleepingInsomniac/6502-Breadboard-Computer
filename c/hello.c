extern void __fastcall__ init_lcd();
extern void __fastcall__ lcd_show(char *str);

void main(void)
{
  init_lcd();
  lcd_show("Hello, World!");
}
