%include "sconst.inc"

;导入函数
extern cstart
extern spurious_irq
extern exception_handler
extern kernel_main
extern disp_str
extern delay
extern clock_handler

;导入全局变量
extern gdt_ptr
extern idt_ptr
extern p_proc_ready
extern tss
extern disp_pos
extern k_reenter

[section .bss]
StackSpace	resb	2 * 1024
StackTop:

[section .data]
clock_int_msg	db   "^",0

[section .text]
global _start
global restart

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

;硬件终端异常处理
global hwint_00
global hwint_01
global hwint_02
global hwint_03
global hwint_04
global hwint_05
global hwint_06
global hwint_07
global hwint_08
global hwint_09
global hwint_10
global hwint_11
global hwint_12
global hwint_13
global hwint_14
global hwint_15

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
	sgdt [gdt_ptr]
	;挪GDT到内核,初始化IDT
	call cstart
	lgdt [gdt_ptr]
	lidt [idt_ptr]
	jmp SELECTOR_KERNEL_CS:csinit
	csinit:
	push 0
	popfd
	;ud2
	;jmp 0x40:0
	
	;mov ah, 0Fh
	;mov al, 'K'
	;mov [gs:((80 * 2 + 39) * 2)], ax

	;sti
	;hlt
	;加载TSS描述符
	xor eax, eax
	mov ax, SELECTOR_TSS
	ltr ax

	;jmp kernel_main
	jmp kernel_main

	
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


;硬件中断处理
%macro hwint_master 1
	push %1
	call spurious_irq
	add esp, 4
	hlt
%endmacro

%macro hwint_slave 1
	push %1
	call spurious_irq
	add esp, 4
	hlt
%endmacro

hwint_00:
		;hwint_master 0

		sub esp, 4
		;保存寄存器的值
		pushad
		push ds
		push es
		push fs
		push gs

		;设置段寄存器
		mov dx, ss
		mov ds, dx
		mov es, dx

		inc byte [gs:0]

		;设置EOI
		mov al, EOI
		out INT_M_CTL, al

		;判断是否中断重入
		inc dword [k_reenter]
		cmp dword [k_reenter], 0
		jne .re_enter

		;切到内核栈
		mov esp, StackTop

		;开中断
		sti

		;验证是否影响到中断处理程序
		push 0
		call clock_handler
		add esp, 4

		;关中断
		cli

		;离开内核栈
		mov esp, [p_proc_ready]

		;设置tss.esp0
		lea eax, [esp + P_STACKTOP]
		mov dword [tss + TSS3_S_SP0], eax

.re_enter:
		dec dword [k_reenter]
		;恢复寄存器的值
		pop gs
		pop fs
		pop es
		pop ds
		popad
		;跳过返回地址
		add esp, 4

		iretd
hwint_01:
		hwint_master 1
hwint_02:
		hwint_master 2
hwint_03:
		hwint_master 3
hwint_04:
		hwint_master 4
hwint_05:
		hwint_master 5
hwint_06:
		hwint_master 6
hwint_07:
		hwint_master 7
hwint_08:
		hwint_slave 8
hwint_09:
		hwint_slave 9
hwint_10:
		hwint_slave 10
hwint_11:
		hwint_slave 11
hwint_12:
		hwint_slave 12
hwint_13:
		hwint_slave 13
hwint_14:
		hwint_slave 14
hwint_15:
		hwint_slave 15


;===================================================================
;					restart
;   准备好第一个进程运行的环境，用iretd进行切换
;===================================================================
restart:
	mov esp, [p_proc_ready]
	lldt [esp + P_LDT_SEL]
	;lea eax, [esp + P_STACKTOP]
	mov eax, esp
	add eax, P_STACKTOP
	mov dword [tss + TSS3_S_SP0], eax   ;tss ??????

	pop gs
	pop fs
	pop es
	pop ds
	popad

	add esp, 4

	iretd
