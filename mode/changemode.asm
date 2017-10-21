%include "macro.inc"

%define REALMODE_SEGMENT       0x1000     ;real mode segment 
%define REALMODE_SEGMENT_PHYADDR	REALMODE_SEGMENT * 10h        
%define REALMODE_IMAGE_SIZE    0x0200     ;real mode code size 
%define REALMODE_STACK_POINTER 0x1fe      ;real mode stack pointer
%define PROTECTIONMODE_START   0x00010200 ;protection mode code address
%define KERNEL_ADDRESS         0x00012000 ;
%define CHANGEMODE_SIZE        0x2000     ;
%define CODE_SEGMENT           0x08
%define DATA_SEGMENT           0x10
%define GRAPH_SEGMENT          0x18
PageDirBase		equ	200000h	; 頁目錄開始位址:	2M
PageTblBase		equ	201000h	; 頁表開始位址:		2M +  4K

bits 16          
org 0x0000
RealModeStart:                    ;range of realinit is [0x1000:0x0000]~[0x1000:0x03FF]
    jmp L_RealModeInitial
times (3-($-$$)) db 0x00          ;make sure this address is at 0x03    
RealModeMessage: db "realmode",0  ;string of realmode
RealModeVariable:                 ;this line should be at 0x0001000C

L_RealModeInitial:
    mov ax,REALMODE_SEGMENT      ;ax=0x1000
    mov ds,ax                    ;data segment 0x1000
    mov es,ax                    ;extra segment 0x1000
    mov ss,ax                    ;stack segment 0x1000
    mov sp,REALMODE_STACK_POINTER ;stack pointer [ss:sp]
                                 ;prepare to enter protected mode.                                 
    jmp L_EnterProtectionMode
    
L_EnterProtectionMode:   
    in al,0x92						;從real mode轉成protected mode，必須啟用A20位址線以使用1M以上的位址
	or al,0x02					;I/O port 92h的bit 1被定義為A20的開關
    out 0x92,al

    lgdt [GdtLoader]            ;load gdt table

    mov eax,cr0                  ;get cpu cr0 register
    or eax,0x01                  ;set the PE bit of CR0 register.
    mov cr0,eax                  ;enter the protected mode.
    jmp dword CODE_SEGMENT:PROTECTIONMODE_START  ;protected mode...run protect mode code
                                         ;0x08 is byte offset in GdtTables                      
                                         
times (REALMODE_IMAGE_SIZE-($-$$)) db 0x00   ; fill out the rest of 512 bytes with 0x00

bits 32 
ProtectionModeStart:                    
    jmp L_ProtectionMode
ProtectionModeMessage: db "protectionmode",0 ;string of protection mode
L_ProtectionMode:

    mov ax,DATA_SEGMENT
    mov ds,ax
    mov ss,ax
    mov es,ax
    mov fs,ax
	mov esp,TopOfStack
	mov ax,GRAPH_SEGMENT
    mov gs,ax                    ;graphics segment is not used,set it to extra segment gdt entry is at 0x28 of GdtTable
	
SetupPaging:
	;初始化Page Directory
	mov ax, DATA_SEGMENT
	mov es, ax
	mov ecx, 1024	;假設記憶體有4G，需1024個PDE
	xor edi, edi
	mov edi, PageDirBase
	xor eax, eax
	mov eax, PageTblBase | 0x01 | 0x02 | 0x04 ;Page directory entry (W=1, U=1, R=1)
.1:
	stosd	;Store double word in EAX at [ES:EDI] and increment the addressing resgisters by 4
	add eax, 4096 ;PageTblBase++
	loop .1
	
	;初始化Page Table
	mov	ecx, 1024 * 1024	; 每個PDE對應到1024個PTE，共有1024個PDE，因此共有1M個PTE
	xor	edi, edi
	mov edi, PageTblBase
	xor	eax, eax
	mov	eax, 0x01 | 0x02 | 0x04 ;Page table entry (W=1, U=1, R=1)
.2:
	stosd
	add	eax, 4096		; 每一個PTE對應到4K記憶體
	loop	.2
	
	;設定cr3
	mov eax, 0x200000 ;The upper 20 bits of CR3 are the page directory base register (PDBR),
	mov cr3, eax			 ; which stores the physical address of the first page directory entry
	
	;設定cr0
	mov eax, cr0
	or eax, 0x80000000 ; Set the PG (Paging) bit of the CR0 register
	mov cr0, eax

    jmp dword CODE_SEGMENT:KERNEL_ADDRESS
       
;GDT------------------------------------------------------------------------------
GdtTable:
	NullGdt:			Descriptor	0,		 0,			0
	CodeSegmentGdt:		Descriptor	0,		 0fffffh,	DA_CR 	| DA_32 | DA_G_4KB
	DataSegmentGdt:		Descriptor	0,		 0fffffh,	DA_DRW	| DA_32	| DA_G_4KB	
	GraphicSegmentGdt:	Descriptor	0B8000h, 00ffffh,	DA_DRW
GdtByteCount	equ	$ - GdtTable
GdtLoader		dw 	GdtByteCount - 1
				dd	REALMODE_SEGMENT_PHYADDR + GdtTable
;--------------------------------------------------------------------------------

StackSpace:	times	1000h	db	0
TopOfStack	equ	REALMODE_SEGMENT_PHYADDR + $				
times (CHANGEMODE_SIZE-($-$$)) db 0x00   ; fill out the rest of 1024 bytes with 0x00    
