#include<tinux.h>

//klib.asm
PUBLIC void out_byte(u16 port, u8 value);
PUBLIC void in_byte(u16 port);
PUBLIC void disp_str(char *info);
PUBLIC void disp_color_str(char *info, u8 text_color);
PUBLIC void disp_int(u32 input);

//klib.c
PUBLIC void delay(int time);
PUBLIC char* itoa(char *str, u32 num);
PUBLIC void disp_int(u32 input);

//main.c
void TestA();
