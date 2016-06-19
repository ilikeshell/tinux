#ifndef TINUX_PROTECT_H_
#define TINUX_PROTECT_H_

/* GDT和IDT描述符个数 */
#define GDT_SIZE 128
#define IDT_SIZE 256

/* LDT描述符个数  */
#define LDT_SIZE 2

/* GDT */
/* 描述符索引 */
#define INDEX_DUMMY			0
#define INDEX_FLAT_C		1
#define INDEX_FLAT_RW		2
#define INDEX_VIDEO			3
#define INDEX_TSS			4
#define INDEX_LDT_FIRST		5

/* 选择子 */
#define SELECTOR_DUMMY			0
#define SELECTOR_FLAT_C			0x08
#define SELECTOR_FLAT_RW		0x10
#define SELECTOR_VIDEO			(0x18+3)
#define SELECTOR_TSS			0x20
#define SELECTOR_LDT_FIRST		0x28

#define SELECTOR_KERNEL_CS		SELECTOR_FLAT_C
#define SELECTOR_KERNEL_DS		SELECTOR_FLAT_RW
#define SELECTOR_KERNEL_GS		SELECTOR_VIDEO

/* 定义选择子属性 */
#define SA_RPL_MASK			0xFFFC
#define SA_RPL0				0
#define SA_RPL1				1
#define SA_RPL2				2
#define SA_RPL3				3

#define SA_TI_MASK			0xFFFB
#define SA_TIG				0
#define SA_TIL				4

/* RPL */
#define RPL_KRNL	SA_RPL0
#define RPL_TASK	SA_RPL1
#define RPL_USER	SA_RPL3


/* 描述符类型值说明 */
#define DA_LIMIT_4K			0x8000
#define DA_32				0x4000
#define DA_DPL0				0x00
#define DA_DPL1				0x20
#define DA_DPL2				0x40
#define DA_DPL3				0x60

/* 存储段描述符类型值说明 */
#define DA_DR				0x90
#define DA_DRW				0x92
#define DA_DRWA				0x93
#define DA_C				0x98
#define DA_CR				0X9A
#define DA_CCO				0X9C
#define DA_CCOR				0X9E

/* 系统段描述符类型,默认P=1且S=0，即存在的系统段或门 */
#define DA_LDT				0x82
#define DA_TaskGate			0x85
#define DA_386TSS			0x89
#define DA_386CGATE     	0x8C
#define DA_386IGATE			0x8E
#define DA_386TGATE			0x8F

/* 描述符特权级 */
#define PRIVILEGE_KRNL		0x00
#define PRIVILEGE_TASK		0x20
#define PRIVILEGE_USER 		0x60

/* 每个任务有一个单独的 LDT, 每个 LDT 中的描述符个数: */
#define LDT_SIZE	2

/* 定义中断向量 */
#define INT_VECTOR_DIVIDE		0
#define INT_VECTOR_DEBUG 		1
#define INT_VECTOR_NMI			2
#define INT_VECTOR_BREAKPOINT	3
#define INT_VECTOR_OVERFLOW		4
#define INT_VECTOR_BOUNDS		5
#define INT_VECTOR_INVAL_OP		6
#define INT_VECTOR_COPROC_NOT	7
#define INT_VECTOR_DOUBLE_FAULT 8
#define INT_VECTOR_COPROC_SEG	9
#define INT_VECTOR_INVAL_TSS	10
#define INT_VECTOR_SEG_NOT		11
#define INT_VECTOR_STACK_FAULT	12
#define INT_VECTOR_PROTECTION	13
#define INT_VECTOR_PAGE_FAULT 	14
#define INT_VECTOR_DIVIDE 		15
#define INT_VECTOR_COPROC_ERR 	16


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

typedef struct s_tss{
	u32 backlink;
	u32 esp0;
	u32 ss0;
	u32 esp1;
	u32 ss1;
	u32 esp2;
	u32 ss2;
	u32 cr3;
	u32 eip;
	u32 flags;
	u32 eax;
	u32 ecx;
	u32 edx;
	u32 ebx;
	u32 esp;
	u32 ebp;
	u32 esi;
	u32 edi;
	u32 es;
	u32 cs;
	u32 ss;
	u32 ds;
	u32 fs;
	u32 gs;
	u32 ldt;
	u32 trap;
	u32 iobase;
}TSS;

/* 保护模式相关函数声明 */
PUBLIC void init_8259A();
PUBLIC void init_prot();

/* 线性地址转物理地址 */
#define vir2phys(seg_base, vir) (u32)(((u32)seg_base) + (u32)(vir))

#endif
