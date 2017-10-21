#ifndef _PROCESS_H_
#define _PROCESS_H_

#include "type.h"
#include "protectMode.h"
#define numOfLdtDesc 2 //number of LDT descriptors

//----------------------
// 	Stack frame
//----------------------
//	  u32 gs						<- Stack top
//	  u32 fs
//	  u32 es
//	  u32 ds
//	  u32 edi				 	 	-¢{
//	  u32 esi					  	  |
//	  u32 ebp					  	  |
//	  u32 kernel_esp		  	  |-- pushed by pushad
//	  u32 ebx					  	  |   (pushad will skip kernel_esp)
//	  u32 edx					  	  |
//	  u32 ecx					  	  |
//	  u32 eax					  	-¢}
//	  u32 eip					  	-¢{
//	  u32 cs					  	  |
//	  u32 eflags				  	  |-- pushed by CPU during interrupt
//	  u32 esp	(only for TSS) |
//	  u32 ss (only for TSS) 	-¢}
//------------------------	<- Stack base

typedef struct s_proc
{
	u32 esp;
	u32 ss;
	u16 ldt_sel;
	DESCRIPTOR ldt_desc[numOfLdtDesc];
	u32 pid;
	char p_name[32];
}PROCESS;

typedef struct s_task
{
	u32 initial_eip;
	int stacksize;
	char name[32];
}TASK;

#define NR_TASKS 3

#define EFLAGS 0x202 //(Interrupt Flag=1, IOPL=0 <-priveledge level, bit 2 reserved)

#define STACK_SIZE_TASKA 0x8000 //32KB
#define STACK_SIZE_TASKB 0x8000
#define STACK_SIZE_TASKC 0x8000

#define STACK_SIZE_TOTAL (STACK_SIZE_TASKA + \
										 STACK_SIZE_TASKB + \
										 STACK_SIZE_TASKC)


#endif /* _PROCESS_H_ */