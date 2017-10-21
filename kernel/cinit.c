#include "type.h"
#include "protectMode.h"
#include "global.h"

//------------------------------------------------------
void cinit()
{
	DESCRIPTOR* gdt_ptr = gdt_desc; //Point to gdt_desc[]
	GATE* idt_ptr = idt_gate; //Point to idt_gate[]
	
	//Copy the GDT in loader (changemode.asm) to new GDT
	memcpy( gdt_ptr,
			(void*)(*((u32*)(&gdt_info[2]))), //Base address of old GDT  (void*)(value); value=*(pointer); pointer=(u32*)(address); address=&gdt_info[2]
			*((u16*)(&gdt_info[0])) + 1
		   );
		   
	//Renew the gdt_info data to new GDT limit and base address
	u16* p_gdt_limit = (u16*)(&gdt_info[0]); //&gdt_info[0] = gdt_info
	u32* p_gdt_base  = (u32*)(&gdt_info[2]); //&gdt_info[2] = gdt_info+2
	*p_gdt_limit = numOfDesc * sizeof(DESCRIPTOR) - 1; //Save the limit of GDT
	*p_gdt_base  = (u32)gdt_ptr; //Save the base address of GDT
	
	//Fill the idt_info with a new IDT limit and base created in the future
	u16* p_idt_limit = (u16*)(&idt_info[0]);//&idt_info[0] = idt_info
	u32* p_idt_base  = (u32*)(&idt_info[2]); //&idt_info[2] = idt_info+2
	*p_idt_limit = numOfGate * sizeof(GATE) - 1; //Save the limit of IDT
	*p_idt_base  = (u32)idt_ptr; //Save the base address of IDT
	
	init_prot(); //Initialize GDT and IDT table
}