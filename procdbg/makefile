#Kernel Entry Point and offset
ENTRYPOINT = 0x30400
ENTRYOFFSET = 0x400

#program, flags, etc
ASM		=	nasm
DASM	=	ndisasm
CC		=	clang
LD		=	ld
ASMBFLAGS	=	-I boot/include/
ASMKFLAGS	=	-I include/ -f elf -F stabs
CLANGFLAGS	=	-Iinclude -c -fno-builtin -target i686-pc-linux-gnu -g

#CLANGFLAGS	=	-Iinclude -c -fno-builtin -target elf32-i386 -g 
#CLANGFLAGS	=	-I include -c -fno-builtin
#LDFLAGS		=	-Ttext $(ENTRYPOINT)
#LDFLAGS		=	-Ttext $(ENTRYPOINT) --oformat  elf32-i386 -m elf_i386
#LDFLAGS		=	-flavor gnu -target i686-pc-linux-gnu

#CLANGFLAGS	=	-I include -c -fno-builtin

LDFLAGS		=	-Ttext $(ENTRYPOINT) -m elf_i386

DASMFLAGS	=	-u -o $(ENTRYPOINT) -e $(ENTRYOFFSET)

#this program
KERNEL		=	kernel.bin 
OBJS		=	kernel/kernel.o kernel/global.o kernel/start.o  kernel/main.o lib/klib.o lib/string.o \
		kernel/8259A.o kernel/protect.o kernel/clock.o lib/klibc.o kernel/syscall.o kernel/proc.o
DASMOUTPUT	=	kernel.bin.asm

#all phony targets
.PHONY:everything final image clean realclean disasm all buildimg

#Default starting position
everything:$(KERNEL)
all:realclean everything
final:all clean

macimg:final BuildMacImg
winimg:final BuildWinImg

image:final buildimg

clean:
	rm -f $(OBJS)
realclean:
	rm -f $(OBJS) $(KERNEL)
disasm:
	$(DASM) $(DASMFLAGS) $(KERNEL) > $(DASMOUTPUT)
	
#buildimg:
#	sudo mount -t msdos /dev/disk2 /Volumes/floppy/
#	sudo cp -fv kernel.bin /Volumes/floppy/
#	sudo umount /Volumes/floppy/

BuildMacImg:
	hdiutil mount ~/osdev/fdos/b.img
	cp -fv kernel.bin "/Volumes/Tinux  Boot"
	hdiutil unmount "/Volumes/Tinux  Boot"

BuildWinImg:
	imdisk -a -m A: -o rem -f e:/os/fdos/A.img
	cp -fv kernel.bin A:
	imdisk -d -m A:

buildimg:
	hdiutil mount ~/osdev/fdos/b.img
	cp -fv kernel.bin "/Volumes/Tinux  Boot"
	hdiutil unmount "/Volumes/Tinux  Boot"


$(KERNEL):$(OBJS)
	$(LD) $(LDFLAGS) -o $(KERNEL) $(OBJS)
	
kernel/kernel.o:kernel/kernel.asm include/sconst.inc
	$(ASM) $(ASMKFLAGS) -o $@ $<
kernel/start.o: kernel/start.c include/tinux.h include/type.h include/const.h \
  include/protect.h include/string.h include/proto.h
	$(CC) $(CLANGFLAGS) -o $@ $<
kernel/8259A.o: kernel/8259A.c include/tinux.h include/type.h include/const.h include/protect.h
	$(CC) $(CLANGFLAGS) -o $@ $<
kernel/protect.o: kernel/protect.c include/tinux.h include/type.h include/const.h include/proto.h include/global.h include/protect.h \
  include/string.h include/proc.h
	$(CC) $(CLANGFLAGS) -o $@ $<
kernel/global.o:kernel/global.c include/type.h include/const.h include/protect.h include/global.h include/tinux.h include/proto.h
	$(CC) $(CLANGFLAGS) -o $@ $<
kernel/main.o: kernel/main.c include/tinux.h include/type.h include/const.h include/proto.h include/global.h include/protect.h \
  include/string.h include/proc.h
	$(CC) $(CLANGFLAGS) -o $@ $<
kernel/clock.o: kernel/clock.c include/tinux.h include/type.h include/const.h include/proto.h include/global.h include/protect.h \
  include/string.h include/proc.h
	$(CC) $(CLANGFLAGS) -o $@ $<
kernel/proc.o: kernel/proc.c include/tinux.h include/type.h include/const.h include/proto.h include/global.h include/protect.h \
  include/string.h include/proc.h
	$(CC) $(CLANGFLAGS) -o $@ $<
kernel/syscall.o:kernel/syscall.asm include/sconst.inc
	$(ASM) $(ASMKFLAGS) -o $@ $<
lib/string.o:lib/string.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<
lib/klib.o:lib/klib.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<
lib/klibc.o: lib/klibc.c include/tinux.h include/type.h include/const.h include/proto.h include/global.h
	$(CC) $(CLANGFLAGS) -o $@ $<
