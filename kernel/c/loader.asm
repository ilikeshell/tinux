org 0100h

BaseOfStack	equ	0100h

BaseOfKernel		equ	08000h	;kernel.bin被加载的段地址
OffsetOfKernel	equ	0h	;kernel.bin被加载的段偏移

jmp LABLE_START
%include "fat12hdr.inc"

;变量 
wRootDirSizeForLoop	dw	RootDirSectors	;循环数
wSectorNo		dw	0			;要读取的扇区号
bOdd			db	0			;是基数还是偶数？

;字符串
KernelFileName	db	"KERNEL  BIN",0	;
KernelMessage		db	"Loading  ",0		;
Message1		db	"Ready.   ",0		;
Message2		db	"NO KERNEL",0		;
MessageLen		equ	10

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
	call DispStr					;显示“Loading  ”
	
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
	call DispStr
%ifdef	_BOOT_DEBUG_
	mov ax, 4C00h
	int 21h
%else	
	jmp $
%endif
	
LABLE_KERNELBIN_FOUND:
	jmp $
	
	
	
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
DispStr:	
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
