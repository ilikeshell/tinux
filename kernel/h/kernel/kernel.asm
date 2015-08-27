SELECTOR_KERNEL_CS	equ	8
SELECTOR_KERNEL_DS	equ	10h
SELECTOR_KERNEL_GS	equ	1Bh

;导入函数
extern cstart
;导入全局变量
extern gdt_ptr
extern idt_ptr
extern exception_handler

[section .bss]
StackSpace	resb	2 * 1024
StackTop:

[section .text]
global _start

global divide_error
global single_step_exception
global nmi
global breakpoint_exception
global overflow
global bounds_check
global invalid_opcode
global copr_not_available
global double_fault
global copr_seg_overrun
global invalid_tss
global segment_not_present
global stack_exception
global general_protection
global page_fault
global copr_error

_start:
	;mov ax, SELECTOR_KERNEL_DS
	;mov ds, ax
	;mov es, ax
	;mov fs, ax
	;mov ss, ax
	;mov ax, SELECTOR_KERNEL_GS
	;mov gs, ax
	
	;重设堆栈
	mov esp, StackTop
	;挪GDT到内核
	sgdt [gdt_ptr]
	call cstart
	lgdt [gdt_ptr]
	lidt [idt_ptr]
	jmp SELECTOR_KERNEL_CS:csinit
	csinit:
	push 0
	popfd
	
	mov ah, 0Fh
	mov al, 'K'
	mov [gs:((80 * 2 + 39) * 2)], ax
	hlt
	
divide_error:
	push 0xFFFFFFFF
	push 0
	jmp exception
single_step_exception:
	push 0xFFFFFFFF
	push 1
	jmp exception
nmi:
	push 0xFFFFFFFF
	push 2
	jmp exception
breakpoint_exception:
	push 0xFFFFFFFF
	push 3
	jmp exception
overflow:
	push 0xFFFFFFFF
	push 4
	jmp exception
bounds_check:
	push 0xFFFFFFFF
	push 5
	jmp exception
invalid_opcode:
	push 0xFFFFFFFF
	push 6
	jmp exception
copr_not_available:
	push 0xFFFFFFFF
	push 7
	jmp exception
double_fault:
	push 8
	jmp exception
copr_seg_overrun:
	push 0xFFFFFFFF
	push 9
	jmp exception
invalid_tss:
	push 10
	jmp exception
segment_not_present:
	push 11
	jmp exception
stack_exception:
	push 12
	jmp exception
general_protection:
	push 13
	jmp exception
page_fault:
	push 14
	jmp exception
copr_error:
	push 0xFFFFFFFF
	push 16
	jmp exception
exception:
	call exception_handler
	add esp, 4*2
	hlt
