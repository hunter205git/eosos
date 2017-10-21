#ifndef _PROTECTMODE_H_
#define _PROTECTMODE_H_

typedef struct s_descriptor
{
	u16 limit_low;
	u16 base_low;
	u8 base_mid;
	u8 attr1;
	u8 limit_high_attr2;
	u8 base_high;
}DESCRIPTOR;

typedef struct s_gate
{
	u16 offset_low;
	u16 selector;
	u8 dcount;
	u8 attr;
	u16 offset_high;
}GATE;

//GDT index
#define INDEX_NULL			0
#define INDEX_CODE_SEG	1
#define INDEX_DATA_SEG	2
#define INDEX_GRAPH_SEG	3
#define INDEX_LDTA			4

#define INDEX_KERNEL_CS INDEX_CODE_SEG
#define INDEX_KERNEL_DS INDEX_DATA_SEG
#define INDEX_KERNEL_GS INDEX_GRAPH_SEG

//GDT Selector
#define SELECTOR_NULL				0
#define SELECTOR_CODE_SEG		0x08
#define SELECTOR_DATA_SEG		0x10
#define SELECTOR_GRAPH_SEG	0x18
#define SELECTOR_LDTA				0x20

#define SELECTOR_KERNEL_CS SELECTOR_CODE_SEG
#define SELECTOR_KERNEL_DS SELECTOR_DATA_SEG
#define SELECTOR_KERNEL_GS SELECTOR_GRAPH_SEG

//DPL
#define	PRIVILEGE_KRNL	0
#define	PRIVILEGE_TASK	1
#define	PRIVILEGE_USER	3

//Descriptor Attribute
#define	DA_LDT	0x4082 //G=0; D=1; P=1; DPL=0; S=0; TYPE=0010

//Interrupt vector
#define	INT_VECTOR_DIVIDE			0x0 //除法錯
#define	INT_VECTOR_DEBUG			0x1 //測試異常
#define	INT_VECTOR_NMI				0x2 //非遮罩中斷
#define	INT_VECTOR_BREAKPOINT		0x3 //測試中斷點
#define	INT_VECTOR_OVERFLOW			0x4 //溢位
#define	INT_VECTOR_BOUNDS			0x5	//越界
#define	INT_VECTOR_INVAL_OP			0x6	//無效操作碼
#define	INT_VECTOR_COPROC_NOT		0x7 //設備不可用 (無數學輔助處理器)
#define	INT_VECTOR_DOUBLE_FAULT		0x8 //雙重錯誤
#define	INT_VECTOR_COPROC_SEG		0x9 //輔助處理器段越界
#define	INT_VECTOR_INVAL_TSS		0xA //無效TSS
#define	INT_VECTOR_SEG_NOT			0xB //段不存在
#define	INT_VECTOR_STACK_FAULT		0xC //堆疊段錯誤
#define	INT_VECTOR_PROTECTION		0xD //一般保護錯誤
#define	INT_VECTOR_PAGE_FAULT		0xE //頁錯誤
//...
#define	INT_VECTOR_COPROC_ERR		0x10//x86FPU浮點錯
//...
#define INT_VECTOR_IRQ0				0x20
#define INT_VECTOR_IRQ8				0x28

//Gate attribute
#define INT_GATE_ATTR	0x8E //P=1 S=0 TYPE=1110


#endif /* _PROTECTMODE_H_ */