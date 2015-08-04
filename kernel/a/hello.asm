[section .data]
	StrHello db "Hello,world!",0Ah
	StrLen equ $ - $$
	
[section .code]
	global	_start
_start:
	mov edx, StrLen
	mov ecx, StrHello
	mov ebx, 1
	mov eax, 4
	int 80h
	mov ebx, 0
	mov eax, 1
	int 80h