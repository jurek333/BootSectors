    bits 16
    org 0x7c00

    VIDEO_MEM   EQU 0xb800
    LINE        EQU 80*2
    LEFT        EQU 2
    RIGHT       EQU 1
    GRASS       EQU 0x02ce
    ROAD        EQU 0x0f00
    SCREEN_AREA EQU 0x0f00

    LEFT_WHEEL  EQU 199
    RIGHT_WHEEL EQU 182
    CAR_BODY    EQU 219
    FRONT_AXIS  EQU 202
    REAR_AXIS   EQU 210
    CAR_COLOR   EQU 0x0e

start:
    xor ax, ax
    mov ss, ax
    mov sp, VIDEO_MEM
    mov ds, ax
    mov es, sp
    cld

    ;; color text mode 
    mov al, 0x03
    int 0x10
    ;; turn off cursor
    mov ch, 0x26
    mov ax, 0x103
    int 0x10
    ;; initial time
    mov ah, 0x00
    int 0x1a
    mov [oldtime], dx
    ;; clear screen
    mov ax, SCREEN_AREA
    xor di, di
    mov cx, ax
    rep stosw

main:
    call road

    ;; check if car not crashed
    mov di, [position]
    es mov ax, [di]
    test al, al
    jnz crash

    ;; draw car at ax
    mov ax, [position]
    call car

    call time

    mov ah, 0x02
    int 0x16
    
    test al, LEFT               ;left
    jz .skip_left
    mov bx, [position]
    sub bx, 2
    mov [position], bx
    jmp main
    .skip_left:
    test al, RIGHT               ;right
    jz .skip_right
    mov bx, [position]
    add bx, 2
    mov [position], bx
    jmp main
    .skip_right:
    cmp ah, 1
    je end
    
    jmp main

crash:
    mov ax, [position]
    call car
    mov di, [position]
    es mov word [di-LINE], 0xcbb0
    es mov word [di-2], 0xc4b2
    es mov word [di], 0xf4bd
    es mov word [di+2], 0xc4b2
    es mov word [di+LINE], 0xcbb0
end:
    jmp $

    ;; changes ah, dx
time:
    mov ah, 0x00
    int 0x1a
    cmp dx, [oldtime]
    je time
    mov [oldtime],dx
    ret

road:
    xor di, di
    mov cx, SCREEN_AREA
    .board:
    mov bx, di
    jmp .while
    .dec:
    sub bx, LINE
    .while:
    cmp bx, LINE
    jnb .dec
    mov ax, GRASS
    cmp bx, [pavement_l]
    jb .paint
    cmp bx, [pavement_r]
    ja .paint
    mov ax, ROAD
    jmp .paint
    .pav:
    mov ax, GRASS
    .paint:
    stosw
    loop .board
    ret

car:
    mov di, ax
    mov ah, CAR_COLOR
    mov al, CAR_BODY                 ;center
    es mov [di], ax
    mov al, REAR_AXIS
    es mov [di-LINE], ax
    mov al, FRONT_AXIS
    es mov [di+LINE], ax

    mov al, LEFT_WHEEL
    es mov [di-LINE-2], ax
    mov al, RIGHT_WHEEL
    es mov [di-LINE+2], ax

    mov al, LEFT_WHEEL
    es mov [di+LINE-2], ax
    mov al, RIGHT_WHEEL
    es mov [di+LINE+2], ax
    ret

    position    dw 22*LINE+LINE/2
    oldtime     dw 0
    pavement_l  dw 10*2
    pavement_r  dw LINE-10*2

    times 510-($-$$) db 0x00
    dw 0xaa55
