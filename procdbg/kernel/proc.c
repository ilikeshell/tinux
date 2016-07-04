#include <tinux.h>
#include <proto.h>
#include <global.h>

PUBLIC int sys_get_ticks()
{
	//disp_str("+");
	return ticks;
}
