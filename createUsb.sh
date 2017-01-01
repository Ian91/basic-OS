#!/bin/bash

nasm -f bin floppy_boot.asm -o floppy_boot.bin 
gcc -c -m32 -ffreestanding -Wall test.c -o test.o
ld -melf_i386 -Tlink.ld test.o -o test.elf
objcopy -O binary test.elf test.bin

dd if=floppy_boot.bin of=os.flp bs=1024 count=1 &> /dev/null
dd if=test.bin of=os.flp bs=1024 count=1 oflag=append conv=notrunc &> /dev/null

sudo dd if=os.flp of=/dev/sdb bs=4096 count=1
