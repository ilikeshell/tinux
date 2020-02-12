%include "sconst.inc"

_NR_GET_TICKS		equ		0
INT_VECTOR_SYS_CALL	equ		0x90

global get_ticks

bit32
[section .text]
get_ticks:
	mov eax, _NR_GET_TICKS
	int INT_VECTOR_SYS_CALL
	ret
