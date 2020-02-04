    bits 16
    org 0x7c00
start:
    xor ax, ax
    mov ds, ax
    mov ss, ax

    mov al, 0x03
    int 0x10
    mov ax, 0xb800
    mov es, ax

    ;; clean screen
    xor di, di
    mov cx, 80*25
    mov ah, 0x4F
    mov al, 0x20
    rep stosw

    mov di, 2*80+8
    mov si, line1
    mov cx, line2-line1
    call print

    mov di, 4*2*80+8
    mov si, line2
    mov cx, line3-line2
    call print

    mov di, 5*2*80+8
    mov si, line3
    mov cx, oldtime-line3
    call print

    mov al, 0x4f
    mov bx, 0
    push bx ; line
    .p0:
    mov di, 17*2*80+2 ; where to start
    pop dx ; line
    mov bx, 2*80
    imul bx, dx
    add di, bx ; calculate line

    mov si, logo
    mov bx, 7
    imul bx, dx
    add si, bx ; choose line of logo
    push dx ; save line

    mov bx, 0 ; col
    .pl:
    push si ; save logo addr
    mov cx, 7
    .cp:
    movsb
    stosb
    loop .cp
    add di, 2
    inc bx
    pop si
    cmp bx, 10
    jb .pl
    pop bx ; line
    inc bx
    push bx
    cmp bx, 3
    jb .p0



    mov ax, 0x47b1
    .repeat:
    mov di, 22*2*80+4
    mov cx, 76
    inc ah

    .wait:
    push ax
    push cx
    .sec:
    mov ah, 0x00
    int 0x1a
    cmp dx, [oldtime]
    je .sec
    mov [oldtime], dx
    pop cx
    pop ax
    stosw
    loop .wait

    jmp .repeat

    jmp $

print:
    cld
    mov al, ah
    .print_loop:
    movsb
    stosb
    loop .print_loop
    ret

    line1 db "Freedom for the factorial!!!"
    line2 db "You PC has been encrypted! If You want to get back your "
    line3 db "data write proper factorial alghoritm in assembler on the whiteboard!", 
    oldtime dw 0x00

    logo db '(\___/)'
         db '(=^.^=)'
         db '(")_(")'


    times 510-($-$$) db 0x00
    dw 0xaa55
    