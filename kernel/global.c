#include "type.h"
#include "protectMode.h"
#include "global.h"
#include "process.h"

u8 			gdt_info[6]; //sgdt [gdt_info] -> 0~15:Limit  16~47:Base
DESCRIPTOR 	gdt_desc[numOfDesc];
u8 			idt_info[6];
GATE 		idt_gate[numOfGate];

int 			disp_pos = 1280; //Row 8, Column 0  (80 * 8 + 0) * 2bytes

PROCESS		proc_table[NR_TASKS];
char		task_stack[STACK_SIZE_TOTAL]; //1 byte size for each memory address
PROCESS* p_proc_ready = proc_table;

TASK		task_table[NR_TASKS] = {{TaskA, STACK_SIZE_TASKA, "TaskA"},
					{TaskB, STACK_SIZE_TASKB, "TaskB"},
					{TaskC, STACK_SIZE_TASKC, "TaskC"}};