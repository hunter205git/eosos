#include "process.h"
#include "type.h"
#include "global.h"

void kernel_main()
{
	PROCESS* p_proc = proc_table;
	TASK* p_task = task_table;
	p_task_stack = task_stack + STACK_SIZE_TOTAL;
	u16 selector_ldt=SELECTOR_LDTA;
	
	int i;
	for(i=0;i<NR_TASKS;i++)
	{
			strcpy(p_proc->p_name,p_task->name);
			p_proc->pid = i;
			p_proc->ldt_sel = selector_ldt;
			//Copy KERNEL_CS descriptor to the first descriptor of LDT
			memcpy(&p_proc->ldt_desc[0],&gdt_desc[INDEX_KERNEL_CS],sizeof(DESCRIPTOR));
			//Copy KERNEL_DS descriptor to the second descriptor of LDT
			memcpy(&p_proc->ldt_desc[1],&gdt_desc[INDEX_KERNEL_DS],sizeof(DESCRIPTOR));
			
			//Push the registers data into stack
			//These will be popped in restart()			
			push(EFLAGS); //EFLAGS
			push(SELECTOR_KERNEL_CS); //CS
			push(p_task->initial_eip); //EIP
			
			pushad(); // EAX, ECX, EDX, EBX, kernel_esp, EBP, ESI, EDI
			
			push(SELECTOR_KERNEL_DS); //DS
			push(SELECTOR_KERNEL_DS); //ES
			push(SELECTOR_KERNEL_DS); //FS
			push(SELECTOR_KERNEL_GS); //GS
			
			//Save the ss:esp
			p_proc->esp=p_task_stack;
			p_proc->ss=SELECTOR_KERNEL_DS;
			
			p_proc++; //Next process
			p_task++;
			p_task_stack -= p_task->stacksize;
			selector_ldt +=(1<<3);
	}
	p_proc_ready = proc_table; //Set p_proc_ready to the first process
	
	int textColor = 0x07;
	print_color_str("Initializing OS ------------------- [ SUCCESSED ]\n\n",textColor);

	restart(); //Run the first process
	
	while(1);
}

//-----------------------------------
//				Processes
//-----------------------------------
void TaskA()
{
	int textColor=0x0A;
	while(1)
	{
		print_color_str("A", textColor);
		delay(1);
	}
}

void TaskB()
{
	int textColor=0x0B;
	while(1)
	{
		print_color_str("B", textColor);
		delay(1);
	}
}

void TaskC()
{
	int textColor=0x0E;
	while(1)
	{
		print_color_str("C",textColor);
		delay(1);
	}
}