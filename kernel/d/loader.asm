org 0100h

BaseOfStack	equ	0100h

BaseOfKernel		equ	08000h	;kernel.bin被加载的段地址
OffsetOfKernel		equ	0h	;kernel.bin被加载的段偏移
BaseOfLoader		equ	09000h	;Loader.bin被加载的段地址
OffsetOfLoader		equ	0100h	;Loader.bin被加载的段偏移

BaseOfLoaderPhyAddr	equ	BaseOfLoader * 10h
BaseOfKernelPhyAddr	equ	BaseOfKernel * 10h

KernelEntryPointPhyAddr equ	30400h

PageDirBase		equ	100000h				;页目录基址
PageTblBase		equ	101000h				;页表基址

jmp LABLE_START
%include "fat12hdr.inc"
%include "pm.inc"

[section .gdt]
LABLE_GDT:		Descriptor	0,		0,		0;
LABLE_DESC_FLAT_C:	Descriptor	0,		0FFFFFh,	DA_32 | DA_C | DA_LIMIT_4K;
LABLE_DESC_FLAT_RW:	Descriptor	0,		0FFFFFh,	DA_DRW | DA_32 | DA_LIMIT_4K;
LABLE_DESC_VIDEO:	Descriptor	0B8000h,	0FFFFh,		DA_DRW | DA_DPL3;

GdtLen	equ $ - LABLE_GDT 
GdtPtr	dw GdtLen - 1
	dd BaseOfLoaderPhyAddr + LABLE_GDT
	
;选择子
SelectorFlatC	equ LABLE_DESC_FLAT_C - LABLE_GDT
SelectorFlatRW equ LABLE_DESC_FLAT_RW - LABLE_GDT
SelectorVideo	equ LABLE_DESC_VIDEO - LABLE_GDT + SA_RPL3

;变量 
wRootDirSizeForLoop	dw	RootDirSectors	;循环数
wSectorNo		dw	0			;要读取的扇区号
bOdd			db	0			;是基数还是偶数？
dwKernelSize		dd	0			;内核大小

;字符串
KernelFileName		db	"KERNEL  BIN",0	;
KernelMessage		db	"Loading  ",0		;
Message1		db	"Ready.   ",0		;
Message2		db	"NO KERNEL",0		;
MessageLen		equ	10

;栈空间
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
	int 13h					; 软驱复位
	
	mov dh, 0
	call DispStrRealMode					;显示“Loading  ”
	
	;在软盘的根目录下寻找KERNEL.BIN
	mov word [wSectorNo], SectorNoOfRootDir	;从19号扇区开始读
LABLE_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp word [wRootDirSizeForLoop], 0		;根目录最多为14个扇区
	jz LABLE_NO_KERNELBIN
	dec word [wRootDirSizeForLoop]
	
	;es:bx指向数据缓冲区
	mov ax, BaseOfKernel
	mov es, ax
	mov bx, OffsetOfKernel
	;读取一个扇区
	mov ax, [wSectorNo]
	mov cl, 1
	call ReadSector
	
	
	;对读取的扇区进行处理
	mov si, KernelFileName			;ds:si------> "KERNEL  BIN"
	mov di, OffsetOfKernel			;es:di------> BaseOfKernel:0
	
	cld
	mov dx, 16					;一个扇区共16个条目
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
	and di, 0FFE0h				;di指向当前条目的开始
	add di, 32					;di指向下一个条目
	mov si, KernelFileName
	jmp LABLE_SEARCH_FOR_KERNELBIN
	
LABLE_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	inc word [wSectorNo]				;指向下一个扇区
	jmp LABLE_SEARCH_IN_ROOT_DIR_BEGIN

LABLE_NO_KERNELBIN:
	mov dh, 2
	call DispStrRealMode
%ifdef	_BOOT_DEBUG_
	mov ax, 4C00h
	int 21h
%else	
	jmp $
%endif
	
LABLE_KERNELBIN_FOUND:
	and di, 0FFE0h				;指向第一个条目
	;保存内核大小
	push eax
	mov eax, [es:(edi+01Ch)]
	mov dword [dwKernelSize], eax
	pop eax

	
	add di, 01Ah					;指向第一个簇号
	mov ax, [es:di]				;读入第一个簇号
	push ax					;保存簇号
	add ax, OffsetDataSec			;获取文件第一个扇区的编号
	mov cx, ax
	
	mov ax, BaseOfKernel
	mov es, ax
	mov bx, OffsetOfKernel			;es:bx----->fat表
	
	mov ax, cx
	LABLE_GO_ON_LOADING_FILE:
	;每读取一个扇区，打一个“.”
	call PrintDot
	;读取一个扇区
	mov cl, 1
	call ReadSector
	pop ax						;获取簇号
	call GetFatEntry
	cmp ax, 0FFFh
	jz LABLE_FILE_LOADED
	push ax 
	add ax, OffsetDataSec			;计算文件的下一个扇区编号
	add bx, [BPB_BytesPerSec]			;bx+512
	jmp LABLE_GO_ON_LOADING_FILE
	
LABLE_FILE_LOADED:
	call KillMotor
	mov dh, 1
	call DispStrRealMode
	
	;实模式下获取系统内存信息
	mov ebx, 0
	mov ax, CS
	mov es, ax
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
	
	
	;加载GDT
	lgdt [GdtPtr]
	
	;打开A20
	in al, 092h
	or al, 010b
	out 092h, al 
	
	
	;准备进入保护模式
	mov eax, cr0
	or eax, 1
	mov cr0, eax
	
	jmp dword SelectorFlatC:(BaseOfLoaderPhyAddr + LABLE_PM_START)
	
	
	
;ReadSector的功能：把从第AX个扇区开始，将CL个扇区读入数据缓冲区
;利用BIOS 13h读取扇区
;说明：ah=00h, dl=DriveNum, int 13h 复位软驱
;     ah=02h, ch=柱面号, dh=磁头号，cl=起始扇区号， dl=驱动器号， al=要读取的扇区数， es:bx数据缓冲区
ReadSector:
	push bp
	mov bp, sp
	sub sp, 2
	mov byte [bp - 2], cl
	
	push bx
	mov bl, byte [BPB_SecPerTrk]
	div bl
	mov cl, ah
	inc cl						;获得起始扇区号
	pop bx
	
	mov dh, al
	and dh, 01b					;获得磁头号
	
	shr al, 1					;
	mov ch, al					;获得柱面号
	
	;所有参数信息已经全部获取
	mov dl, [BS_DrvNum]				;获取驱动器号
	GO_ON_READING:
	mov al, byte [bp - 2]			;获取要读取的扇区个数
	mov ah, 02h
	int 13h
	jc GO_ON_READING
	
	add sp, 2
	pop bp
	ret

;显示一个字符串，dh为要显示的字符串序号
DispStrRealMode:	
	push es
	
	mov ax, MessageLen
	mul dh
	add ax, KernelMessage
	mov bp, ax	;--|
	mov ax, ds	;  |--- es:bp 串地址
	mov es, ax	;--|
	
	mov cx, MessageLen;         串长
	
	mov ax, 01301h				;
	mov bx, 0007h					;bh=页号， bl=07（黑底白字）
	mov dl, 0
	add dh, 3
	int 10h
	
	pop es
	ret
	

;输入：文件在数据区的扇区编号（从2开始）；返回：文件在数据区的下一个扇区编号
GetFatEntry:
	push es
	push bx
	push dx

	;开辟一段内存空间用于保存Fat表
	push ax
	mov ax, BaseOfKernel
	sub ax, 0100h
	mov es, ax
	pop ax
	
	;获取ax代表的扇区编号在Fat表中的字节偏移量
	mov byte [bOdd], 0				;初始化奇偶标志
	xor dx, dx
	mov bx, 3
	mul bx
	mov bx, 2
	div bx
	
	;判断是奇数还是偶数
	cmp dx, 0
	jz .LABLE_EVEN
	mov byte [bOdd], 1				;保存奇偶标志
	.LABLE_EVEN:
	xor dx, dx					;字除法DX需清零
	mov bx, [BPB_BytesPerSec]
	div bx 					;ax存放FAT项所在的扇区偏移
	add ax, OffsetFatTblSec			;ax存放FAT项所在的扇区序号
	push dx					;保存余数，即在扇区内的偏移量
	mov cl, 2
	mov bx, 0					;es:bx指向fat表
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
	
	
;打点
PrintDot:
	;每读取一个扇区，打一个“.”
	push ax 
	push bx	
	mov ah, 0Eh
	mov al, '.'
	mov bl, 0Fh
	int 10h	
	pop bx
	pop ax
	
	ret
	
;关闭软驱马达
KillMotor:
	push  dx
	mov dx, 03F2h
	mov al, 0
	out dx, al
	pop dx
	ret
	
[section .s32]
ALIGN 32
[bits 32]
LABLE_PM_START:
	mov ax, SelectorVideo
	mov gs, ax
	mov ax, SelectorFlatRW
	mov ds, ax 
	mov es, ax
	mov fs, ax
	mov ss, ax 
	mov esp, TopOfStack
	
	mov ah, 0Fh
	mov al, 'P'
	mov [gs:((80 * 0 + 39) * 2)], ax 
	
	;jmp $
	
	push szMemChkTitle
	call DispStr
	add esp, 4
	
	
	
	call DispMemInfo
	call SetupPaging					;开启分页机制
	
	call InitKernel
	
	jmp SelectorFlatC:KernelEntryPointPhyAddr
	
	%include "lib.inc"
	
[section .data32]
align 32
[bits 32]
	LABLE_DATA32_BEGIN:
	;string
	_SetupPagingMsg:	db 	"Setup pageing succsessful!",0Ah,0Ah,0
	_szMemChkTitle:	db	"BaseAddrL BaseAddrH LengthLow Lengthhigh   Type",0Ah,0
	_szRamSize		db	"Ram Size:",0
	_szReturn		db	0Ah,0
	;var
	_dwDispPos		dd	(80 * 6 + 0) * 2
	_dwMCRNumber		dd	0
	_dwMemSize		dd	0
	_ARDStruct:
		_dwBaseAddrLow:	dd	0
		_dwBaseAddrHigh:	dd	0
		_dwLengthLow:		dd	0
		_dwLengthHigh:	dd	0
		_dwType:		dd	0
	
	_MemChkBuf	times	256	db	0
	
	;保护模式下使用的符号
	szPagingMsg:		equ	BaseOfLoaderPhyAddr + _SetupPagingMsg
	szMemChkTitle		equ	BaseOfLoaderPhyAddr + _szMemChkTitle
	szRAMSize		equ	BaseOfLoaderPhyAddr + _szRamSize
	szReturn		equ	BaseOfLoaderPhyAddr + _szReturn
	dwDispPos		equ	BaseOfLoaderPhyAddr + _dwDispPos
	dwMemSize		equ	BaseOfLoaderPhyAddr + _dwMemSize
	dwMCRNumber		equ	BaseOfLoaderPhyAddr + _dwMCRNumber
	ARDStruct		equ	BaseOfLoaderPhyAddr + _ARDStruct
	   dwBaseAddrLow	equ	BaseOfLoaderPhyAddr + _dwBaseAddrLow
	   dwBaseAddrHigh	equ	BaseOfLoaderPhyAddr + _dwBaseAddrHigh
	   dwLengthLow		equ	BaseOfLoaderPhyAddr + _dwLengthLow
	   dwLengthHigh	equ	BaseOfLoaderPhyAddr + _dwLengthHigh	
	   dwType		equ	BaseOfLoaderPhyAddr + _dwType
	MemChkBuf		equ	BaseOfLoaderPhyAddr + _MemChkBuf
	
	DataLen		equ	$ - $$				; $ - $$ = $ - LABEL_DATA ? m
; end of [section .data32]


;实模式下调用
;通过int15h中断获取内存信息，输入：eax=0E820h, ebx(后序值), es:di(指向一个ARDS),ecx(填充的字节)，edx="SAMP"(0534D4150h)
	;			       输出：CF=0（正确，否则存在错误，终止程序），eax="SAMP"，es:di，ecx，ebx(后序值)

GetSysMem:
	
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
	
	
;开启分页机制
SetupPaging:
	;计算需要多少个页表目录
	xor edx, edx
	mov eax, [dwMemSize]
	mov ebx, 400000h						;一个页表可以映射4M的内存
	div ebx
	test edx, edx
	jz LABLE_NO_REMAINDER
	inc eax
	LABLE_NO_REMAINDER:
	mov ecx, eax
	push ecx
	
	;初始化页目录
	mov ax, SelectorFlatRW
	mov es, ax
	mov edi, PageDirBase
	xor eax, eax
	add eax, PageTblBase | PG_P | PG_USU | PG_RWW
	.1:
	stosd
	add eax, 4096
	loop .1
	
	;初始化页表
	pop eax
	mov ebx, 1024
	mul ebx
	mov ecx, eax
	
	mov edi, PageTblBase
	xor eax, eax
	add eax, PG_P | PG_USU | PG_RWW
	.2:
	stosd
	add eax, 4096
	loop .2

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
	;call DispReturn
	;call DispReturn
	;push szPagingMsg
	;call DispStr
	;add esp, 4
	ret
	
;初始化内核
InitKernel:
	;获取循环的次数
	mov cx, [BaseOfKernelPhyAddr + 02Ch]
	and ecx, 0FFFFh
	
	;ESI指向第一个程序头表项
	mov esi, [BaseOfKernelPhyAddr + 01Ch]
	add esi, BaseOfKernelPhyAddr				;不要忘记
	Begin:
	mov eax, [esi + 0]
	cmp eax, 0
	jz NoAction
	mov eax, [esi + 10h]
	push eax
	mov eax, [esi + 04h]
	add eax, BaseOfKernelPhyAddr
	push eax
	mov eax, [esi + 8]
	push eax
	call MemCpy
	add esp, 12						;由调用者清栈
	NoAction:
	add esi, 20h
	dec ecx
	jnz Begin
	ret