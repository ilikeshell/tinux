#include "tinux.h"

PUBLIC void* memcpy(void* pDst, void* pSrc, int iSize);
PUBLIC u8 gdt_ptr[6];
PUBLIC DESCRIPTOR gdt[GDT_SIZE];

PUBLIC void cstart( )
{
	/* 把GDT从LAODER中拷贝到KERNEL */
	memcpy(gdt, 
		((void*)((u32*)(&gdt_ptr[2]))), 
		*((u16*)(&gdt_ptr[0]))+1
		);
	/* 设置新的GDTPTR，以便加载 */
	u16* p_gdt_limit = (u16* )(&gdt_ptr[0]);
	u32* p_gdt_base = (u32* )(&gdt_ptr[2]);
	*p_gdt_limit = GDT_SIZE * sizeof (DESCRIPTOR) - 1;
	*p_gdt_base = *((u32* )(&gdt[0]));
}
