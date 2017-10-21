[section .text]

extern _disp_pos
extern _scrollup
extern _endLine

global _print_str
global _print_color_str
global _memcpy
global _init_8259A
global _out_byte
global _cleanline
global _movScrnChar
global _strcpy

;--------------------------------------------------------------
; void print_str(char * string)
;--------------------------------------------------------------
_print_str:
	push ebp				; create stack frame
	mov ebp, esp
	mov esi, [ebp + 8]		; skip old EIP and grab the first argument (string pointer)
	mov edi, [_disp_pos]		; get cursor position
	mov ah, 0Fh				; set the char color
.1:
	lodsb					; loads a byte from [DS:ESI] into AL
	test al,al
	jz		.3				; jump if ZF ==1
	cmp al, 0Ah				; check if it's "\n"
	jnz .2					; jump if not "\n"
	mov 	[_disp_pos], edi
	call _endLine
	mov edi, [_disp_pos]
	jmp .1
.2:
	mov		[gs:edi], ax	; print the char(with color) in ax
	add 	edi,2			; move to next 2 bytes in VGA memory
	;Needs scroll up or not----------------------------------------
	cmp 	edi,3998
	jbe		.1				; jump if edi <= 3998
	call	_scrollup		; else scroll the screen
	mov		edi, [_disp_pos]	;get cursor position
	;--------------------------------------------------------------
.3:	
	mov 	[_disp_pos], edi	; Save the cursor
	mov ebx,edi
	pop     ebp             ; restore the base pointer
    ret
	
;--------------------------------------------------------------
; void print_color_str(char * string, int text_color)
;--------------------------------------------------------------
_print_color_str:
	push ebp				; create stack frame
	mov ebp, esp
	
	mov esi, [ebp + 8]		; grab the first argument (string pointer)
	mov ah, [ebp + 12]		; grab the second argument (text color)
	mov edi, [_disp_pos]		; get cursor position
.1:
	lodsb					; loads a byte from [DS:ESI] into AL
	test al,al
	jz		.3				; jump if ZF ==1
	cmp al, 0Ah				; check if it's "\n"
	jnz .2					; jump if not "\n"
	mov 	[_disp_pos], edi
	call _endLine
	mov edi, [_disp_pos]
	jmp .1
.2:
	mov		[gs:edi], ax	; print the char(with color) in ax
	add 	edi,2			; move to next 2 bytes in VGA memory
	;Needs scroll up or not----------------------------------------
	cmp 	edi,3998
	jbe		.1				; jump if edi <= 3998
	;call	_scrollup		; else scroll the screen
	mov  edi,1600
	mov	[_disp_pos], edi 	;get cursor position
	;--------------------------------------------------------------
.3:	
	mov 	[_disp_pos], edi	; Save the cursor
	pop     ebp             ; restore the base pointer
    ret

;--------------------------------------------------------------
; void* memcpy(void* es:ptr_dst, void* ds:ptr_src, int size);
;--------------------------------------------------------------
_memcpy:
	push	ebp
	mov	ebp, esp

	push	esi
	push	edi
	push	ecx

	mov	edi, [ebp + 8]	; Destination
	mov	esi, [ebp + 12]	; Source
	mov	ecx, [ebp + 16]	; Counter
.1:
	cmp	ecx, 0		; 判斷計數器
	jz	.2		; 計數器為零時跳出

	mov	al, [ds:esi]		
	inc	esi			
					; 逐字元移動
	mov	byte [es:edi], al
	inc	edi

	dec	ecx		; 計數器減一
	jmp	.1		; 循環
.2:
	mov	eax, [ebp + 8]	; 返回值

	pop	ecx
	pop	edi
	pop	esi
	mov	esp, ebp
	pop	ebp

	ret
	
;-----------------------------------------------------------
;void strcpy(char* p_dst, char* p_src)
;-----------------------------------------------------------
_strcpy:
	push ebp
	mov ebp,esp
	
	mov edi,[ebp+8] ;source
	mov esi,[ebp+12] ;destination
.1:	
	lodsb
	test al,al
	jz .2
	mov byte [ds:edi],al
	inc edi
	jmp .1
.2:
	pop ebp
	
	ret

;-----------------------------------------------------------
;void init_8258A();
;-----------------------------------------------------------
_init_8259A:
	mov	al, 011h
	out	020h, al	; 主8259, ICW1.
	call	io_delay    
                            
	out	0A0h, al	; 從8259, ICW1.
	call	io_delay    
                            
	mov	al, 020h	; IRQ0 對應中斷向量 0x20
	out	021h, al	; 主8259, ICW2.
	call	io_delay    
                            
	mov	al, 028h	; IRQ8 對應中斷向量 0x28
	out	0A1h, al	; 從8259, ICW2.
	call	io_delay    
                            
	mov	al, 004h	; IR2 對應從8259
	out	021h, al	; 主8259, ICW3.
	call	io_delay    
                            
	mov	al, 002h	; 對應主8259的 IR2
	out	0A1h, al	; 從8259, ICW3.
	call	io_delay    
                            
	mov	al, 001h    
	out	021h, al	; 主8259, ICW4.
	call	io_delay    
                            
	out	0A1h, al	; 從8259, ICW4.
	call	io_delay

	mov	al, 11111110b	; 僅僅開啟定時器中斷
	out	021h, al	; 主8259, OCW1.
	call	io_delay

	mov	al, 11111111b	; 屏蔽從8259所有中斷
	out	0A1h, al	; 從8259, OCW1.
	call	io_delay
	
io_delay:
	nop
	nop
	nop
	nop
	ret
	
;-------------------------------------------------------
;void out_byte()
;-------------------------------------------------------
_out_byte:
	mov	edx, [esp + 4]		; port
	mov	al, [esp + 4 + 4]	; value
	out	dx, al
	nop
	nop
	ret
	
;-------------------------------------------------------
;-------------------------------------------------------
_cleanline: ;clean the last line of screen
	mov		edi, (80*24+0)*2	; set edi to the last line of screen
.1:
	mov 	ax,0
	mov		[gs:edi],ax		; print nothing
	add		edi,2			; move to next 2 bytes in VGA memory to print next char
	cmp		edi,3998		; if edi reach the last char on screen
	ja		.2				; jmp if yes
	jmp		.1
.2:
	mov		eax,3840
	mov		[_disp_pos], eax	; Save the cursor
	ret
	
_movScrnChar: ;scroll the screen up
	push    ebp             ; create stack frame
    mov     ebp, esp
    mov     eax, [ebp+8]    ; grab the first argument
	mov		ebx, [ebp+12]	; grab the second argument (char with color)
	mov		di, [gs:ebx]	; get the char
	mov		[gs:eax],di		; print the char to the upper line
	pop     ebp             ; restore the base pointer
    ret