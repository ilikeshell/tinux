#ifndef TINUX_CONST_H_
#define TINUX_CONST_H_

/* 函数类型 */
#define PUBLIC
#define PRIVATE static

/* 定义EXTERN宏 */
#define EXTERN extern

/* Boolean 类型  */
#define TRUE	1
#define FALSE	0

/* 主从两个8259A处理中断的个数 */
#define NR_IRQ 	16

/* 硬件中断 */
#define CLOCK_IRQ		0
#define KEYBOARD_IRQ	1
#define CASCADE_IRQ		2
#define ETHER_IRQ		3
#define SECONDARY_IRQ	3
#define RS232_IRQ		4
#define XT_WINI_IRQ		5
#define FLOPPY_IRQ		6
#define PRINTER_IRQ		7
#define AT_WINI_IRQ		14

/* 系统调用函数类型 */
typedef void*   system_call;

/* 系统调用的个数 */
#define NR_SYS_CALL		16

/* 8253可编程定时器 */
#define TIMER0			0x40
#define TIMER_MODE		0x43
#define RATE_GENERATOR	0x34
#define TIMER_FREQ		1193182L
#define HZ				100

/* 颜色 */
/*
 * e.g. MAKE_COLOR(BLUE, RED)
 *      MAKE_COLOR(BLACK, RED) | BRIGHT
 *      MAKE_COLOR(BLACK, RED) | BRIGHT | FLASH
 */
#define BLACK   0x0     /* 0000 */
#define WHITE   0x7     /* 0111 */
#define RED     0x4     /* 0100 */
#define GREEN   0x2     /* 0010 */
#define BLUE    0x1     /* 0001 */
#define FLASH   0x80    /* 1000 0000 */
#define BRIGHT  0x08    /* 0000 1000 */
#define MAKE_COLOR(x,y) (x | y) /* MAKE_COLOR(Background,Foreground) */



#endif