include 'proc16.inc'

proc read_filename x
    mov di, si
	mov al, ' '
	repe scasb
	mov si, di
	dec si

	mov di, [x]

	.next:
	lodsb
	cmp al, ' '
	je .fin
	cmp al, 0Dh
	je .fin
	stosb
	jmp .next
	.fin:
	mov byte [di], 0
	ret
endp

proc print_int uses ax dx cx, x
	mov ax, [x]
	mov dx, 0
	mov cx, 10
	idiv cx

	cmp ax, 0
	je .skip
	stdcall print_int, ax
	.skip:
	mov ah, 02h
	add dl, 30h
	int 21h
	ret
endp

proc get_timestamp uses bx cx dx
	mov ah, 2ch
	int 21h

	mov ah, 0
	mov al, cl
	mov bx, 60
	push dx
	mul bx
	pop dx
	mov ch, 0
	mov cl, dh
	add ax, cx

	mov bx, 100
	push dx
	mul bx
	pop dx
	mov dh, 0
	add ax, dx

	ret
endp

proc print_ms
	mov dx, 0
	mov cx, 100
	idiv cx
	stdcall print_int, ax

	push ax
	push dx
	mov ah, 02h
	mov dl, '.'
	int 21h
	pop dx
	pop ax

	cmp dx, 10
	jge .skip
	push dx
	mov ah, 02h
	mov dl, '0'
	int 21h
	pop dx
	.skip:

	stdcall print_int, dx
	ret
endp