#include<tinux.h>
//#include<protect.h>
#include<global.h>
#include<proto.h>

void divide_error();
void single_step_exception();
void nmi();
void breakpoint_exception();
void overflow();
void bounds_check();
void invalid_opcode();
void copr_not_available();
void double_fault();
void copr_seg_overrun();
void invalid_tss();
void segment_not_present();
void stack_exception();
void general_protection();
void page_fault();
void copr_error();

void hwint_00();
void hwint_01();
void hwint_02();
void hwint_03();
void hwint_04();
void hwint_05();
void hwint_06();
void hwint_07();
void hwint_08();
void hwint_09();
void hwint_10();
void hwint_11();
void hwint_12();
void hwint_13();
void hwint_14();
void hwint_15();



PUBLIC void exception_handler(u32 vec_no, u32 err_code, u32 eip, u32 cs, u32 eflags)
{
	int i;
	u8 text_color = 0x74;	/* 灰底红字 */
	char* err_msg[] = 
	{
		"#DE Divide Error",
		"#BD RESERVED",
		"-- NMI Interrupt",
		"#BP Breakpoint",
		"#OF Overflow",
		"#BR Bound Range Exceeded",
		"#UD Invalid Opcode (Undefined Opcode)",
		"#NM Device Not Available (No Math Coprocessor)",
		"#DF Double Fault",
		"   Coprocessor Segment Overrun (reserved)",
		"#TS Invalid TSS",
		"#NP Segment Not Present",
		"#SS Stack Segment Fault",
		"#GP General Protection",
		"#PF Page Fault",
		"-- (Intel Reserved. Do not use)",
		"#MF x87 FPU Floating Point Error (Math Fault)",
		"#AC Alignment Check",
		"#MC Machine Check",
		"#XF SIMD Floating Point Exception"
	};
		
		/* 屏幕前五行清零 */
		disp_pos = 0;
		for(i = 0; i < 5 * 80; i++)
			disp_str(" ");
		disp_pos = 0;
		
		disp_color_str("Exception! --> ", text_color);
		disp_color_str(err_msg[vec_no], text_color);
		disp_color_str("\n\n", text_color);
		disp_color_str("EFLAGS:", text_color);
		disp_int(eflags);
		disp_color_str("CS:", text_color);
		disp_int(cs);
		disp_color_str("EIP:",text_color);
		disp_int(eip);
		
		if(err_code != 0xFFFFFFFF)
		{
			disp_color_str("ERROR CODE:", text_color);
			disp_int(err_code);
		}

		/* 补丁，测试显示区域指针是否越界 */
		disp_color_str("disp_pos value:", text_color);
		disp_int(disp_pos);
}

typedef void (*int_hander)();

PRIVATE void init_idt_desc(u8 vector, u8 desc_type, int_hander hander, u8 privilege)
{
	GATE *p_gate = &idt[vector];
	u32 offset = (u32)hander;
	p_gate->offset_low = offset & 0xFFFF;
	p_gate->offset_high = (offset >> 16) & 0xFFFF;
	p_gate->selector = SELECTOR_KERNEL_CS;
	p_gate->attr = desc_type | privilege;
	p_gate->dcount = 0;
}

/* 初始化描述符 */
PRIVATE void init_descriptor(DESCRIPTOR *p_desc, u32 base, u32 limit, u16 attribute)
{
	p_desc->base_low = 0xFFFF & base;
	p_desc->base_mid = 0xFF & (base >> 16);
	p_desc->base_high = 0XFF & (base >> 24);
	p_desc->limit_low = 0xFFFF & limit;
	p_desc->limit_high_attr2 = (0x0F & (limit >> 16)) | (0xF0 & (attribute >> 8));
	p_desc->attr1 = 0xFF & attribute;
}

/* 由段名求绝对地址 */
PUBLIC u32 seg2phys(u16 seg)
{
	DESCRIPTOR *p_desc = &gdt[seg >> 3];

	return p_desc->base_low + (p_desc->base_mid << 16) + (p_desc->base_high << 24);
}

PUBLIC void init_prot()
{
	init_8259A();
	
	/* 全部初始化为中断门 */
	init_idt_desc(INT_VECTOR_DIVIDE, DA_386IGate, divide_error, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_DEBUG, DA_386IGate, single_step_exception, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_NMI, DA_386IGate, nmi, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_BREAKPOINT, DA_386IGate, breakpoint_exception, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_OVERFLOW, DA_386IGate, overflow, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_BOUNDS, DA_386IGate, bounds_check, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_INVAL_OP, DA_386IGate, invalid_opcode, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_COPROC_NOT, DA_386IGate, copr_not_available, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_DOUBLE_FAULT, DA_386IGate, double_fault, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_COPROC_SEG, DA_386IGate, copr_seg_overrun, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_INVAL_TSS, DA_386IGate, invalid_tss, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_SEG_NOT, DA_386IGate, segment_not_present, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_STACK_FAULT, DA_386IGate, stack_exception, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_PROTECTION, DA_386IGate, general_protection, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_PAGE_FAULT, DA_386IGate, page_fault, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_COPROC_ERR, DA_386IGate, copr_error, PRIVILEGE_KRNL);

	/* 初始化8259A的处理程序 */
	init_idt_desc(INT_VECTOR_IRQ0 + 0, DA_386IGate, hwint_00, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_IRQ0 + 1, DA_386IGate, hwint_01, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_IRQ0 + 2, DA_386IGate, hwint_02, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_IRQ0 + 3, DA_386IGate, hwint_03, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_IRQ0 + 4, DA_386IGate, hwint_04, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_IRQ0 + 5, DA_386IGate, hwint_05, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_IRQ0 + 6, DA_386IGate, hwint_06, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_IRQ0 + 7, DA_386IGate, hwint_07, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_IRQ8 + 0, DA_386IGate, hwint_08, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_IRQ8 + 1, DA_386IGate, hwint_09, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_IRQ8 + 2, DA_386IGate, hwint_10, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_IRQ8 + 3, DA_386IGate, hwint_11, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_IRQ8 + 4, DA_386IGate, hwint_12, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_IRQ8 + 5, DA_386IGate, hwint_13, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_IRQ8 + 6, DA_386IGate, hwint_14, PRIVILEGE_KRNL);
	init_idt_desc(INT_VECTOR_IRQ8 + 7, DA_386IGate, hwint_15, PRIVILEGE_KRNL);
	/* 初始化系统调用描述符 */
	init_idt_desc(INT_VECTOR_SYS_CALL, DA_386IGate, sys_call, PRIVILEGE_USER);

	int i;
	u16 selector_ldt = INDEX_LDT_FIRST << 3;
	PROCESS *p_proc = proc_table;

	//初始化LDT描述符
	for(i = 0; i < NR_TASKS; i++)
	{
		init_descriptor(&gdt[selector_ldt >> 3],
					vir2phys(seg2phys(SELECTOR_KERNEL_DS),p_proc->ldts),
					LDT_SIZE * sizeof(DESCRIPTOR) - 1,
					DA_LDT);
		selector_ldt += 1 << 3;
		p_proc++;
	}



	//TSS相关
	memset(&tss, 0, sizeof(tss));
	tss.ss0 = SELECTOR_KERNEL_DS;
	//tss.esp0 = (u32)(&(proc_table[0].ldt_sel)); 	//tss.esp0放在汇编代码里设置
	tss.iobase = sizeof(tss);
	init_descriptor(&gdt[INDEX_TSS],
			vir2phys(seg2phys(SELECTOR_KERNEL_DS), &tss),
			sizeof(tss)-1,
			DA_386TSS);

}



