#include "global.h"
#include "process.h"

void scheduler()
{
	p_proc_ready++;
	if(p_proc_ready >= proc_table + NR_TASKS)
		p_proc_ready = proc_table;
}