SELECTOR_KERNEL_CS	equ	8

;导入函数
extern cstart
;导入全局变量
extern gdt_ptr

[section .bss]
StackSpace	resb	2 * 1024
StackTop:

[section .text]
global _start
_start:
	;
	mov esp, StackTop
	;
	sgdt [gdt_ptr]
	call cstart
	lgdt [gdt_ptr]
	
	jmp SELECTOR_KERNEL_CS:csinit
	csinit:
	push 0
	popfd
	
	mov ah, 0Fh
	mov al, 'K'
	mov [gs:((80 * 2 + 39) * 2)], ax
	
	hlt
