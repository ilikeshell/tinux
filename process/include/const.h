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

/* number of GDT and IDT table entries */
#define GDT_SIZE	128
#define IDT_SIZE	256

/* 定义特权级 */
#define PRIVILEGE_KRNL	0
#define PRIVILEGE_TASK	1
#define PRIVILEGE_USER	3

/* RPL */
#define RPL_KRNL	SA_RPL0
#define RPL_TASK	SA_RPL1
#define RPL_USER	SA_RPL3

#endif
