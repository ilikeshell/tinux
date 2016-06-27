; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                              string.asm
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                                                       kenny, 2015
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

[SECTION .text]

; 导出函数
global	memcpy
global  memset
global  strcpy

; ------------------------------------------------------------------------
; void* memcpy(void* es:pDest, void* ds:pSrc, int iSize);
; ------------------------------------------------------------------------
memcpy:
	push ebp
	mov ebp, esp
	
	push esi
	push edi
	push ecx
	
	mov edi, [ebp+8]
	mov esi, [ebp+12]
	mov ecx, [ebp+16]
	
	.1:
	cmp ecx, 0
	jz .2
	mov al, [ds:esi]
	mov [es:edi], al
	inc esi
	inc edi
	dec ecx
	jmp .1
	.2:
	mov eax, [ebp+8]
	
	pop ecx
	pop edi
	pop esi
	
	mov esp, ebp	;清栈
	pop ebp
	ret

; ------------------------------------------------------------------------
; void  memset(void* pdest, char ch, int size);
; ------------------------------------------------------------------------
memset:
	push ebp
	mov ebp, esp

	push edi
	push ecx

	mov edi, [ebp + 8]
	mov eax, [ebp + 12]
	mov ecx, [ebp + 16]
	.1:
	cmp ecx, 0
	jz .2
	mov byte [edi], al
	inc edi
	dec ecx
	jmp .1

	.2:
	pop ecx
	pop edi

	mov esp, ebp	;清栈
	pop ebp
	ret



; ------------------------------------------------------------------------
; char*  strcpy(void* pdest, void* psource);
; ------------------------------------------------------------------------
strcpy:
	push ebp
	mov ebp, esp

	push edi
	push esi

	mov edi, [ebp + 8]
	mov esi, [ebp + 12]

	.1:
	mov al, byte [esi]
	mov byte [edi], al
	inc esi
	inc edi

	cmp al, 0
	jne .1

	pop esi
	pop edi

	mov eax, [ebp + 8]
	mov esp, ebp	;清栈
	pop ebp
	ret
