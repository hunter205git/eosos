;Fill the Descriptor Table
;	%macro [macroName] [numberOfParameters]
;	%endmacro
;WAY TO USE
;LABEL:	Descriptor	Base, Limit,	Attribute

%macro Descriptor 3
	dw %2 & 0FFFFh
	dw %1 & 0FFFFh
	db (%1>>16) & 0FFh
	dw ((%2>>8) & 0F00h) | (%3 & 0F0FFh)
	db (%1>>24) & 0FFh
%endmacro

;Descriptor attribute
;----------------------------------------------------------------------------
; Type definitions
;       DA_  : Descriptor Attribute
;		G	 : Granularity
;       D    : Data Segment
;       C    : Code Segment
;       S    : System Segment
;       R    : Read
;       RW   : Read & write
;       A    : Access
;----------------------------------------------------------------------------
DA_16		EQU 0000h
DA_32		EQU	4000h	; 32 位段

DA_G_1B		EQU	0000h	; Limit的單位為1B
DA_G_4KB	EQU	8000h	; Limit的單位為4KB

DA_DPL0		EQU	  00h	; DPL = 0
DA_DPL1		EQU	  20h	; DPL = 1
DA_DPL2		EQU	  40h	; DPL = 2
DA_DPL3		EQU	  60h	; DPL = 3
;----------------------------------------------------------------------------
; 存儲段描述符類型值說明
;----------------------------------------------------------------------------
DA_DR		EQU	90h	; 存在的只讀數據段類型值
DA_DRW		EQU	92h	; 存在的可讀寫數據段屬性值
DA_DRWA		EQU	93h	; 存在的已訪問可讀寫數據段類型值
DA_C		EQU	98h	; 存在的只執行代碼段屬性值
DA_CR		EQU	9Ah	; 存在的可執行可讀代碼段屬性值
DA_CCO		EQU	9Ch	; 存在的只執行一致代碼段屬性值
DA_CCOR		EQU	9Eh	; 存在的可執行可讀一致代碼段屬性值