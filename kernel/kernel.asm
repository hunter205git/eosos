%include "sconst.inc"
;C function
extern _cinit
extern _set_timer
extern _kernel_main
extern _scheduler
extern _spurious_irq
extern _exception_handler
extern _print_int
extern _print_str
extern _mem_dump

;global variable
extern _gdt_info
extern _idt_info
extern _p_proc_ready

%define SELECTOR_KERNEL_CS 0x08
%define SELECTOR_KERNEL_DS 0x10

bits 32

[SECTION .data]
kernel_esp dd 0
int_output dd '0'

[SECTION .bss] 
;用來存放程序中未初始化的全局變量的一塊內存區域。
;BSS是英文Block Started by Symbol的簡稱。
;BSS段屬於靜態內存分配。.bss section 的空間結構類似於 stack
StackSpace resb 2 * 1024
StackTop:	;Top of the Stack

[SECTION .text]
;asm function
global _restart

global _divide_error		 	 	
global _debug_exception	 	
global _nmi				 		 	
global _breakpoint_exception
global _overflow			 		
global _bounds_check		 	
global _invalid_opcode		 	
global _coproc_not_avalible 
global _double_fault		 		
global _coproc_seg_overrun
global _invalid_tss,		 		
global _seg_not_present	 	
global _stack_exception	 	
global _general_protection	
global _page_fault			 	
global _coproc_error		 	
global _hwint00
global _hwint01
global _hwint02
global _hwint03
global _hwint04
global _hwint05
global _hwint06
global _hwint07
global _hwint08
global _hwint09
global _hwint10
global _hwint11
global _hwint12
global _hwint13
global _hwint14
global _hwint15

;-----------------------------------------------------------------
; Kernel start from here
;-----------------------------------------------------------------
_start:
	mov esp, StackTop

	sgdt [_gdt_info] ;old GDT (0~15:Limit  16~47:Base)
	call _cinit
	lgdt [_gdt_info] ;new GDT (0~15:Limit  16~47:Base)
	lidt [_idt_info]
	jmp SELECTOR_KERNEL_CS:csinit ;強制使用cstart初始化的GDT結構
csinit:
	;call _set_timer
	;sti ;開中斷
	jmp _kernel_main

;-----------------------------------------------------------------
; void restart()
;-----------------------------------------------------------------
_restart:	
	mov [kernel_esp], esp ;save the kernel esp
	
	mov esp, [_p_proc_ready]
	lldt [esp + P_LDT_SEL]
	mov esp,[esp] ;get the esp in task_stack
	pop gs	
	pop fs	
	pop es
	pop ds
	popad

	iretd ;會自動開中斷

;-----------------------------------------------------------------
;Hardware interrupt
;-----------------------------------------------------------------
;hardware interrupt master
%macro hwint_master 1
	push	%1 ;push the first argument
	call	_spurious_irq
	hlt
%endmacro

ALIGN 16
_hwint00: ;IRQ0 interrupt handler
	pushad	
	push ds
	push es
	push fs	
	push gs

	mov eax,[_p_proc_ready]
	mov [eax],esp ;save the process esp

	mov	dx, ss
	mov	ds, dx
	mov	es, dx

	mov esp, [kernel_esp] ;load the kernel esp
	
	;inc byte [gs:0] ;increase the upper-left character of the screen
	
	call _scheduler
	
	mov [kernel_esp], esp ;save the kernel esp
	
	mov esp, [_p_proc_ready]
	lldt [esp + P_LDT_SEL]
	mov esp, [esp] ; *(_p_proc_ready->esp); get the esp in task_stack

	pop gs
	pop fs
	pop es
	pop ds
	popad

	mov al, 20h ;EOI
	out 20h, al  ;當每次中斷結束，需要發送一個EOI給8259A，以便繼續接收中斷。

	iretd

ALIGN 16		;reserved space for macro
_hwint01:
	hwint_master 1

ALIGN 16
_hwint02:
	hwint_master 2

ALIGN 16
_hwint03:
	hwint_master 3

ALIGN 16
_hwint04:
	hwint_master 4

ALIGN 16
_hwint05:
	hwint_master 5

ALIGN 16
_hwint06:
	hwint_master 6

ALIGN 16
_hwint07:
	hwint_master 7
	
;hardware interrupt slave
%macro hwint_slave 1
	push	%1 	;push the first argument
	call	_spurious_irq
	hlt
%endmacro

ALIGN 16
_hwint08:
	hwint_slave	8

ALIGN 16
_hwint09:
	hwint_slave	9

ALIGN 16
_hwint10:
	hwint_slave	10

ALIGN 16
_hwint11:
	hwint_slave	11

ALIGN 16
_hwint12:
	hwint_slave	12

ALIGN 16
_hwint13:
	hwint_slave	13

ALIGN 16
_hwint14:
	hwint_slave	14

ALIGN 16
_hwint15:
	hwint_slave	15

;----------------------------------------------
;Exception interrupt
;----------------------------------------------
;vector 8, 10-14,17, 預設有錯誤碼, 會自動push errorcode
;為了用exception_handler接參數, 其他vector需手動push noerrorcode
_divide_error:
	push 0xFFFFFFFF		;no error code
	push 0				;vector_no = 0
	jmp exception
_debug_exception:
	push 0xFFFFFFFF		;no error code
	push 1				;vector_no = 1
	jmp exception
_nmi:
	push 0xFFFFFFFF		;no error code
	push 2				;vector_no = 2
	jmp exception
_breakpoint_exception
	push 0xFFFFFFFF		;no error code
	push 3				;vector_no = 3
	jmp exception
_overflow:
	push 0xFFFFFFFF		;no error code
	push 4				;vector_no = 4
	jmp exception
_bounds_check:
	push 0xFFFFFFFF		;no error code
	push 5				;vector_no = 5
	jmp exception
_invalid_opcode:
	push 0xFFFFFFFF		;no error code
	push 6				;vector_no = 6
	jmp exception
_coproc_not_avalible:
	push 0xFFFFFFFF		;no error code
	push 7				;vector_no = 7
	jmp exception
_double_fault:
	push 8				;vector_no = 8
	jmp	exception
_coproc_seg_overrun:
	push 0xFFFFFFFF		;no error code
	push 9				;vector_no = 9
	jmp exception
_invalid_tss:
	push 10				;vector_no = 10
	jmp	exception
_seg_not_present:
	push 11				;vector_no = 11
	jmp	exception
_stack_exception:
	push 12				;vector_no = 12
	jmp	exception
_general_protection:
	push 13				;vector_no = 13
	jmp	exception
_page_fault:
	push 14				;vector_no = 14
	jmp	exception
_coproc_error:
	push 0xFFFFFFFF		;no error code
	push 15				;vector_no = 15
	jmp exception

exception:
	call _exception_handler
	hlt
