#include<tinux.h>
#include<global.h>
#include<proc.h>

PUBLIC void clock_handler(int irq)
{
	disp_str("#");

	if(k_reenter != 0){
		disp_str("!");
		return;
	}

	p_proc_ready++;
	if(p_proc_ready >= proc_table + NR_TASKS)
		p_proc_ready = proc_table;
}
