/*
 * 	main.c
 *	创建第一个进程
 *  Created on: 2015年9月7日
 *  Author: kaiyan
 */
#include<tinux.h>
#include<global.h>
#include<proc.h>

void TestA()
{
	int i = 0x1;

	while(1)
	{
		disp_str("A.");
		//disp_int(get_ticks());
		//disp_str(".");
		milli_delay(200);
	}
}

void TestB()
{
	int i = 0x1000;
	while(1)
	{
		disp_str("B.");
		//disp_int(i++);
		//disp_str(".");
		milli_delay(200);
	}
}

void TestC()
{
	int i = 0x2000;
	while(1)
	{
		disp_str("C.");
		//disp_int(i++);
		//disp_str(".");
		milli_delay(200);
	}
}

PUBLIC int kernel_main()
{
	int i;

	disp_str("------\"kernel_main\" begins-----\n");

	TASK *p_task	= task_table;
	PROCESS *p_proc = proc_table;
	char *p_task_stack = task_stack + STACK_SIZE_TOTAL;
	u16 selector_ldt= SELECTOR_LDT_FIRST;

	put_irq_handler(CLOCK_IRQ, clock_handler);
	enable_irq(CLOCK_IRQ);
	//out_byte(INT_M_CTLMASK, 0xFE);
	/* 初始化8253 PIT */
	out_byte(TIMER_MODE, RATE_GENERATOR);
	out_byte(TIMER0, (u8)(TIMER_FREQ/HZ));
	out_byte(TIMER0, (u8)((TIMER_FREQ/HZ) >> 8));

	for(i = 0; i < NR_TASKS; i++)
	{
		//在进程表中填充名字
		strcpy(p_proc->p_name, p_task->name);
		p_proc->pid = i;

		p_proc->ldt_sel = selector_ldt;

		//初始化LDT表，后续还需在GDT中登记
		memcpy(&p_proc->ldts[0], &gdt[INDEX_FLAT_C], sizeof(DESCRIPTOR));
		p_proc->ldts[0].attr1 = DA_C | PRIVILEGE_TASK;
		memcpy(&p_proc->ldts[1], &gdt[INDEX_FLAT_RW], sizeof(DESCRIPTOR));
		p_proc->ldts[1].attr1 = DA_DRW | PRIVILEGE_TASK;

		// set registers
		p_proc->regs.cs = (0 & SA_RPL_MASK & SA_TI_MASK)| SA_TIL | RPL_TASK;
		p_proc->regs.ds = (8 & SA_RPL_MASK & SA_TI_MASK)| SA_TIL | RPL_TASK;
		p_proc->regs.es = (8 & SA_RPL_MASK & SA_TI_MASK)| SA_TIL | RPL_TASK;
		p_proc->regs.fs = (8 & SA_RPL_MASK & SA_TI_MASK)| SA_TIL | RPL_TASK;
		p_proc->regs.ss = (8 & SA_RPL_MASK & SA_TI_MASK)| SA_TIL | RPL_TASK;
		p_proc->regs.gs = (SELECTOR_KERNEL_GS & SA_RPL_MASK) | RPL_TASK;
		p_proc->regs.eip = (u32)p_task->init_eip;
		p_proc->regs.esp = (u32)p_task_stack;
		p_proc->regs.eflags = 0x1202;     //IF=1, IOPL=1; bit w is always 1.

		selector_ldt += 1 << 3;
		p_task++;
		p_proc++;
		p_task_stack -= p_task->stacksize;

	}

	/* 中断重入指示 */
	k_reenter = 0;

	/* 系统调用ticks*/
	ticks = 0;

	/* 初始化进程表中的ticks和priority */
	proc_table[0].ticks = proc_table[0].priority = 150;
	proc_table[1].ticks = proc_table[1].priority = 50;
	proc_table[2].ticks = proc_table[2].priority = 30;

	p_proc_ready = proc_table;
	restart();

	while(1){}
	//return 0;
}
