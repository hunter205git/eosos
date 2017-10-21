#include "type.h"
#include "protectMode.h"
#include "process.h"

#define numOfDesc 128 //number of GDT descriptors
#define numOfGate 256 //number of IDT gates

int 			disp_pos;

u8 			gdt_info[]; 
DESCRIPTOR 	gdt_desc[];
u8 			idt_info[];
GATE 	idt_gate[];

char task_stack[];
PROCESS proc_table[];
TASK task_table[];
PROCESS* p_proc_ready;

char* p_task_stack;
extern void TaskA();
extern void TaskB();
extern void TaskC();