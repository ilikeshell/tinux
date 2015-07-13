;lib.inc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;显示一个整数
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DispInt:
	push ebx
	
	mov ebx, [esp + 4]
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
	
	mov esi, [ebp + 8]
	
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

	pop edx
	pop ecx
	ret
	
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