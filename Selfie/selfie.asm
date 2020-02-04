    bits 16
    org 0x7c00
start:
    xor ax, ax
    mov ds, ax
    mov ss, ax

    ;; color text mode 80x25
    mov ah, 0xb8
    mov es, ax
    mov ax, 0x0003
    int 0x10
    ;; clean screen
    xor di, di
    mov cx, 80*25
    rep stosw
    ;; Print memory 512 bytes 
    ;; (2 chars on byte plus space every word)
    xor di, di
    mov si, start
    mov cx, 512*2+256
    cld
    mov ah, 0x0e
    xor bx, bx
print:
    mov al, [si]
    push ax
    ;; first nibble
    shr al, 4
    call cast
    stosw
    dec cx
    ;; second nibble
    pop ax
    and al, 0x0f
    call cast
    stosw
    ;; print space if needed
    inc bx
    test bx, 1
    jnz .skip_space
    mov al, 0x20
    stosw
    dec cx
    .skip_space:

    inc si
    loop print

jmp $

cast:
    cmp al, 0x0a
    jb .number
    add al, 0x37
    ret
    .number:
    add al, 0x30
    ret

    times 510-($-$$) db 0
    dw 0xaa55
