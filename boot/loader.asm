org	0100h
	mov ax, 0B800h
	mov gs, ax
	mov ah, 0Fh
	mov al, 'L'
	mov [gs:((80 * 0 + 39) * 2)], ax
	times 1024 nop
	mov al, 'O'
	mov [gs:((80 * 0 + 40) * 2)], ax
	mov [gs:((80 * 0 + 41) * 2)], ax
	mov al, 'D'
	mov [gs:((80 * 0 + 42) * 2)], ax
	mov al, 'E'
	mov [gs:((80 * 0 + 43) * 2)], ax
	mov al, 'R'
	mov [gs:((80 * 0 + 44) * 2)], ax
	jmp $