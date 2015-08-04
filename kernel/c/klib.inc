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
