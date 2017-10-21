#include "global.h"

/// Dump and print the memory data
/// args1: start mem_dump address
/// args2: dumping memory length (unit: 32bit)
/// args3: direction=0 (Low -> High) ; direction=1 (High -> Low)
void mem_dump(int address, int mem_len, int direction)
{
	int* mem_ptr;
	mem_ptr=address;
	
	int i,dir;
	if(direction==0)
		dir=1;
	else if (direction == 1)
		dir=-1;
	else
		return;
		
	for(i=0;i<mem_len;i++)
	{
		print_int_hex(*mem_ptr);
		print_str("\n");
		mem_ptr+=dir;
	}

	
}

void print_int(int value)
{
	int i, j=0, firstDigitFlag = 0, digit;
	char string[16]="";
	if(value==0)
		string[j]='0';
	else
	{
		for(i=1000000000; i>0; i/=10)
		{
			digit = value / i;
			if(firstDigitFlag == 1 || digit != 0) 
			{
				string[j]=digit+'0';
				j++;
				value -= digit * i; //minus the first digit value
				firstDigitFlag = 1; //already meet the first digit
			}
		}
	}
	print_str(string);
}

void print_int_hex(int value)
{
	char string[16]="";
	char *	ptr = string;
	char	digit;
	int	i;

	*ptr++ = '0';
	*ptr++ = 'x';
	for(i=28;i>=0;i-=4)
	{
			digit = (value >> i) & 0xF;			
			digit += '0';
			if(digit > '9'){
				digit += 7;
			}
			*ptr++ = digit;
	}
	*ptr = 0;
	print_str(string);
}

#define TIMER0 0x40
#define TIMER_MODE 0x43
#define RATE_GENERATOR 0x34
#define TIMER_FREQ 1193182L
#define HZ 1000

void push(int data)
{
	p_task_stack-=4;
	*((u32*)(p_task_stack))=data;	
}
void pushad()
{
	p_task_stack-=(4*8);
}

void set_timer()
{
	out_byte(TIMER_MODE,RATE_GENERATOR);
	out_byte(TIMER0, (unsigned char)(TIMER_FREQ/HZ));
	out_byte(TIMER0, (unsigned char)(TIMER_FREQ/HZ >> 8));
}

void delay(int time)
{
	int i, j, k;
	for(k=0;k<time;k++){
		for(i=0;i<10;i++){	/*for Virtual PC	*/
			for(i=0;i<1000;i++){/*	for Bochs	*/
				for(j=0;j<5000;j++){}
			}
		}
	}
}

void endLine()
{
	int newCursor = disp_pos;
	newCursor /= 160; //160 bytes per row
	newCursor ++;
	if(newCursor > 24) //there are 24 rows in screen
		scrollup();
	newCursor *= 160;
	disp_pos = newCursor;
}

void scrollup()
{
	int i, charPosition;
	for(i=0; i<3838; i++)
	{
		charPosition = i+160; //start from second row of screen
		movScrnChar(charPosition-160, charPosition); //move the char to upper row
	}
	cleanline(); //clean the last row
}