#include <tinux.h>
#include <global.h>
#include <protect.h>

PUBLIC void init_8259A()
{
	//初始化，写入ICW1
	out_byte(INT_M_CTL, ICW1);
	out_byte(INT_S_CTL, ICW1);
	
	//写入ICW2,制定各自第一个引脚对应的向量号
	out_byte(INT_M_CTLMASK, ICW2_M);
	out_byte(INT_S_CTLMASK, ICW2_S);
	
	//ICW3指定级联的端口号
	out_byte(INT_M_CTLMASK, ICW3_M);
	out_byte(INT_S_CTLMASK, ICW3_S);
	
	//ICW4指定80X86，正常EOI，Sequential模式
	out_byte(INT_M_CTLMASK, ICW4);
	out_byte(INT_S_CTLMASK, ICW4);

	//写入OCW1打开时钟中断
	out_byte(INT_M_CTLMASK, 0xFF);
	out_byte(INT_S_CTLMASK, 0xFF);

	//
	int i;
	for(i = 0; i < NR_IRQ; i++){
		irq_table[i] = spurious_irq;
	}
}

PUBLIC void spurious_irq(int irq)
{
	disp_str("spurious_irq: ");
	disp_int(irq);
	disp_str("\n");
}

PUBLIC void put_irq_handler(int irq, irq_handler handler)
{
	disable_irq(irq);
	irq_table[irq] = handler;
}
