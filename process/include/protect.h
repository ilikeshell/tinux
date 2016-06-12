#ifndef TINUX_PROTECT_H_
#define TINUX_PROTECT_H_

/* GDT和IDT描述符个数 */
#define GDT_SIZE 128
#define IDT_SIZE 256

/* 定义中断向量 */
#define INT_VECTOR_DIVIDE	0
#define INT_VECTOR_DEBUG 	1
#define INT_VECTOR_NMI		2
#define INT_VECTOR_BREAKPOINT	3
#define INT_VECTOR_OVERFLOW	4
#define INT_VECTOR_BOUNDS	5
#define INT_VECTOR_INVAL_OP	6
#define INT_VECTOR_COPROC_NOT	7
#define INT_VECTOR_DOUBLE_FAULT 8
#define INT_VECTOR_COPROC_SEG	9
#define INT_VECTOR_INVAL_TSS	10
#define INT_VECTOR_SEG_NOT	11
#define INT_VECTOR_STACK_FAULT	12
#define INT_VECTOR_PROTECTION	13
#define INT_VECTOR_PAGE_FAULT 14
//#define INT_VECTOR_DIVIDE 15
#define INT_VECTOR_COPROC_ERR 16

/* 8259A对应的中断向量 */
#define INT_VECTOR_IRQ0	0x20	//对应主8259A的第一个端口
#define INT_VECTOR_IRQ8	0x28	//对应从8259A的第一个端口

/* 8259A中断控制器端口 */
#define INT_M_CTL		0x20
#define INT_M_CTLMASK	0x21
#define INT_S_CTL		0xA0
#define INT_S_CTLMASK	0xA1

/* 定义ICW1、ICW2、ICW3、ICW4 */
#define ICW1 	0x11		//高4位只能为0001，低4位的值代表边缘触发、8字节中断向量、级联8259A与需要ICW4
#define ICW2_M	INT_VECTOR_IRQ0
#define ICW2_S	INT_VECTOR_IRQ8
#define ICW3_M	0x4		//IR2对应从8259
#define ICW3_S	0x2		//对应主8259的IR2
#define ICW4	0x1		//80X86模式，正常EOI，Sequential模式

/* 定义内核代码段选择子 */
#define SELECTOR_CS_KERNEL  8

/* 系统段描述符类型,默认P=1且S=0，即存在的系统段或门 */
#define	DA_LDT		0x82
#define DA_TaskGate 0x85
#define DA_386TSS 	0x89
#define DA_386CGate	0x8C
#define DA_386IGate	0x8E
#define DA_386TGate	0x8F

/* 描述符特权级 */
#define PRIVILEGE_KRNL	0x0
#define PRIVILEGE_USER 0x60

/* GDT描述符 */
typedef struct s_descriptor
{
	u16 limit_low;
	u16 base_low;
	u8  base_mid;
	u8 attr1;
	u8 limit_high_attr2;
	u8 base_high;
}DESCRIPTOR;

/* 门描述符 */
typedef struct s_gate
{
	u16 offset_low;
	u16 selector;
	u8 dcount;
	u8 attr;
	u16 offset_high;
}GATE;

/* 保护模式相关函数声明 */
PUBLIC void init_8259A();
PUBLIC void init_prot();
#endif
