;%define	_BOOT_DEBUG_	; 做 Boot Sector 时一定将此行注释掉!将此行打开后用 nasm Boot.asm -o Boot.com 做成一个.COM文件易于调试

%ifdef	_BOOT_DEBUG_
	org  0100h			; 调试状态, 做成 .COM 文件, 可调试
%else
	org  07c00h			; Boot 状态, Bios 将把 Boot Sector 加载到 0:7C00 处并开始执行
%endif

;FAT12磁盘头
jmp LABLE_START					;跳转指令，编译成3字节的指令，若jmp short LABLE_START,编译成2字节指令
;nop							;必不可少

%include "fat12hdr.inc"

;宏、常量、变量、以及字符串定义
%ifdef _BOOT_DEBUG_
	BaseOfStack	equ	0100h
%else
	BaseOfStack	equ	07C00h
%endif

BaseOfLoader		equ	09000h			;
OffsetOfLoader	equ	0100h			;


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
	call PrintDot
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

%include "klib.inc"

	times 510 - ($ - $$)	db 0
	dw 0xAA55
