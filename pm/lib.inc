;lib.inc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;显示一个整数
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DispInt:
	push ebx
	
	mov ebx, [esp + 8]	;EBX保存值,先前这里犯了大错误，写成了mov ebx, [esp + 4]
	
	mov eax, ebx
	shr eax, 24
	call DispAL
	
	mov eax, ebx
	shr eax, 16
	call DispAL
	
	mov eax, ebx
	shr eax, 8
	call DispAL
	
	mov eax, ebx
	call DispAL
	
	mov ah, 07h
	mov al, 'h'
	push edi
	mov edi, [dwDispPos]
	mov [gs:edi], ax
	add edi, 4
	mov [dwDispPos], edi
	pop edi
	
	pop ebx
	ret
;DispInt结束

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;显示一个字符串
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DispStr:
	push ebp
	mov ebp, esp
	push ebx
	push esi
	push edi
	
	mov ah, 0Fh
	mov esi, [ebp + 8]			;要显示的字符串首地址
	mov edi, [dwDispPos]		;
.1:	lodsb
	test al, al				;al = 0 or not?
	jz .2
	cmp al, 0Ah
	jnz .3
	push eax
	mov eax, edi
	mov bl, 160
	div bl
	;and eax, 0FFh
	inc eax
	mov bl, 160
	mul bl
	mov edi, eax
	pop eax
	jmp .1
.3:	mov [gs:edi], ax
	add edi, 2
	jmp .1
.2:	mov [dwDispPos], edi

	pop edi
	pop esi
	pop ebx
	pop ebp
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;显示AL中的数字
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DispAL:
	push ecx
	push edx
	push edi
	
	mov edi, [dwDispPos]
	
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
	;add edi, 2								;留空格

	mov [dwDispPos], edi
	
	pop edi
	pop edx
	pop ecx
	ret
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;显示一个换行(新方法)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DispReturn:
	push szReturn
	call DispStr
	add esp, 4

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;显示一个换行(原来的办法)
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