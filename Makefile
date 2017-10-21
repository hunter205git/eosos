# makefile for operating system FORMOSA

ENTRYPOINT=0x00012000

MAKE=c:\MinGW\bin\mingw32-make.exe
CC = c:\MinGW\bin\gcc.exe
ASM = c:\nasm\nasm.exe
LD = c:\MinGW\bin\ld.exe
EXE2BIN = tools\exe2bin.exe
SHELL = cmd.exe

ASMBFLAGS = -o $@ $<
ASMCFLAGS = -I 'mode\' -o $@ $< -l $@.lst
ASMKFLAGS = -I 'include\' -f elf -o $@ $< -l $@.lst
CFLAGS = -I include -c -w -o $@ $<
LDFLAGS = -Ttext $(ENTRYPOINT) -s -o $@ $(OBJS_K)
IMGFLAGS = -f bin -o $@ $<

INSTALL_OBJS = install\install.img
BOOT_OBJS = boot\bootloader.bin boot\bootinstall.bin
MODE_OBJS = mode\changemode.bin
KERNEL_OBJS = kernel\kernel.bin

SYSTEM_OBJS = kernel\kernel.o kernel\cinit.o kernel\cmain.o kernel\protectMode.o \
			kernel\global.o kernel\scheduler.o lib\lib.o lib\clib.o

OBJS_K = $(SYSTEM_OBJS)
OBJS_BM = $(BOOT_OBJS) $(MODE_OBJS)

all: $(OBJS_BM) $(OBJS_K)  $(KERNEL_OBJS) $(INSTALL_OBJS)
	
%.img: %.asm
	$(ASM) $(IMGFLAGS)

boot\bootloader.bin: boot\bootloader.asm
	$(ASM) $(ASMBFLAGS)
	
boot\bootinstall.bin: boot\bootinstall.asm
	$(ASM) $(ASMBFLAGS)
	
mode\changemode.bin: mode\changemode.asm
	$(ASM) $(ASMCFLAGS)

$(KERNEL_OBJS): kernel\kernel.exe
	$(EXE2BIN) $< $@ > $@.log

kernel\kernel.exe: $(OBJS_K)
	$(LD) $(LDFLAGS) 
	
%.o: %.c
	$(CC)  $(CFLAGS)

%.o: %.asm
	$(ASM)  $(ASMKFLAGS) 
	
clean:
	del $(BOOT_OBJS)
	del $(MODE_OBJS)
	del $(KERNEL_OBJS)
	del $(SYSTEM_OBJS)
	del $(INSTALL_OBJS)