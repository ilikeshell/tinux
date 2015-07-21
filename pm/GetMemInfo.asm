;编译方法 nasm IntoPM.asm -o IntoPM.com
;采用UTF8编码

%include "pm.inc"


org 0100h

jmp	LABLE_DEBUG

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
	_PMMessage:		db	"In Protected Mode Now.^-^",0Ah,0Ah,0	;string will be shown in Protected Mode
	_SetupPagingMsg:	db 	"Setup pageing succsessful!",0Ah,0Ah,0
	_szMemChkTitle:	db	"BaseAddrL BaseAddrH LengthLow Lengthhigh   Type",0Ah,0
	_szRamSize		db	"Ram Size:",0
	_szReturn		db	0Ah,0
	;var
	_dwMCRNumber		dd	0
	_dwDispPos		dd	(80 * 6 + 0) * 2
	_dwMemSize		dd	0
	_ARDStruct:
		_dwBaseAddrLow:	dd	0
		_dwBaseAddrHigh:	dd	0
		_dwLengthLow:		dd	0
		_dwLengthHigh:	dd	0
		_dwType:		dd	0
	
	_MemChkBuf	times	256	db	0
	
	;保护模式下使用的符号
	szPMMessage		equ	_PMMessage - $$
	szPagingMsg:		equ	_SetupPagingMsg - $$
	szMemChkTitle		equ	_szMemChkTitle	- $$
	szRAMSize		equ	_szRamSize	- $$
	szReturn		equ	_szReturn	- $$
	dwDispPos		equ	_dwDispPos	- $$
	dwMemSize		equ	_dwMemSize	- $$
	dwMCRNumber		equ	_dwMCRNumber	- $$
	ARDStruct		equ	_ARDStruct	- $$
	   dwBaseAddrLow	equ	_dwBaseAddrLow-$$
	   dwBaseAddrHigh	equ	_dwBaseAddrHigh-$$
	   dwLengthLow	equ	_dwLengthLow	- $$
	   dwLengthHigh	equ	_dwLengthHigh	- $$
	   dwType		equ	_dwType	- $$
	MemChkBuf		equ	_MemChkBuf	- $$
	
	
	
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
LABLE_DEBUG:
	mov  dx, cs
	mov  cx, 800h  ;;800h,自己乱定的，可以改，这个就是调试时用的断点
	mov  ds, cx
	mov  byte [ds:0], 00eah    ;;ea是jmp的机器码，加下面两句就是 jmp offset:seg，也就是跳回
	mov  word [ds:1],LABLE_BEGIN
	mov  word [ds:3], dx
	jmp  800h:0h           ;;跳到断点

LABLE_BEGIN:
	;初始化段寄存器和栈顶指针
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp,0100h
	
	
	
	;通过int15h中断获取内存信息，输入：eax=0E820h, ebx(后序值), es:di(指向一个ARDS),ecx(填充的字节)，edx="SAMP"(0534D4150h)
	;			       输出：CF=0（正确，否则存在错误，终止程序），eax="SAMP"，es:di，ecx，ebx(后序值)
	mov ebx, 0
	mov di, _MemChkBuf
	.loop:
	mov eax, 0E820h
	mov ecx, 20
	mov edx, 0534D4150h
	int 15h
	jc LABEL_GET_MEM_INFO_FAILED
	inc dword [_dwMCRNumber];				;记录内存块数
	add di, 20
	cmp ebx, 0
	jnz .loop
	jmp LABEL_GET_MEM_INFO_OK
LABEL_GET_MEM_INFO_FAILED:
	mov dword [_dwMCRNumber], 0
LABEL_GET_MEM_INFO_OK:


	;保存返回实模式时的段值
	mov ax, CS
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
	mov es, ax
	mov ax, SelectorStack
	mov ss, ax
	mov esp, TopOfStack
	mov ax, SelectorVedio
	mov gs, ax

	;显示保护模式字符串
	mov ah, 0Ch
	push szPMMessage
	call DispStr
	add esp, 4
							;显示保护模式字符串结束
	push szMemChkTitle
	call DispStr
	add esp, 4
	
	;call SetupPaging					;开启分页机制
	
	call DispMemInfo
	
	
	
	;执行完毕
	jmp SelectorCode16:0




	
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
	mov esi, szPagingMsg
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
	
;在保护模式下显示内存信息
DispMemInfo:
	push esi
	push edi
	push ecx
	
	mov esi, MemChkBuf
	mov ecx, [dwMCRNumber]
.loop:
	mov edx, 5
	mov edi, ARDStruct
    .1:
	push dword [esi]
	call DispInt
	pop eax
	stosd
	add esi, 4
	dec edx
	cmp edx, 0
	jnz .1
	call DispReturn
	cmp dword [dwType], 1
	jne .2
	mov eax, [dwBaseAddrLow]
	add eax, [dwLengthLow]
	cmp eax, [dwMemSize]
	jb .2
	mov [dwMemSize], eax
    .2:
	loop .loop
	
	call DispReturn
	push szRAMSize
	call DispStr
	add esp, 4
	
	push dword [dwMemSize]
	call DispInt
	add esp,4
	
	pop ecx
	pop edi
	pop esi
	ret
	
	%include "lib.inc"				;不放在这里会出现“offset outside of CS limits”错误
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
	;and eax, FFFFFFFEh					;关闭分页并退出保护模式
	and al, 1110B
	mov cr0, eax
	LABLE_GO_BACK_TO_REAL:
	
	jmp 0:LABEL_REAL_ENTRY
SegCode16Len	equ	$ - $$



