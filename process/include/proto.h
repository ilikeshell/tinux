#include<tinux.h>

//klib.asm
PUBLIC void out_byte(u16 port, u8 value);
PUBLIC void in_byte(u16 port);
PUBLIC void disp_str(char *info);
PUBLIC void disp_color_str(char *info, u8 text_color);
PUBLIC void disable_irq(int irq);
PUBLIC void enable_irq(int irq);

PUBLIC void delay(int time);

//klib.c
PUBLIC void delay(int time);
PUBLIC char* itoa(char *str, u32 num);
PUBLIC void disp_int(u32 input);

//main.c
void TestA();
void TestB();
void TestC();

//clock.c
PUBLIC void clock_handler(int irq);

/* 以下时系统调用相关 */
/* proc.c */
PUBLIC int sys_get_ticks();
/* syscall.asm */
PUBLIC void sys_call();
PUBLIC int get_ticks();
