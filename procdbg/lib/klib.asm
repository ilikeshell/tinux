%include "sconst.inc"

;导入全局变量
extern disp_pos

[section .text]
global disp_str
global disp_color_str
global out_byte
global in_byte
global enable_irq
global disable_irq
;extern disp_pos
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
	mov edi, [disp_pos]
	mov [gs:edi], ax
	add edi, 4
	mov [disp_pos], edi
	pop edi
	
	pop ebx
	ret
;DispInt结束

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;显示一个字符串
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
disp_str:
	push ebp
	mov ebp, esp
	push ebx
	push esi
	push edi
	
	mov ah, 0Fh
	mov esi, [ebp + 8]			;要显示的字符串首地址
	mov edi, [disp_pos]		;
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
.2:	mov [disp_pos], edi

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
	
	mov edi, [disp_pos]
	
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

	mov [disp_pos], edi
	
	pop edi
	pop edx
	pop ecx
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
;换行结束

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  void out_byte(u16 port, u8 value);
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
out_byte:
	mov edx, [esp + 4]
	mov al, [esp + 8]
	out dx, al
	nop
	nop
	nop
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  u8 in_byte(u16 port);
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
in_byte:
	mov edx, [esp + 4]
	xor eax, eax 
	in al, dx
	nop
	nop
	nop
	ret
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;显示一个彩色字符串
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
disp_color_str:
	push ebp
	mov ebp, esp
	push ebx
	push esi
	push edi
	
	mov ah, [ebp + 12]
	mov esi, [ebp + 8]			;要显示的字符串首地址
	mov edi, [disp_pos]		;
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
.2:	mov [disp_pos], edi

	pop edi
	pop esi
	pop ebx
	pop ebp
	ret

;===================================================================
;				void disable_irq(int irq)
;
;===================================================================
disable_irq:
	mov ecx, [esp + 4]
	pushf
	cli
	mov ah, 1
	rol ah, cl
	cmp cl, 8
	jae disable_8
disable_0:
	in al, INT_M_CTLMASK
	test al, ah
	jnz dis_already
	or al, ah
	out INT_M_CTLMASK, al
	popf
	mov eax, 1
	ret
disable_8:
	in al, INT_S_CTLMASK
	test al, ah
	jnz dis_already
	or al, ah
	out INT_S_CTLMASK, al
	popf
	mov eax, 1
	ret
dis_already:
	popf
	xor eax, eax
	ret
;===================================================================
;				void disable_irq(int irq)
;
;===================================================================
enable_irq:
	mov ecx, [esp + 4]
	pushf
	cli
	mov ah, ~1
	rol ah, cl
	cmp cl, 8
	jae enable_8
enable_0:
	in al, INT_M_CTLMASK
	and al, ah
	out INT_M_CTLMASK, al
	popf
	ret
enable_8:
	in al, INT_S_CTLMASK
	and al, ah
	out INT_S_CTLMASK, al
	popf
	ret

