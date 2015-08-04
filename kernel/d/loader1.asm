%line 1+1 loader.asm
[org 0100h]

BaseOfStack equ 0100h

BaseOfKernel equ 08000h
OffsetOfKernel equ 0h
BaseOfLoader equ 09000h
OffsetOfLoader equ 0100h

BaseOfLoaderPhyAddr equ BaseOfLoader * 10h

jmp LABLE_START
%line 1+1 fat12hdr.inc



BS_OEMName db "ForrestY"
BPB_BytesPerSec dw 512
BPB_SecPerClus db 1
BPB_RsvdSecCnt dw 1
BPB_NumFATs db 2
BPB_RootEntCnt dw 224
BPB_TotSec16 dw 2880
BPB_Media db 0F0h
BPB_FATSz16 dw 9
BPB_SecPerTrk dw 18
BPB_NumHeads dw 2
BPB_HiddSec dd 0
BPB_TotSec32 dd 0
BS_DrvNum db 0
BS_Reserved1 db 0
BS_BootSig db 29h
BS_VolID dd 0
BS_VolLab db "Tinux  Boot"
BS_FileSysType db "FAT12   "



FATSz equ 9
RootDirSectors equ 14
SectorNoOfRootDir equ 19
OffsetFatTblSec equ 1
OffsetDataSec equ RootDirSectors + SectorNoOfRootDir - 2

%line 1+1 pm.inc










%line 17+1 pm.inc













%line 37+1 pm.inc
































































DA_32 equ 04000h
DA_LIMIT_4K equ 08000h

DA_DPL0 equ 00h
DA_DPL1 equ 20h
DA_DPL2 equ 40h
DA_DPL3 equ 60h


DA_DR equ 90h
DA_DRW equ 92h
DA_DRWA equ 93h
DA_C equ 98h
DA_CR equ 9Ah
DA_CCO equ 9Ch
DA_CCOR equ 9Eh


DA_LDT equ 82h
DA_TaskGate equ 85h
DA_386TSS equ 89h
DA_386CGate equ 8Ch
DA_386IGate equ 8Eh
DA_386TGate equ 8Fh




SA_RPL0 equ 00h
SA_RPL1 equ 01h
SA_RPL2 equ 02h
SA_RPL3 equ 03h

SA_TIG equ 00h
SA_TIL equ 04h













%line 153+1 pm.inc















%line 175+1 pm.inc






PG_P equ 01h
PG_RWR equ 00h
PG_RWW equ 02h
PG_USU equ 04h
PG_USS equ 00h
%line 15+1 loader.asm

[section .gdt]
LABLE_GDT: Discriptor 0, 0, 0
LABLE_DESC_FLAT_C: Discriptor 0, 0FFFFFh, DA_32 | DA_C | DA_LIMIT_4K
LABLE_DESC_FLAT_RW: Discriptor 0, 0FFFFFh, DA_DRW | DA_32 | DA_LIMIT_4K
LABLE_DESC_VIDEO: 
%line 20+0 loader.asm
 dw 0FFFFh & 0FFFFh
 dw 0B8000h & 0FFFFh
 db (0B8000h >> 16) & 0FFh
 dw (DA_DRW | DA_DPL3 & 0F0FFh) | ((0FFFFh >> 8) & 0F00h)
 db (0B8000h >> 24) & 0FFh
%line 21+1 loader.asm

GdtLen equ $ - LABLE_GDT
GdtPtr dw GdtLen - 1
 dd BaseOfLoaderPhyAddr + LABLE_GDT


SelectorFlatC equ LABLE_DESC_FLAT_C - LABLE_GDT
SelectorFlatRW equ LABLE_DESC_FLAT_RW - LABLE_GDT
SelectorVideo equ LABLE_DESC_VIDEO - LABLE_GDT + SA_RPL3


wRootDirSizeForLoop dw RootDirSectors
wSectorNo dw 0
bOdd db 0
dwKernelSize dd 0


KernelFileName db "KERNEL  BIN",0
KernelMessage db "Loading  ",0
Message1 db "Ready.   ",0
Message2 db "NO KERNEL",0
MessageLen equ 10


times 1024 db 0
TopOfStack equ BaseOfLoaderPhyAddr + $


LABLE_START:
 mov ax, cs
 mov ds, ax
 mov es, ax
 mov ss, ax
 mov sp, BaseOfStack

 xor ax, ax
 xor dx, dx
 int 13h

 mov dh, 0
 call DispStr


 mov word [wSectorNo], SectorNoOfRootDir
LABLE_SEARCH_IN_ROOT_DIR_BEGIN:
 cmp word [wRootDirSizeForLoop], 0
 jz LABLE_NO_KERNELBIN
 dec word [wRootDirSizeForLoop]


 mov ax, BaseOfKernel
 mov es, ax
 mov bx, OffsetOfKernel

 mov ax, [wSectorNo]
 mov cl, 1
 call ReadSector



 mov si, KernelFileName
 mov di, OffsetOfKernel

 cld
 mov dx, 16
 LABLE_SEARCH_FOR_KERNELBIN:
 cmp dx, 0
 jz LABLE_GOTO_NEXT_SECTOR_IN_ROOT_DIR
 dec dx
 mov cx, 11
 LABLE_CMP_FILENAME:
 cmp cx, 0
 jz LABLE_KERNELBIN_FOUND
 dec cx
 lodsb
 mov ah, byte [es:di]
 cmp al, ah
 jz LABLE_GO_ON
 jmp LABLE_FILE_NAME_DIFF


LABLE_GO_ON:
 inc di
 jmp LABLE_CMP_FILENAME
LABLE_FILE_NAME_DIFF:
 and di, 0FFE0h
 add di, 32
 mov si, KernelFileName
 jmp LABLE_SEARCH_FOR_KERNELBIN

LABLE_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
 inc word [wSectorNo]
 jmp LABLE_SEARCH_IN_ROOT_DIR_BEGIN

LABLE_NO_KERNELBIN:
 mov dh, 2
 call DispStr
%line 122+1 loader.asm
 jmp $


LABLE_KERNELBIN_FOUND:
 and di, 0FFE0h

 push eax
 mov eax, [es:(edi+01Ch)]
 mov dword [dwKernelSize], eax
 pop eax


 add di, 01Ah
 mov ax, [es:di]
 push ax
 add ax, OffsetDataSec
 mov cx, ax

 mov ax, BaseOfKernel
 mov es, ax
 mov bx, OffsetOfKernel

 mov ax, cx
 LABLE_GO_ON_LOADING_FILE:

 call PrintDot

 mov cl, 1
 call ReadSector
 pop ax
 call GetFatEntry
 cmp ax, 0FFFh
 jz LABLE_FILE_LOADED
 push ax
 add ax, OffsetDataSec
 add bx, [BPB_BytesPerSec]
 jmp LABLE_GO_ON_LOADING_FILE

LABLE_FILE_LOADED:
 call KillMotor
 mov dh, 1
 call DispStr



 lgdt [GdtPtr]


 in al, 092h
 or al, 010b
 out 092h, al


 mov eax, cr0
 or eax, 1
 mov cr0, eax

 jmp dword SelectorFlatC:(BaseOfLoaderPhyAddr + LABLE_PM_START)







ReadSector:
 push bp
 mov bp, sp
 sub sp, 2
 mov byte [bp - 2], cl

 push bx
 mov bl, byte [BPB_SecPerTrk]
 div bl
 mov cl, ah
 inc cl
 pop bx

 mov dh, al
 and dh, 01b

 shr al, 1
 mov ch, al


 mov dl, [BS_DrvNum]
 GO_ON_READING:
 mov al, byte [bp - 2]
 mov ah, 02h
 int 13h
 jc GO_ON_READING

 add sp, 2
 pop bp
 ret


DispStr:
 push es

 mov ax, MessageLen
 mul dh
 add ax, KernelMessage
 mov bp, ax
 mov ax, ds
 mov es, ax

 mov cx, MessageLen

 mov ax, 01301h
 mov bx, 0007h
 mov dl, 0
 add dh, 3
 int 10h

 pop es
 ret



GetFatEntry:
 push es
 push bx
 push dx


 push ax
 mov ax, BaseOfKernel
 sub ax, 0100h
 mov es, ax
 pop ax


 mov byte [bOdd], 0
 xor dx, dx
 mov bx, 3
 mul bx
 mov bx, 2
 div bx


 cmp dx, 0
 jz .LABLE_EVEN
 mov byte [bOdd], 1
 .LABLE_EVEN:
 xor dx, dx
 mov bx, [BPB_BytesPerSec]
 div bx
 add ax, OffsetFatTblSec
 push dx
 mov cl, 2
 mov bx, 0
 call ReadSector
 pop dx
 add bx, dx
 mov ax, [es:bx]
 cmp byte [bOdd], 0
 jz .LABLE_EVEN1
 shr ax, 4
 .LABLE_EVEN1:
 and ax, 0FFFh

 pop dx
 pop bx
 pop es

 ret



PrintDot:

 push ax
 push bx
 mov ah, 0Eh
 mov al, '.'
 mov bl, 0Fh
 int 10h
 pop bx
 pop ax

 ret


KillMotor:
 push dx
 mov dx, 03F2h
 mov al, 0
 out dx, al
 pop dx
 ret

[section .s32]
[sectalign 32]
%line 315+0 loader.asm
times (((32) - (($-$$) % (32))) % (32)) nop
%line 316+1 loader.asm
[bits 32]
LABLE_PM_START:
 mov ax, SelectorVideo
 mov gs, ax
 mov ax, SelectorFlatC
 mov cs, ax
 mov ax, SelectorFlatRW
 mov ds, ax
 mov es, ax
 mov fs, ax
 mov ss, ax
 mov esp, TopOfStack

 mov ah, 0Fh
 mov al, 'P'
 mov [gs:((80 * 0 + 39) * 2)]
 jmp $

