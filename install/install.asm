

INCBIN "boot\bootloader.bin"  ;at 0x0000~0x0200,1 sector
times (2*512-($-$$)) db 00h                      ;at 0x0200~0x0400
INCBIN "mode\changemode.bin"            ;at 0x0400~0x0800,1k,2 sectors
INCBIN "kernel\kernel.bin"                ;at 0x0800~
times (2880*512-($-$$)) db 00h