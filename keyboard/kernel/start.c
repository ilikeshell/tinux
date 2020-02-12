#include <type.h>
#include <const.h>
#include <protect.h>
#include <string.h>
#include <proto.h>
#include <global.h>

PUBLIC void cstart( )
{
	/* 把GDT从LAODER中拷贝到KERNEL */
	memcpy(gdt,
			(void *)(*(u32*)(&gdt_ptr[2])),
		*((u16 *)(&gdt_ptr[0]))+1
		);

	/* 设置新的GDTPTR，以便加载 */
	u16* p_gdt_limit = (u16* )(&gdt_ptr[0]);
	u32* p_gdt_base = (u32* )(&gdt_ptr[2]);
	*p_gdt_limit = GDT_SIZE * sizeof (DESCRIPTOR) - 1;
	*p_gdt_base = (u32)gdt;
	//*p_gdt_base = *((u32* )(&gdt[0]));
	
	/* 设置新的IDTPTR，以便加载 */
	u16* p_idt_limit = (u16* )(&idt_ptr[0]);
	u32* p_idt_base = (u32* )(&idt_ptr[2]);
	*p_idt_limit = IDT_SIZE * sizeof (GATE) - 1;
	*p_idt_base = (u32)idt;
	
	/* 显示字符串 */
	init_disp_pos();
	disp_str("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n------\"cstart\" begin------\n");
	/* 初始化8259A，设置中断及异常处理程序，初始化LDT和TSS描述符，并设置TSS的ss0和sp0 */
	init_prot();
	//disp_int(test);
	//disp_str("\n");
	//disp_str("------\"cstart\" ends-------\n");
	//	label: goto label;
}
