;编译方法 nasm IntoPM.asm -o IntoPM.com
;采用UTF8编码

%include "pm.inc"

org 0100h

jmp	LABLE_BEGIN

[section .gdt]
LABLE_GDT:		Descriptor	0,		0,			0		;空描述符
LABLE_DESC_CODE32:	Descriptor	0,		SegCode32Len -1,	DA_32 | DA_C	;32位代码段描述符,只执行，非一致代码段
LABLE_DESC_VEDIO:	Descriptor	0B8000h,	0FFFFh,		DA_DRW		;显存的描述符
LABLE_DESC_NORMAL:	Descriptor	0,		0FFFFh,		DA_DRW		;
LABLE_DESC_CODE16:	Descriptor	0,		0FFFFh,		DA_C		;16位代码段描述符,只执行，非一致代码段,     段长为什么为0FFFF？实际长度为什么会崩溃?
LABLE_DESC_STACK:	Descriptor	0,		TopOfStack,		DA_DRW | DA_32;
LABLE_DESC_DATA32:	Descriptor	0,		DataLen - 1,		DA_DRW		;32位数据段
LABLE_DESC_PAGE_DIR:Descriptor	PageDirBase,	4095,			DA_DRW		;页目录表描述符,从2M的地址开始
LABLE_DESC_PAGE_TBL:Descriptor	PageTblBase,	1023,			DA_DRW | DA_LIMIT_4K	;


GdtLen	equ	$ - LABLE_GDT				;GDT长度
GdtPtr	db	GdtLen - 1				;
	dd	0					;

PageDirBase		equ	200000h				;页目录基址
PageTblBase		equ	201000h				;页表基址

SelectorCode32	equ	LABLE_DESC_CODE32 - LABLE_GDT	;32位代码段选择子
SelectorVedio		equ	LABLE_DESC_VEDIO - LABLE_GDT		;显存段选择子
SelectorNormal	equ	LABLE_DESC_NORMAL - LABLE_GDT	;返回时加载的选择子
SelectorCode16	equ	LABLE_DESC_CODE16 - LABLE_GDT	;16位代码段选择子
SelectorStack		equ	LABLE_DESC_STACK - LABLE_GDT		;32位栈选择子
SelectorData32	equ	LABLE_DESC_DATA32 - LABLE_GDT	;32位数据段选择子
SelectorPageDir	equ	LABLE_DESC_PAGE_DIR - LABLE_GDT	;
SelectorPageTbl	equ	LABLE_DESC_PAGE_TBL - LABLE_GDT	;


[section .data32]
align 32
[bits 32]
	LABLE_DATA32_BEGIN:
	SPValueInRealMode	dw	0			;
	;string
	PMMessage:		db	"In Protected Mode Now.^-^",0	;string will be shown in Protected Mode
	OffsetPMMessage	equ	PMMessage - $$
	SetupPagingMsg:	db 	"Setup pageing succsessful!",0
	OffsetPagingMsg:	equ	SetupPagingMsg - $$
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
.2:								;显示保护模式字符串结束
	call DispReturn
	call SetupPaging					;开启分页机制
	
	
	
	;执行完毕
	jmp SelectorCode16:0

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
	
;开启分页机制
SetupPaging:
	;初始化页表目录，
	mov ax, SelectorPageDir
	mov es, ax
	xor edi, edi						;为stosd指令做准备
	mov ecx, 1024						;共1024个页目录项
	mov eax, PageTblBase | PG_P | PG_RWW | PG_USU	;页表基址+属性
	cld
	.loop1:
	stosd
	add eax, 4096
	loop .loop1
	
	;初始化页表
	mov ax, SelectorPageTbl;
	mov es, ax
	xor edi, edi
	mov ecx, 1024*1024
	xor eax, eax
	mov eax, PG_P | PG_RWW | PG_USU
	cld
	.loop2:
	stosd
	add eax, 4096
	loop .loop2
	
	;页目录和页表初始化完毕，然后加载
	mov eax, PageDirBase					;PageDirBase必须4K对齐
	mov cr3, eax
	mov eax,  cr0
	or  eax, 80000000h
	mov cr0, eax
	jmp short .end					;为什么加short
.end:	
	nop
	
	;显示分页成功字符串
	mov ax, SelectorData32
	mov ds, ax
	mov ax, SelectorVedio
	mov gs, ax
	mov esi, OffsetPagingMsg
	mov edi, 80 * 11 * 2
	mov ah, 0Ch
	cld
.3:
	lodsb
	test al, al
	jz .4
	mov [gs:edi], ax
	inc edi
	inc edi
	jmp .3
.4:	
	ret
;end of [section .s32]
SegCode32Len	equ	$ - LABLE_CODE32_BEGIN

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
	and eax, 7FFFFFFEh					;关闭分页并退出保护模式
	;and al, 1110B
	mov cr0, eax
	LABLE_GO_BACK_TO_REAL:
	jmp 0:LABEL_REAL_ENTRY
SegCode16Len	equ	$ - $$