/* 如果定义了GLOBAL_VARIABLES_HERE，就把EXTERN定义为空 */
#ifdef GLOBAL_VARIABLES_HERE
#undef EXTERN
#define EXTERN 
#endif

#include<tinux.h>
#include<proc.h>

EXTERN int test;
EXTERN int disp_pos;
EXTERN u8 gdt_ptr[6];
EXTERN DESCRIPTOR gdt[GDT_SIZE];
EXTERN u8 idt_ptr[6];
EXTERN GATE idt[IDT_SIZE];
EXTERN int k_reenter;
EXTERN int ticks;

EXTERN TSS	tss;
EXTERN PROCESS* p_proc_ready;

extern PROCESS proc_table[];
extern char task_stack[];
extern TASK task_table[];
extern irq_handler irq_table[NR_IRQ];


PUBLIC void init_disp_pos();
PUBLIC void restart();

