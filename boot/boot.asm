;%define	_BOOT_DEBUG_	; 做 Boot Sector 时一定将此行注释掉!将此行打开后用 nasm Boot.asm -o Boot.com 做成一个.COM文件易于调试

%ifdef	_BOOT_DEBUG_
	org  0100h			; 调试状态, 做成 .COM 文件, 可调试
%else
	org  07c00h			; Boot 状态, Bios 将把 Boot Sector 加载到 0:7C00 处并开始执行
%endif

;FAT12磁盘头
jmp short LABLE_START					;跳转指令，编译成3字节的指令，若jmp short LABLE_START,编译成2字节指令
nop							;必不可少
BS_OEMName		db	"ForrestY"		;OEM厂商名，共8个字节
BPB_BytesPerSec	dw 	512			;每扇区字节数，共2个字节
BPB_SecPerClus	db	1			;每个簇的扇区数，共1个字节
BPB_RsvdSecCnt	dw	1			;boot记录占用多少扇区，共2个字节
BPB_NumFATs		db	2			;共有多少个FAT表，共1个字节
BPB_RootEntCnt	dw	224			;根目录文件数最大值，共2个字节
BPB_TotSec16		dw	2880			;逻辑扇区总数，共2个字节
BPB_Media		db	0F0h			;介质描述符，共1个字节
BPB_FATSz16		dw	9			;每个FAT表所占用的扇区数，共2个字节
BPB_SecPerTrk		dw	18			;每个磁道扇区数，共2个字节
BPB_NumHeads		dw	2			;磁头数，共2个字节
BPB_HiddSec		dd	0			;隐藏扇区数，共4个字节
BPB_TotSec32		dd	0			;如果BPB_TotSec16为0，则由该值记录扇区数，共4个字节
BS_DrvNum		db	0			;中断13的驱动器号，共1个字节
BS_Reserved1		db	0			;未使用，共1个字节
BS_BootSig		db	29h			;扩展引导标记，共1个字节
BS_VolID		dd	0			;卷序列号，共4个字节
BS_VolLab		db	"Tinux  Boot"		;卷标，必须11个字节
BS_FileSysType	db	"FAT12   "		;文件系统类型，必须8个字节



;宏、常量、变量、以及字符串定义
%ifdef _BOOT_DEBUG_
	BaseOfStack	equ	0100h
%else
	BaseOfStack	equ	07C00h
%endif

BaseOfLoader		equ	09000h			;
OffsetOfLoader	equ	0100h			;
RootDirSectors	equ	14			;224 * 32 / 512 = 14
SectorNoOfRootDir	equ	19			;根目录从19号扇区开始
OffsetFatTblSec	equ	1			;Fat表从1号扇区开始
OffsetDataSec		equ	RootDirSectors + SectorNoOfRootDir - 2

;变量 
wRootDirSizeForLoop	dw	RootDirSectors	;循环数
wSectorNo		dw	0			;要读取的扇区号
bOdd			db	0			;是基数还是偶数？

;字符串
LoaderFileName	db	"LOADER  BIN",0	;
BootMessage		db	"Booting  ",0		;
Message1		db	"Ready.   ",0		;
Message2		db	"NO LOADER",0		;
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
	
	;在软盘的根目录下寻找LOADER.BIN
	mov word [wSectorNo], SectorNoOfRootDir	;从19号扇区开始读
LABLE_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp word [wRootDirSizeForLoop], 0		;根目录最多为14个扇区
	jz LABLE_NO_LOADERBIN
	dec word [wRootDirSizeForLoop]
	
	;es:bx指向数据缓冲区
	mov ax, BaseOfLoader
	mov es, ax
	mov bx, OffsetOfLoader
	;读取一个扇区
	mov ax, [wSectorNo]
	mov cl, 1
	call ReadSector
	
	
	;对读取的扇区进行处理
	mov si, LoaderFileName			;ds:si------> "LOADER  BIN"
	mov di, OffsetOfLoader			;es:di------> BaseOfLoader:0100h
	
	cld
	mov dx, 16					;一个扇区共16个条目
	LABLE_SEARCH_FOR_LOADERBIN:
	cmp dx, 0
	jz LABLE_GOTO_NEXT_SECTOR_IN_ROOT_DIR
	dec dx
	mov cx, 11
	LABLE_CMP_FILENAME:
	cmp cx, 0
	jz LABLE_LOADERBIN_FOUND
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
	mov si, LoaderFileName
	jmp LABLE_SEARCH_FOR_LOADERBIN
	
LABLE_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	inc word [wSectorNo]				;指向下一个扇区
	jmp LABLE_SEARCH_IN_ROOT_DIR_BEGIN

LABLE_NO_LOADERBIN:
	mov dh, 2
	call DispStr
%ifdef	_BOOT_DEBUG_
	mov ax, 4C00h
	int 21h
%else	
	jmp $
%endif
	
LABLE_LOADERBIN_FOUND:
	;清屏
	mov ax, 0600h
	mov bx, 0700h
	mov cx, 0
	mov dx, 0184Fh
	int 10h
	
	mov dh, 0
	call DispStr

	
	and di, 0FFE0h
	add di, 01Ah					;指向第一个簇号
	mov ax, [es:di]				;读入第一个簇号
	push ax					;保存簇号
	add ax, OffsetDataSec			;获取文件第一个扇区的编号
	mov cx, ax
	
	mov ax, BaseOfLoader
	mov es, ax
	mov bx, OffsetOfLoader			;es:bx----->fat表
	
	mov ax, cx
	LABLE_GO_ON_LOADING_FILE:
	;每读取一个扇区，打一个“.”
	push ax 
	push bx	
	mov ah, 0Eh
	mov al, '.'
	mov bl, 0Fh
	int 10h	
	pop bx
	pop ax
	
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
	mov dh, 1
	call DispStr
	jmp BaseOfLoader:OffsetOfLoader

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
	add ax, BootMessage
	mov bp, ax	;--|
	mov ax, ds	;  |--- es:bp 串地址
	mov es, ax	;--|
	
	mov cx, MessageLen;         串长
	
	mov ax, 01301h				;
	mov bx, 0007h					;bh=页号， bl=07（黑底白字）
	mov dl, 0
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
	mov ax, BaseOfLoader
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


	times 510 - ($ - $$)	db 0
	dw 0xAA55
