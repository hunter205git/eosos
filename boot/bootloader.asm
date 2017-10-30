%define DRIVE_FLOPPY_A    0x00     ;drive number used in int 13h
%define DRIVE_FLOPPY_B    0x01     ;drive number used in int 13h
%define DRIVE_HD_1        0x80     ;drive number used in int 13h
%define DRIVE_HD_2        0x81     ;drive number used in int 13h
%define DISK_READ         0x02     ;action code of read
%define COMMAND_DISK      0x13     ;bios disk operation command
%define SECTOR_PER_TRACK  18       ;Sector number per track. 1.44mb hd floppy 
%define TRACK_PER_HEAD    80       ;Track number per head. 1.44mb hd floppy
%define HEAD_PER_DISK     2        ;Head number per disk.
%define BOOTUP_SEGMENT    0x07c0   ;boot sector address by BIOS
%define OS_IMAGE_SEGMENT  0x1000   ;1000:0000
%define CHANGEMODE_SIZE   2        ;protection mode setup codesize 
%define OSKERNEL_SIZE     800      ;operation kernel code size...400*0.5k=200k
%define TOTAL_CODE_LENGTH (CHANGEMODE_SIZE+OSKERNEL_SIZE) 

bits 16                            ;This boot sector's code is running under real mode.
org 0x0000                         ;code start address
BootStart:                                  
    cli                            ;clear interrupt enable flag
    jmp BOOTUP_SEGMENT:L_BootStartAt7c00 ;change cs to 0x07c0
L_BootStartAt7c00:
    mov ax,BOOTUP_SEGMENT          ;set 07c0:0000 to ds,ss,
    mov ds,ax                      ;ds=07c0
    mov ss,ax                      ;ss=07c0
    mov es,ax                      ;es=0x07c0
    mov sp,0x3fe                   ;set stack pointer at 07c0:0x03fe = 7ffe
L_LoadOsImage:
    mov ax,0x0600		           ;ah=0x06 scroll up,al=0x00 scroll 0 rows
    mov bx,0x0700		           ;bh=0x07 normal attribute
    mov cx,0		               ;ch=0 start row,cl=0 start column
    mov dx,0x184f		           ;dh=0x18 end at 24 row,dl=4f end at 79 column
    int 10h                        ;text mode command
    mov ah,0x02                    ;set cursor position
    mov bh,0x00                    ;page 0
    mov dh,0x00                    ;row=1
    mov dl,0x00                    ;column=0
    int 10h                        ;text mode command
    call PrintBootMessage          ;print load image message   
    mov byte [CurrentSector],0x03
    mov byte [CurrentHead],0x00
    mov byte [CurrentTrack],0x00
    call LoadOsImage               ;load image to 9000:0000 
    call PrintLoadKernelOkMessage  ;print load image ok
    ;hlt
    jmp OS_IMAGE_SEGMENT:0         ;jump to real mode initial code address

LoadOsImage:                        
    push es                        ;prestore es,because it will be used in reading floppy
    mov ax,OS_IMAGE_SEGMENT        ;[0x1000:0x0000]
    mov es,ax                      ;es=0x1000
    mov bx,0                       ;0x0000...offset in destination segment [9000:0000]
    xor cx,cx                      ;clear cx...xor is [11.0],[00.0],[10.1],[01.1]
L_LoadOsImageLoop:
    mov ah,DISK_READ               ;read command
    mov al,0x02                    ;2 sectors per read command
    mov ch,byte [CurrentTrack]     ;track number
    mov cl,byte [CurrentSector]    ;sector number
    mov dh,byte [CurrentHead]      ;head number...disk side
    mov dl,DRIVE_FLOPPY_A          ;drive a:
    int COMMAND_DISK               ;execute read command
    jc L_LoadOsImageError          ;error if carry==1
    dec word [TotalSector]         ;total sector-=1
    dec word [TotalSector]         ;total sector-=1
    jz L_LoadOsImageDone           ;change to next track if last sector in track is reached
L_AdvanceBufferAddress:            ;advance [es:bx] by 2*512
    cmp bx,63*2*512                ;check segment boundary
    jae L_SegmentAdvance           ;if segment boundary is reached,change to next segment
    add bx,1024                    ;else offset+=1024...get new [es:bs]
    jmp L_PrepareNextRead          ;do next read command 
L_SegmentAdvance:
    mov bx,es                      ;get segment value
    add bx,4*1024                  ;add 64k/16=4k to next segment value
    mov es,bx                      ;update es segment value
    xor bx,bx                      ;clear bx...bx must be 0,now...get new [es:bs]
L_PrepareNextRead:                 ;prepare parameter for next read command
    inc byte [CurrentSector]       ;advance current sector value
    inc byte [CurrentSector]       ;advance current sector value
    cmp byte [CurrentSector],SECTOR_PER_TRACK  ;check if it reachs track boundary
    jae L_TrackAdvance             ;if reach track boundary advance track number
    jmp L_LoadOsImageLoop          ;else continue do read command
L_TrackAdvance:
    cmp byte [CurrentHead],0x0     ;check if head==0 
    je L_NextTrackInHead1          ;if head==0,jump to head 1
L_NextTrackInHead0:
    mov byte [CurrentSector],0x01  ;initialize current sector number
    mov byte [CurrentHead],0x00    ;switch to head 1
    inc byte [CurrentTrack]        ;advance track number 
    cmp byte [CurrentTrack],TRACK_PER_HEAD ;check if reaching head boundary
    jae L_LoadOsImageDone          ;if reach track bounary,stop load image
    jmp L_LoadOsImageLoop          ;else continue to do read command
L_NextTrackInHead1:
    mov byte [CurrentSector],0x01  ;initialize current sector number
    mov byte [CurrentHead],0x01
    jmp L_LoadOsImageLoop
L_LoadOsImageDone:
    mov dx,0x03f2                  ;shut down floppy disk controller
    mov al,0x00                    ;shut down floppy disk controller
    out dx,al                      ;shut down floppy disk controller
    pop es                         ;get original es
    ret
		
L_LoadOsImageError:    	
    pop es                         	;get original es
    mov ah,0x03                    	;read cursor position
    mov bh,0x00                    	;1st page
    int 0x10                       	;text mode command,return dh=row number,dl=line number
    mov cx,8                       	;string length
    mov bx,0x0007                  	;bh=0x00 back ground color black,bl=7 foreground color white
    mov bp,ErrorMessage            	;string address
    mov ax,0x1301                  	;ah=0x13...write string,al=0x01...write mode
    int 0x010                      	;text mode command
L_LoadOsImageDeadLoop2:            	;dead loop
    jmp L_LoadOsImageDeadLoop2     	;dead loop
    ret                            	;this line should never execute
	
PrintBootMessage:	
    mov ah,0x03                    	;Åª¨ú´å¼Ð¦ì¸m get cursor position command
    mov bh,0x00                    	;page number 
    int 0x10                       	;screen io...dh=row number,dl=line number
    mov cx,40	                  	;string length
    mov bx,0x0007                  	;bl=7...color
    mov bp,BootMessage             	;string address
    mov ax,0x1301                  	;ah=0x13...write string,al=0x01...write mode
    int 0x10                       	;show meaasge on video
	call PrintAuthor
    ret     						;ªð¦^
			
PrintLoadKernelOkMessage:	
    mov ah,0x03                    	;get cursor position command
    mov bh,0x00                    	;page number 
    int 0x10                       	;screen io...dh=row number,dl=line number
    mov cx,51                     	;string length
    mov bx,0x0007                  	;bl=7...color
    mov bp,LoadingOkMessage        	;string address
    mov ax,0x1301                  	;ah=0x13...write string,al=0x01...write mode
    int 0x10                       	;show meaasge on video
    ret    

PrintAuthor:	
	mov ah,0x03                    	;get cursor position command
    mov bh,0x00                    	;page number 
    int 0x10                       	;screen io...dh=row number,dl=line number
    mov cx,102                      	;string length
    mov bx,0x0007                  	;bl=7...color
    mov bp,AuthorMessage        	;string address
    mov ax,0x1301                  	;ah=0x13...write string,al=0x01...write mode
    int 0x10                       	;show meaasge on video
    ret    
MessagePool:
    ErrorMessage:
        db 0x0d
        db 0x0a
        db 'Fault.'
        db 0x00
    BootMessage: ;26 bytes length
        db 0x0d
        db 0x0a
        db 'Welcome to EOSLAB operating system.'
        db 0x0d
        db 0x0a
		db 0x00
    LoadingOkMessage: ;23 bytes length
        db 0x0d
        db 0x0a
        db 'Loading OS ------------------------ [ SUCCESSED ]'
		db 0x00
    AuthorMessage:
        db 0x0d
        db 0x0a
		db 'Copyright (C) Forever'
		db 0x0d
		db 0x0a
		db 'Hunter Hsieh'
		db 0x0d
		db 0x0a
		db 'M10317004'
		db 0x0d
		db 0x0a
		db 0x00
        
LocalVariables:        
CurrentSector: db 0x03
CurrentTrack:  db 0x00
CurrentHead:   db 0x00   
TotalSector:   dw TOTAL_CODE_LENGTH

times 510 - ($ - $$) db 0x00
dw 0xaa55

