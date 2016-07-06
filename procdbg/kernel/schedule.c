#include <tinux.h>
#include <proc.h>
#include <global.h>

PUBLIC void schedule()
{
	PROCESS *p;
	int greatest_ticks = 0;

	while(!greatest_ticks)
	{
		//遍历进程表，找出最大的ticks，然后指向它
		for(p = proc_table; p < proc_table + NR_TASKS; p++)
		{
			if(p->ticks > greatest_ticks)
			{
				greatest_ticks = p->ticks;
				p_proc_ready = p;
			}
		}
		//如果最大的ticks都为零，重置！
		if(!greatest_ticks)
		{
			for(p = proc_table; p < proc_table + NR_TASKS; p++)
			{
				p->ticks = p->priority;
			}
		}
	}
}
