;编译方法 nasm IntoPM.asm -o IntoPM.com

%include "pm.inc"

org 0100h

jmp	LABLE_BEGIN

[section .gdt]
LABLE_GDT:		Descriptor	0,		0,			0		;
LABLE_DESC_CODE32:	Descriptor	0,		SegCode32Len -1,	DA_32 | DA_C	;
LABLE_DESC_VEDIO:	Descriptor	0B8000h,	0FFFFh,			DA_DRW		;

GdtLen	equ	$ - LABLE_GDT				;
GdtPtr	db	GdtLen - 1				;
	dd	0					;

SelectorCode32	equ	LABLE_DESC_CODE32 - LABLE_GDT	;
SelectorVedio	equ	LABLE_DESC_VEDIO - LABLE_GDT	;

[section .s16]
[bits 16]
LABLE_BEGIN:
;初始化段寄存器和栈顶指针
mov ax, cs
mov ds, ax
mov es, ax
mov ss, ax
mov sp,0100h

;初始化GDT
xor eax, eax
mov ax, ds
shl eax, 4
add eax, LABLE_CODE32_BEGIN
mov [LABLE_DESC_CODE32 + 2], ax
shr eax, 16
mov [LABLE_DESC_CODE32 + 4], al
mov [LABLE_DESC_CODE32 + 7], ah

;加载GDT
xor eax, eax
mov ax, cs
shl eax, 4
add eax, LABLE_GDT
mov dword [GdtPtr + 2], eax				;16位和32位混合编码，不加dword会被截取
lgdt [GdtPtr]

;关中断
cli

;打开A20地址线
in al, 92h
or al, 00000010b
out 92h, al

;切换到保护模式
mov eax, cr0
or eax, 1
mov cr0, eax
jmp dword SelectorCode32:0
;end of [section .s16]


[section .s32]
[bits 32]
LABLE_CODE32_BEGIN:
mov ax, SelectorVedio
mov gs, ax
mov edi, (80 * 11 + 40) * 2
mov ah, 0Ch
mov al, 'P'
mov [gs:edi], ax
jmp $

;end of [section .s32]
SegCode32Len	equ	$ - LABLE_CODE32_BEGIN
