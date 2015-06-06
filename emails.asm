org 100h

include 'proc16.inc'

start:
	stdcall get_timestamp
	mov [timebegin], ax

	cld
	; Перемещаем аргумент->filename
	mov si, 81h
	stdcall read_filename, input_filename
	stdcall read_filename, output_filename

	; Открываем файл ввода
	mov ah, 3dh
	mov al, 00h
	mov dx, input_filename
	int 21h
	mov [input_handle], ax
	jc error

	; Открываем файл вывода
	mov ah, 3ch
	mov cx, 0
	mov dx, output_filename
	int 21h
	mov [output_handle], ax
	jc error

	mov bx, mask

	; Считываем из файла в буфер
	stdcall load_buffer, 0
	mov di, input_buffer
	mov word [output_buffer_ptr], output_buffer

find_loop:
	mov al, '@'
	repne scasb

	cmp cx, 0
	jne .skip_maybe_end_of_file

	cmp byte [eof], 1
	je finish

	.skip_maybe_end_of_file:

	; Если поиск не нашел @ или нашел но скоро закончится буффер
	cmp cx, email_size / 2
	jge .skip_load

	cmp byte [eof], 1
	je .skip_load

	std
	mov si, di

	; Ищем пробел
	.search_space:

	cmp cx, email_size
	je .found_space

	lodsb
	inc cx

	; Если символ не пробельный
	xlatb
	bt ax, 0
	jnc .search_space
	.found_space:
	; Подгружаем буффер
	cld

	stdcall load_buffer, cx
	mov di, input_buffer

	jmp find_loop

	.skip_load:

.validate_login:
	mov dx, cx
	add cx, 2
	mov si, di
	sub si, 2
	std
	
	.q0:
		cmp si, input_buffer
		je .qBad

		lodsb
		inc cx

		xlatb
		bt ax, 1
		jnc .qBad

	.q1:
		cmp si, input_buffer
		je .qGoodBOF

		lodsb
		inc cx

		cmp al, '.'
		je .q2

		xlatb
		bt ax, 1
		jc .q1

		bt ax, 0
		jc .qGood

		jmp .qBad

	.q2:
		cmp si, input_buffer
		je .qBad

		lodsb
		inc cx

		xlatb
		bt ax, 1
		jc .q1

		jmp .qBad

	.qGood:
		add si, 2
		sub cx, 2
	.qGoodBOF:
		cld
		mov di, [output_buffer_ptr]
		.movchar:
			lodsb
			stosb
			dec cx
			cmp al, '@'
			jne .movchar

		jmp .validate_host

	.qBad:
		cld
		mov cx, dx
		jmp find_loop

.validate_host:
	.p0:
		lodsb
		stosb

		xlatb
		bt ax, 2
		jc .p1

		jmp .pBad

	.p1:
		lodsb
		stosb

		xlatb
		bt ax, 2
		jc .p1
		bt ax, 3
		jc .p2
		bt ax, 0
		jc .pGood

		jmp .pBad

	.p2:
		lodsb
		stosb

		xlatb
		bt ax, 2
		jc .p1
		bt ax, 0
		jc .pGoodSpace

		jmp .pBad

	.pGoodSpace:
		dec di

	.pGood:
		mov word [di], 0D0Ah
		inc di
		mov [output_buffer_ptr], di
		inc word [emails]
		cmp word di, output_buffer + buffer_size - email_size

		jg .skip_io
		mov ah, 40h
		mov cx, [output_buffer_ptr]
		sub cx, output_buffer
		mov dx, output_buffer
		mov bx, [output_handle]
		int 21h
		mov word [output_buffer_ptr], output_buffer
		mov bx, mask
		.skip_io:

		mov cx, [bytesread]
		add cx, input_buffer
		sub cx, si

		mov di, si

	.pBad:
		mov di, si
		jmp find_loop

finish:
	mov ah, 40h
	mov bx, [output_handle]
	mov cx, [output_buffer_ptr]
	sub cx, output_buffer
	mov dx, output_buffer
	int 21h

	mov ah, 09h
	mov dx, timestamp_msg
	int 21h
	stdcall get_timestamp
	sub ax, [timebegin]

	stdcall print_ms

	mov ah, 02h
	mov dl, 0Dh
	int 21h
	mov dl, 0Ah
	int 21h

	mov ah, 09h
	mov dx, finish_msg
	int 21h

	stdcall print_int, [emails]

	ret	

error:
	push ax
	mov ah, 09h
	mov dx, error_message
	int 21h
	pop ax

	mov dx, ax
	add dl, 30h
	mov ah, 02h
	int 21h

	ret

proc load_buffer uses bx, keep
	cld
	; Копируем то что нужно оставить
	mov di, input_buffer
	mov si, input_buffer + buffer_size
	sub si, [keep]
	mov cx, [keep]
	rep movsb

	; Читать
	mov ah, 3fh
	mov bx, [input_handle]
	mov cx, buffer_size
	sub cx, [keep]
	mov dx, input_buffer
	add dx, [keep]
	int 21h

	cmp cx, ax
	setl [eof]

	mov cx, [keep]
	add cx, ax
	mov [bytesread], cx

	ret
endp

include 'utils.inc'

error_message: db 'Error: $'

timestamp_msg: db 'Time: $'
finish_msg: db 'Emails: $'
emails: dw 0

timebegin: dw ?
bytesread: dw ?
eof: db 0
input_filename: times 128 db 0
output_filename: times 128 db 0
input_handle: dw ?
output_handle: dw ?
output_buffer_ptr: dw ?

include 'emails_mask.inc'

buffer_size = 0x5000
email_size = 0x100
input_buffer:
output_buffer = input_buffer + buffer_size