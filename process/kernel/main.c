#include<tinux.h>
#include<protect.h>
#include<proto.h>
#include<proc.h>
#include<string.h>

void TestA()
{
	int i=0;
	while(1){
		disp_str("A");
		disp_int(i++);
		disp_str(".");
		delay(1);
	}
}

PUBLIC int kernel_main()
{
	disp_str("------\"kernel_main\" begins-----\n");

	PROCESS *p_proc = proc_table;
	p_proc->ldt_sel = SELECTOR_LDT_FIRST;

	//初始化LDT表，后续还需在GDT中登记
	memcpy(&p_proc->ldts[0], &gdt[INDEX_FLAT_C], sizeof(DESCRIPTOR));
	p_proc->ldts[0].attr1 = DA_C | PRIVILEGE_TASK << 5;
	memcpy(&p_proc->ldts[1], &gdt[INDEX_FLAT_RW], sizeof(DESCRIPTOR));
	p_proc->ldts[1].attr1 = DA_DRW | PRIVILEGE_TASK << 5;

	// set registers
	p_proc->regs.cs = (0 & SA_RPL_MASK & SA_TI_MASK)| SA_TIL | RPL_TASK;
	p_proc->regs.ds = (8 & SA_RPL_MASK & SA_TI_MASK)| SA_TIL | RPL_TASK;
	p_proc->regs.es = (8 & SA_RPL_MASK & SA_TI_MASK)| SA_TIL | RPL_TASK;
	p_proc->regs.fs = (8 & SA_RPL_MASK & SA_TI_MASK)| SA_TIL | RPL_TASK;
	p_proc->regs.ss = (8 & SA_RPL_MASK & SA_TI_MASK)| SA_TIL | RPL_TASK;
	p_proc->regs.gs = (SELECTOR_KERNEL_GS & SA_RPL_MASK) | RPL_TASK;
	p_proc->regs.eip = (u32)TestA;
	p_proc->regs.esp = (u32)task_stack + STACK_SIZE_TOTAL;
	p_proc->regs.eflags = 0x1202;     //IF=1, IOPL=1; bit w is always 1.

	while(1){}
}
