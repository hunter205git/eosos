;/******************************
;* description: IBM AT pc bootup sector
;*              Bios load this sector onto 0000:7c00 and execute it
;*              This boot sector load os image onto 0x00010000
;*              and write into hard disk.
;*              This boot sector is used intall to install OS on hard disk.
;*
;* filename: bootsect_install.asm
;* author: Book Chen
;* date:20091105
;*******************************
;*/

%define DRIVE_FLOPPY_A       0x00     ;drive number used in int 13h
%define DRIVE_FLOPPY_B       0x01     ;drive number used in int 13h
%define DRIVE_HD_1           0x80     ;drive number used in int 13h
%define DRIVE_HD_2           0x81     ;drive number used in int 13h
%define DISK_READ            0x02     ;action code of read
%define DISK_WRITE           0x03     ;action code of read
%define COMMAND_DISK         0x13     ;bios disk operation command
%define SECTOR_PER_CYLINDER  63       ;1~63 in chs
%define MAXHEAD_IN_HD        15       ;maximun head number in hd drive
%define FDC_SECTOR_PER_TRACK 18       ;Sector number per track. 1.44mb hd floppy 
%define FDC_TRACK_PER_HEAD   80       ;Track number per head. 1.44mb hd floppy
%define FDC_HEAD_PER_DISK    2        ;Head number per disk.
%define BOOTUP_SEGMENT       0x07c0   ;boot sector bootup segment
%define OS_IMAGE_SEGMENT     0x1000   ;1000:0000
%define BOOTSECT_SIZE        2        ;boot sector code size
%define CHANGEMODE_SIZE      2        ;protection mode setup codesize 
%define OSKERNEL_SIZE        800      ;operation kernel code size...400*0.5k=200k
%define TOTAL_CODE_LENGTH    (BOOTSECT_SIZE+CHANGEMODE_SIZE+OSKERNEL_SIZE)

bits 16                               ;This boot sector's code is running under real mode.
org 0x0000                            ;code start address
BootSectorStart:              
    cli                               ;clear interrupt enable flag
    jmp BOOTUP_SEGMENT:L_BootStartAt7c00 ;change cs to 0x7c0
L_BootStartAt7c00:
    mov ax,BOOTUP_SEGMENT             ;set 07c0:0000 to ds,ss,
    mov ds,ax                         ;ds=0x07c0
    mov ss,ax                         ;ss=0x07c0
    mov es,ax                         ;es=0x07c0
    mov sp,0x3fe                      ;set stack pointer at 07c0:3ff0(0x7ffe),stack grows up to down
L_ClearScreen:
    mov ax,0600h		              ;ah=0x06 scroll up,al=0x00 scroll 0 rows
    mov bx,0700h		              ;bh=0x07 normal attribute
    mov cx,0		                  ;ch=0 start row,cl=0 start column
    mov dx,0x184f		              ;dh=0x18 end at 24 row,dl=4f end at 79 column
    int 10h                           ;text mode command
    mov ah,0x02                       ;set cursor position
    mov bh,0x00                       ;page 0
    mov dh,0x01                       ;row=1
    mov dl,0x00                       ;column=0
    int 10h                           ;text mode command
L_LoadImageToRam:
    call PrintLoadingMessage          ;print load image message
    mov word [TotalSector],TOTAL_CODE_LENGTH
    mov byte [CurrentSector],0x03
    mov byte [CurrentTrack],0x00
    mov byte [CurrentHead],0x00
    call LoadImageFromFdc             ;load image to 1000:0000
L_WriteImageToHarddisk:
    mov word [TotalSector],TOTAL_CODE_LENGTH
    mov byte [CurrentSector],0x01  
    mov byte [CurrentCylinder],0x00
    mov byte [CurrentHead],0x00
    call WriteImageToHd               ;write image to hard disk
    call PrintDoneMessage             ;print write done message on screen
    hlt                               ;stop program here
    ;jmp (OS_IMAGE_SEGMENT):0         ;jump to real mode initial code address
    
LoadImageFromFdc:                        
    push es                           ;preserve es because es will be used in loading message
    mov ax,OS_IMAGE_SEGMENT           ;0x9000
    mov es,ax                         ;es=0...destination segment [9000:0000]
    mov bx,0                          ;0x0000...offset in destination segment [9000:0000]
    xor cx,cx                         ;clear cx...xor is [11.0],[00.0],[10.1],[01.1]
L_LoadImageLoop:
    mov ah,DISK_READ                   ;read command
    mov al,0x02                       ;2 sectors per read command
    mov ch,byte [CurrentTrack]        ;track number
    mov cl,byte [CurrentSector]       ;sector number
    mov dh,byte [CurrentHead]         ;head number...disk side
    mov dl,DRIVE_FLOPPY_A             ;drive a:
    int COMMAND_DISK                  ;execute read command
    jc L_LoadImageError               ;error if carry==1
    dec word [TotalSector]            ;total sector-=1
    dec word [TotalSector]            ;total sector-=1
    jz L_LoadImageDone                ;change to next track if last sector in track is reached
L_LoadImageAdvanceBufferAddress:      ;advance [es:bx] by 1024
    cmp bx,63*1024                    ;check segment boundary of buffer
    je L_SegmentAdvance               ;if segment boundary is reached,change to next segment
    add bx,1024                       ;else offset+=1024...get new [es:bs]
    jmp L_PrepareNextRead             ;do next read command 
L_SegmentAdvance:
    mov bx,es                         ;get segment value
    add bx,4*1024                     ;add 64k/16=4k to next segment value
    mov es,bx                         ;update es segment value
    xor bx,bx                         ;clear bx...bx must be 0,now...get new [es:bs]
L_PrepareNextRead:                    ;prepare parameter for next read command
    inc byte [CurrentSector]          ;advance current sector value
    inc byte [CurrentSector]          ;advance current sector value
    cmp byte [CurrentSector],FDC_SECTOR_PER_TRACK ;check if reach track boundary...18
    jae L_TrackAdvance                ;if reach track boundary advance track number...CurrentSector=1.3.5.7.9.11.13.15.17.19->19 is invalid
    jmp L_LoadImageLoop               ;else do read command
L_TrackAdvance:
    cmp byte [CurrentHead],0x0        ;check if head==0 
    je L_NextTrackInHead1             ;if head==0,jump to head 1
L_NextTrackInHead0:
    mov byte [CurrentSector],0x01     ;initialize current sector number
    mov byte [CurrentHead],0x00       ;switch to head 1
    inc byte [CurrentTrack]           ;advance track number 
    cmp byte [CurrentTrack],FDC_TRACK_PER_HEAD    ;check if reaching head boundary
    jae L_LoadImageDone               ;if reach head bounary,advance to next head...CurrentTrack=0.1.2.3...79.80->80 is invalid
    jmp L_LoadImageLoop               ;else do read command
L_NextTrackInHead1:
    mov byte [CurrentSector],0x01     ;initialize current sector number
    mov byte [CurrentHead],0x01
    jmp L_LoadImageLoop
L_LoadImageDone:
    mov dx,0x03f2                     ;shut down floppy disk controller
    mov al,0x00                       ;shut down floppy disk controller
    out dx,al                         ;shut down floppy disk controller
    pop es                            ;get original es
    ret

WriteImageToHd:                 
    push es                           ;preserve es because es is used as buffer pointer for write disk
    mov ax,OS_IMAGE_SEGMENT           ;0x1000
    mov es,ax                         ;es=0...destination segment [1000:0000]
    mov bx,0                          ;0x0000...offset in destination segment [1000:0000]
    xor cx,cx                         ;clear cx...xor is [11.0],[00.0],[10.1],[01.1]
L_WriteImageLoop:
    mov ah,DISK_WRITE                 ;write command
    mov al,0x01                       ;1 sectors per read command
    mov ch,byte [CurrentCylinder]     ;cylinder number
    mov cl,byte [CurrentSector]       ;sector number
    mov dh,byte [CurrentHead]         ;head number...disk side
    mov dl,DRIVE_HD_1                 ;hard disk 1
    int COMMAND_DISK                  ;execute read command
    jc L_WriteImageError              ;error if carry==1
    dec word [TotalSector]            ;total sector-=1
    jz L_WriteImageDone               ;change to next track if last sector in track is reached
L_WriteImageAdvanceBufferAddress:     ;advance [es:bx] by 1024
    cmp bx,127*512                    ;check segment boundary of buffer
    je L_WriteImageSegmentAdvance     ;if segment boundary is reached,change to next segment
    add bx,512                        ;else offset+=1024...get new [es:bs]
    jmp L_WriteImagePrepareNextWrite  ;do next write command 
L_WriteImageSegmentAdvance:
    mov bx,es                         ;get segment value
    add bx,4*1024                     ;add 64k/16=4k to next segment value...[segemnt:0x10000]->[segment+4k:00]
    mov es,bx                         ;update es segment value
    xor bx,bx                         ;clear bx...bx must be 0,now...get new [es:bs]
L_WriteImagePrepareNextWrite:         ;prepare parameter for next write command
L_WriteImageSectorAdvance:
    inc byte [CurrentSector]          ;advance current sector value
    cmp byte [CurrentSector],SECTOR_PER_CYLINDER
    ja L_WriteImageHeadAdvance        ;if sector>63
    jmp L_WriteImageLoop              ;else do read command
L_WriteImageHeadAdvance:
    mov byte [CurrentSector],0x01
    inc byte [CurrentHead]
    cmp byte [CurrentHead],MAXHEAD_IN_HD ;check if head==15
    ja L_WriteImageCylinderAdvance    ;if head>=15,head=0 cylinder++
    jmp L_WriteImageLoop              ;else do read command
L_WriteImageCylinderAdvance:
    mov byte [CurrentHead],0x00
    inc byte [CurrentCylinder]
    jmp L_WriteImageLoop
L_WriteImageDone:
    pop es                            ;get original es
    ret

L_LoadImageError:                         
    mov dx,0x03f2                     ;shut down floppy disk controller
    mov al,0x00                       ;shut down floppy
    out dx,al                         ;shut down floppy
L_WriteImageError:
    pop es                            ;get original es
    mov ah,0x03                       ;read cursor position
    mov bh,0x00                       ;1st page
    int 0x10                         ;text mode command,return dh=row number,dl=line number
    mov cx,14                         ;string length
    mov bx,0x0007                     ;bh=0x00 back ground color black,bl=7 foreground color white
    mov bp,ErrorMessage               ;load offset of string
    mov ax,0x1301                     ;ah=0x13...write string,al=0x01...write mode
    int 0x010                         ;text mode command
L_LoadImageDeadLoop:                  ;dead loop
    jmp L_LoadImageDeadLoop           ;dead loop
    ret                               ;this line will never execute

PrintLoadingMessage:
    mov ah,0x03                       ;get cursor position command
    mov bh,0x00                       ;page number 
    int 0x10                         ;screen io...dh=row number,dl=line number
    mov cx,19                         ;string length
    mov bx,0x0007                     ;bl=7...color
    mov bp,LoadingMessage             ;load offset of string
    mov ax,0x1301                     ;ah=0x13...write string,al=0x01...write mode
    int 0x010                         ;text mode command
    ret                          

PrintDoneMessage:
    mov ah,0x03                       ;get cursor position command
    mov bh,0x00                       ;page number 
    int 0x10                         ;screen io...dh=row number,dl=line number
    mov cx,45                         ;string length
    mov bx,0x0007                     ;bl=7...color
    mov bp,DoneMessage                ;load offset of string
    mov ax,0x1301                     ;ah=0x13...write string,al=0x00...write mode
    int 0x010                         ;text mode command
    ret                          

MessagePool:
    ErrorMessage:                     ;14 bytes length string
        db 0x0d
        db 0x0a
        db 'Write fault.'
        db 0x00
    LoadingMessage:                   ;19 bytes length string
        db 0x0d
        db 0x0a
        db 'Install OS image.'
        db 0x00
    DoneMessage:                      ;45 bytes length string
        db 0x0d
        db 0x0a
        db 'Write OS image ok.'
        db 0x0d
        db 0x0a
        db 'Remove disk,and reboot.'
        db 0x00

LocalVariables:        
CurrentSector:   db 0x00
CurrentTrack:    db 0x00
CurrentHead:     db 0x00   
CurrentCylinder: db 0x00
TotalSector:     dw TOTAL_CODE_LENGTH

times 510 - ($ - $$) db 0x00
dw 0xaa55
