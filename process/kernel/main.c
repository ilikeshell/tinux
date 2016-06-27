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
	int i = 0;

	while(1)
	{
		disp_str("A");
		disp_int(i++);
		disp_str(".");
		delay(3);
	}
}

void TestB()
{
	int i = 0x1000;
	while(1)
	{
		disp_str("B");
		disp_int(i++);
		disp_str(".");
		delay(3);
	}
}

void TestC()
{
	int i = 0x2000;
	while(1)
	{
		disp_str("C");
		disp_int(i++);
		disp_str(".");
		delay(3);
	}
}

PUBLIC int kernel_main()
{
	disp_str("------\"kernel_main\" begins-----\n");

	TASK *p_task	= task_table;
	PROCESS *p_proc = proc_table;
	char *p_task_stack = task_stack + STACK_SIZE_TOTAL;
	u16 selector_ldt= SELECTOR_LDT_FIRST;
	int i;

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
		p_proc->regs.eip = p_task->init_eip;
		p_proc->regs.esp = p_task_stack;
		p_proc->regs.eflags = 0x1202;     //IF=1, IOPL=1; bit w is always 1.

		selector_ldt += 1 << 3;
		p_task++;
		p_proc++;
		p_task_stack -= p_task->stacksize;

	}

	/* 中断重入指示 */
	k_reenter = -1;

	p_proc_ready = proc_table;
	restart();

	while(1){}
	//return 0;
}
