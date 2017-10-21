#include "type.h"
#include "protectMode.h"
#include "global.h"

void init_prot();
void init_idt_gate(u8 vector, u8 gate_type, void* handler, u8 privilege);
void exception_handler(int vector_no, int err_code, int eip, int cs, int eflags);

/* 中斷處理函數 */
void	divide_error();
void	debug_exception();
void	nmi();
void	breakpoint_exception();
void	overflow();
void	bounds_check();
void	invalid_opcode();
void	coproc_not_avalible();
void	double_fault();
void	coproc_seg_overrun();
void	invalid_tss();
void	seg_not_present();
void	stack_exception();
void	general_protection();
void	page_fault();
void	coproc_error();
void	hwint00();
void	hwint01();
void	hwint02();
void	hwint03();
void	hwint04();
void	hwint05();
void	hwint06();
void	hwint07();
void	hwint08();
void	hwint09();
void	hwint10();
void	hwint11();
void	hwint12();
void	hwint13();
void	hwint14();
void	hwint15();

void init_prot()
{
	init_8259A();
	
	//initialize IDT gates
	init_idt_gate(INT_VECTOR_DIVIDE, 				INT_GATE_ATTR, divide_error,		 	 	 PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_DEBUG,		  		INT_GATE_ATTR,	debug_exception,	 	 PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_NMI,		  			INT_GATE_ATTR,	nmi,				 		 	 PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_BREAKPOINT,		INT_GATE_ATTR,	breakpoint_exception,PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_OVERFLOW,			INT_GATE_ATTR,	overflow,			 		 PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_BOUNDS,				INT_GATE_ATTR,	bounds_check,		 	 PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_INVAL_OP,			INT_GATE_ATTR,	invalid_opcode,		 	 PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_COPROC_NOT,		INT_GATE_ATTR,	coproc_not_avalible,  PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_DOUBLE_FAULT,	INT_GATE_ATTR,	double_fault,		 		 PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_COPROC_SEG,		INT_GATE_ATTR,	coproc_seg_overrun, PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_INVAL_TSS,	  		INT_GATE_ATTR,	invalid_tss,		 		 PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_SEG_NOT,			INT_GATE_ATTR,	seg_not_present,	 	 PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_STACK_FAULT, 	INT_GATE_ATTR,	stack_exception,	 	 PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_PROTECTION,		INT_GATE_ATTR,	general_protection,	 PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_PAGE_FAULT,		INT_GATE_ATTR,	page_fault,			 	 PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_COPROC_ERR,		INT_GATE_ATTR,	coproc_error,		 	 PRIVILEGE_KRNL);
    //initialize master interrupt
	init_idt_gate(INT_VECTOR_IRQ0 + 0,		INT_GATE_ATTR,	hwint00,	PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_IRQ0 + 1,		INT_GATE_ATTR,	hwint01,	PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_IRQ0 + 2,		INT_GATE_ATTR,	hwint02,	PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_IRQ0 + 3,		INT_GATE_ATTR,	hwint03,	PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_IRQ0 + 4,		INT_GATE_ATTR,	hwint04,	PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_IRQ0 + 5,		INT_GATE_ATTR,	hwint05,	PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_IRQ0 + 6,		INT_GATE_ATTR,	hwint06,	PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_IRQ0 + 7,		INT_GATE_ATTR,	hwint07,	PRIVILEGE_KRNL);	
	//initialize slave interrupt
	init_idt_gate(INT_VECTOR_IRQ8 + 0,		INT_GATE_ATTR,	hwint08,	PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_IRQ8 + 1,		INT_GATE_ATTR,	hwint09,	PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_IRQ8 + 2,		INT_GATE_ATTR,	hwint10,	PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_IRQ8 + 3,		INT_GATE_ATTR,	hwint11,	PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_IRQ8 + 4,		INT_GATE_ATTR,	hwint12,	PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_IRQ8 + 5,		INT_GATE_ATTR,	hwint13,	PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_IRQ8 + 6,		INT_GATE_ATTR,	hwint14,	PRIVILEGE_KRNL);
	init_idt_gate(INT_VECTOR_IRQ8 + 7,		INT_GATE_ATTR,	hwint15,	PRIVILEGE_KRNL);
	
	//Add LDT descriptors into GDT
	int i=0;
	u16 index_ldt = INDEX_LDTA;
	PROCESS* p_proc = proc_table;
	for(i=0;i<NR_TASKS;i++)
	{
		init_descriptor(&gdt_desc[index_ldt], 
							seg_base_addr(INDEX_KERNEL_DS)+p_proc->ldt_desc,
							numOfLdtDesc * sizeof(DESCRIPTOR)-1,
							DA_LDT);
		p_proc++;
		index_ldt++;
	}
}

void init_idt_gate(u8 vector, u8 gate_type, void* handler, u8 privilege)
{
	GATE* p_gate = &idt_gate[vector];
	u32 base = (u32) handler;
	p_gate->offset_low = base & 0xFFFF;
	p_gate->selector = SELECTOR_KERNEL_CS;
	p_gate->dcount = 0;
	p_gate->attr = gate_type | privilege;
	p_gate->offset_high = (base >> 16) & 0xFFFF;
}

void init_descriptor(DESCRIPTOR* p_desc, u32 base, u32 limit, u16 attribute)
{
	p_desc->limit_low=limit & 0xFFFF;
	p_desc->base_low=base & 0xFFFF;
	p_desc->base_mid=(base >> 16) & 0xFF;
	p_desc->attr1=attribute & 0xFF;
	p_desc->limit_high_attr2=((limit >> 16) & 0xF) | ((attribute >> 8) & 0xF0);
	p_desc->base_high=(base >> 24) & 0xFF;
}

void seg_base_addr(int index_desc)
{
	DESCRIPTOR* p_desc = &gdt_desc[index_desc];
	return (p_desc->base_high << 24) | (p_desc->base_mid << 16) | (p_desc->base_low);
}

void spurious_irq(int irq) //called by 8259A interrput handler
{
	print_str("spurious_irq: ");
	print_int(irq);
	print_str("\n");
}

void exception_handler(int vector_no, int err_code, int eip, int cs, int eflags)
{
	int text_color = 0x74;
	char err_description[][64] = {	"#DE Divide Error",
					"#DB RESERVED",
					"—  NMI Interrupt",
					"#BP Breakpoint",
					"#OF Overflow",
					"#BR BOUND Range Exceeded",
					"#UD Invalid Opcode (Undefined Opcode)",
					"#NM Device Not Available (No Math Coprocessor)",
					"#DF Double Fault",
					"    Coprocessor Segment Overrun (reserved)",
					"#TS Invalid TSS",
					"#NP Segment Not Present",
					"#SS Stack-Segment Fault",
					"#GP General Protection",
					"#PF Page Fault",
					"—  (Intel reserved. Do not use.)",
					"#MF x87 FPU Floating-Point Error (Math Fault)",
					"#AC Alignment Check",
					"#MC Machine Check",
					"#XF SIMD Floating-Point Exception"
				};
	disp_pos=0;
	print_color_str("Exception!\n",text_color);
	print_color_str(err_description[vector_no],text_color);
	print_color_str("\n",text_color);
	print_color_str("EFLAGS:",text_color);
	print_int_hex(eflags);
	print_color_str(" CS:",text_color);
	print_int_hex(cs);
	print_color_str(" EIP:",text_color);
	print_int_hex(eip);
	print_color_str("\n",text_color);
	
	if(err_code!=0xFFFFFFFF)
	{
		print_color_str("Error code",text_color);
		print_int_hex(err_code);
	}
}