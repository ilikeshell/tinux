;编译方法 nasm IntoPM.asm -o IntoPM.com

%include "pm.inc"

org 0100h

jmp	LABLE_BEGIN

[section .gdt]
LABLE_GDT:		Descriptor	0,		0,			0		;空描述符
LABLE_DESC_CODE32:	Descriptor	0,		SegCode32Len -1,	DA_32 | DA_C	;32位代码段描述符,只执行，非一致代码段
LABLE_DESC_VEDIO:	Descriptor	0B8000h,	0FFFFh,			DA_DRW		;显存的描述符
LABLE_DESC_NORMAL:	Descriptor	0,		0FFFFh,			DA_DRW		;
LABLE_DESC_CODE16:	Descriptor	0,		0FFFFh,			DA_C		;16位代码段描述符,只执行，非一致代码段,     段长为什么为0FFFF？实际长度为什么会崩溃?
LABLE_DESC_STACK:	Descriptor	0,		TopOfStack,		DA_DRW | DA_32	;
LABLE_DESC_DATA32:	Descriptor	0,		DataLen - 1,		DA_DRW		;32位数据段
LABLE_DESC_TEST:	Descriptor	0500000h,	0FFFFh,			DA_DRW		;用于测试的超过5M的内存段
LABLE_DESC_LDT:		Descriptor	0,		LdtLen,			DA_LDT		;LDT的全局描述符

GdtLen	equ	$ - LABLE_GDT				;GDT长度
GdtPtr	db	GdtLen - 1				;
	dd	0					;
;GDT选择子
SelectorCode32	equ	LABLE_DESC_CODE32 - LABLE_GDT	;32位代码段选择子
SelectorVedio	equ	LABLE_DESC_VEDIO - LABLE_GDT	;显存段选择子
SelectorNormal	equ	LABLE_DESC_NORMAL - LABLE_GDT	;
SelectorCode16	equ	LABLE_DESC_CODE16 - LABLE_GDT	;16位代码段选择子
SelectorStack	equ	LABLE_DESC_STACK - LABLE_GDT	;32位栈选择子
SelectorData32	equ	LABLE_DESC_DATA32 - LABLE_GDT	;32位数据段选择子
SelectorTest:	equ	LABLE_DESC_TEST - LABLE_GDT	;测试段选择子
SelectorLdt:	equ	LABLE_DESC_LDT - LABLE_GDT	;LDT在GDT中的选择子

[section .ldt]
ALIGN 32
LABLE_LDT:
LABLE_LDT_DESC_CODEA:	Descriptor	0,		SegLdtCodeLen,		DA_C | DA_32
LdtLen	equ	$ - LABLE_LDT;
;LDT选择子
;SelectorLdtCode	equ	LABLE_LDT_DESC_CODEA - LABLE_LDT + SA_TIL;
SelectorLdtCode	equ	0 + SA_TIL;

[section .data32]
align 32
[bits 32]
	LABLE_DATA32_BEGIN:
	SPValueInRealMode	dw	0			;
	;string
	PMMessage:	db	"In Protected Mode Now.^-^",0	;string will be shown in Protected Mode
	OffsetPMMessage	equ	PMMessage - $$
	StrTest:	db	"ABCDEFGHIJKLMNOPQRSTUVWXYZ",0
	OffsetStrTest	equ	StrTest - $$
	DataLen		equ	$ - $$				; $ - $$ = $ - LABEL_DATA ? m
; end of [section .data32]

[section .gs]
align 32
[bits 32]
LABLE_STACK_BEGIN:
	times 1024 db 0						;
	TopOfStack equ $ - LABLE_STACK_BEGIN - 1;			;

[section .s16]
[bits 16]
LABLE_BEGIN:
	;初始化段寄存器和栈顶指针
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp,0100h

	;保存返回实模式时的段值
	mov [LABLE_GO_BACK_TO_REAL + 3], ax

	;保存实模式下的栈顶指针
	mov [SPValueInRealMode], sp


	;初始化32位代码段描述符
	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABLE_CODE32_BEGIN
	mov [LABLE_DESC_CODE32 + 2], ax
	shr eax, 16
	mov [LABLE_DESC_CODE32 + 4], al
	mov [LABLE_DESC_CODE32 + 7], ah

	;初始化16位代码段描述符
	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABLE_CODE16_BEGIN
	mov [LABLE_DESC_CODE16 + 2], ax
	shr eax, 16
	mov [LABLE_DESC_CODE16 + 4], al
	mov [LABLE_DESC_CODE16 + 7], ah

	;初始化32位stack段描述符
	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABLE_STACK_BEGIN
	mov [LABLE_DESC_STACK + 2], ax
	shr eax, 16
	mov [LABLE_DESC_STACK + 4], al
	mov [LABLE_DESC_STACK + 7], ah

	;初始化32位数据段描述符
	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABLE_DATA32_BEGIN
	mov [LABLE_DESC_DATA32 + 2], ax
	shr eax, 16
	mov [LABLE_DESC_DATA32 + 4], al
	mov [LABLE_DESC_DATA32 + 7], ah

	;初始化LDT在GDT中的描述符
	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABLE_LDT
	mov [LABLE_DESC_LDT + 2], ax
	shr eax, 16
	mov [LABLE_DESC_LDT + 4], al
	mov [LABLE_DESC_LDT + 7], ah

	;初始化CodeA在LDT中的描述符
	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABLE_CODE32_LDT_BEGIN
	mov [LABLE_LDT_DESC_CODEA + 2], ax
	shr eax, 16
	mov [LABLE_LDT_DESC_CODEA + 4], al
	mov [LABLE_LDT_DESC_CODEA + 7], ah

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

LABEL_REAL_ENTRY:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, [SPValueInRealMode]

	in al, 92h
	and al, 11111101b
	out 92h, al

	sti

	mov ax, 4c00h
	int 21h


	;end of [section .s16]


[section .s32]
[bits 32]
LABLE_CODE32_BEGIN:
	mov ax, SelectorData32
	mov ds, ax
	mov ax, SelectorStack
	mov ss, ax
	mov esp, TopOfStack
	mov ax, SelectorTest
	mov es, ax
	mov ax, SelectorVedio
	mov gs, ax

	;显示保护模式字符串
	mov esi, OffsetPMMessage
	mov edi, 80 * 10 * 2
	mov ah, 0Ch
.1:
	cld
	lodsb
	test al, al
	jz .2
	mov [gs:edi], ax
	inc edi
	inc edi
	jmp .1
.2:							;显示保护模式字符串结束

	;读写测试大内存段
	;call DispReturn
	;call TestRead
	;call TestWrite
	;call TestRead

	;执行完毕
	;jmp SelectorCode16:0
	call DispReturn
	mov ax, SelectorLdt
	lldt ax

	jmp SelectorLdtCode:0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	    读一个8位的字符串
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TestRead:
	push eax
	push ecx

	mov ecx, 8
	mov esi, 0
.loop:	mov al, [es:esi]
	call DispAL
	inc esi
	loop .loop
	call DispReturn

	pop ecx
	pop eax
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	    写一个8位的字符串
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TestWrite:
	push eax
	push ecx
	push edi
	
	xor esi, esi
	xor edi, edi
	mov esi, OffsetStrTest
	cld
.1:	lodsb	
	test al, al
	jz .2
	mov [es:edi], al
	inc edi
	jmp .1
.2:		
	pop edi
	pop ecx
	pop eax
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;显示AL中的数字
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DispAL:
	push ecx
	push edx
	
	mov ah, 0Ch								;
	mov dl, al
	shr al, 4
	mov ecx, 2
.begin	and al, 0Fh
	cmp al, 9
	ja .1
	add al, '0'
	jmp .2
.1:	
	sub al, 0Ah
	add al, 'A'
.2:	
	mov [gs:edi], ax
	add edi, 2
	mov al, dl
	loop .begin
	add edi, 2								;留空格

	pop edx
	pop ecx
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;显示一个换行
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DispReturn:
	push eax
	push ebx
	mov eax, edi
	mov bl, 160
	div bl
	and eax, 0FFh
	inc eax
	mov bl, 160
	mul bl
	mov edi, eax
	pop ebx
	pop eax
	ret
SegCode32Len	equ	$ - LABLE_CODE32_BEGIN
;end of [section .s32]

[section .s16]
align 32
[bits 16]
LABLE_CODE16_BEGIN:
	mov ax, SelectorNormal
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov gs, ax
	mov fs, ax
	
	mov eax, cr0
	;and eax, 0FFFEh
	and al, 01110B
	mov cr0, eax
	LABLE_GO_BACK_TO_REAL:
	jmp 0:LABEL_REAL_ENTRY
SegCode16Len	equ	$ - $$

[section .ldtcode]
align 32
[bits 32]
LABLE_CODE32_LDT_BEGIN:
	mov ax, SelectorVedio
	mov gs, ax
	mov edi, (80 * 11 + 0) * 2
	mov ah, 0Ch
	mov al, 'L'
	mov [gs:edi], ax
	;call DispReturn	
	jmp SelectorCode16:0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;显示一个换行
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DispReturn1:
	push eax
	push ebx
	mov eax, edi
	mov bl, 160
	div bl
	and eax, 0FFh
	inc eax
	mov bl, 160
	mul bl
	mov edi, eax
	pop ebx
	pop eax
	ret

SegLdtCodeLen equ $ - LABLE_CODE32_LDT_BEGIN - 1


