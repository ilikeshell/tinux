; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                              string.asm
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                                                       kenny, 2015
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

[SECTION .text]

; 导出函数
global	memcpy


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
	
	pop ebp
	ret