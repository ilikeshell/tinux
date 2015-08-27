#include<tinux.h>
#include<protect.h>
#include<global.h>

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
		disp_color_str("cs:", text_color);
		disp_int(cs);
		disp_color_str("EIP:",text_color);
		disp_int(eip);
		
		if(err_code != 0xFFFFFFFF)
		{
			disp_color_str("ERROR CODE:", text_color);
			disp_int(err_code);
		}
}

typedef void (*int_hander)();

PRIVATE void init_idt_desc(u8 vector, u8 desc_type, int_hander hander, u8 privilege)
{
	GATE *p_gate = &idt[vector];
	u32 offset = (u32)hander;
	p_gate->offset_low = offset & 0xFFFF;
	p_gate->offset_high = (offset >> 16) & 0xFFFF;
	p_gate->selector = SELECTOR_CS_KERNEL;
	p_gate->attr = desc_type | (privilege << 5);
	p_gate->dcount = 0;
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
}
