    bits 16
    org 0x7c00

    VIDEO_MEM   EQU 0xb800
    LINE        EQU 80*2
    LEFT        EQU 2
    RIGHT       EQU 1
    GRASS       EQU 0x82b0 ; old ce
    ROAD        EQU 0x0f00
    SCREEN_AREA EQU 80*25*2

    BONUS       EQU 0x0e24
    BOMB        EQU 0x06ce ; old e9

    LEFT_WHEEL  EQU 0x0fc7
    RIGHT_WHEEL EQU 0x0fb6 ;182
    CAR_BODY    EQU 0xe9df ;219
    FRONT_AXIS  EQU 0x0eca ;202
    REAR_AXIS   EQU 0x0ed2 ;210
    ;CAR_COLOR   EQU 0x0e

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
    mov [seed], dx
    ;; clear screen
    mov ax, SCREEN_AREA
    xor di, di
    mov cx, ax
    rep stosw

    call road
    xor ax, ax
    push ax
main:
    pop ax
    inc ax
    cmp ax, 2
    jb .continue
    call move
    call rand_bomb
    call rand_bonus
    xor ax, ax
    .continue:
    push ax

    ;; check if car not crashed
    mov di, [position]
    mov al, 0x0e
    es and al, [di+1]
    es and al, [di+1-LINE]
    es and al, [di+1-LINE-2]
    es and al, [di+1-LINE+2]
    es and al, [di+1+LINE]
    es and al, [di+1+LINE+2]
    es and al, [di+1+LINE-2]
    cmp al, 0x0e
    jne crash

    ;; draw car at ax
    mov ax, [position]
    call car

    call time

    mov ax, [position]
    call clear_car

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

move:
    push ds
    push es
    pop ds
    std
    mov si, 80*2*24-2
    mov di, 80*2*25-2
    mov cx, 80*24
    rep movsw
    mov ax, ROAD
    mov di, 70*2
    mov cx, 61
    rep stosw
    pop ds
    cld
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
    mov ax, CAR_BODY                 ;center
    es mov [di], ax
    
    mov ax, REAR_AXIS
    es mov [di-LINE], ax
    mov ax, FRONT_AXIS
    es mov [di+LINE], ax

    mov ax, LEFT_WHEEL
    es mov [di-LINE-2], ax
    mov ax, RIGHT_WHEEL
    es mov [di-LINE+2], ax

    mov ax, LEFT_WHEEL
    es mov [di+LINE-2], ax
    mov ax, RIGHT_WHEEL
    es mov [di+LINE+2], ax
    ret

clear_car:
    mov di, ax
    mov ax, ROAD
    es mov [di], ax
    es mov [di-LINE], ax
    es mov [di+LINE], ax
    es mov [di-LINE-2], ax
    es mov [di-LINE+2], ax
    es mov [di+LINE-2], ax
    es mov [di+LINE+2], ax
    ret

rand_bonus:
    call rand
    cmp ax, 0x0fff
    jb .place_bonus
    ret
    .place_bonus:
    call get_position
    add ax, 20
    mov di, ax
    es mov [di], word BONUS
    ret

rand_bomb:
    call rand
    cmp ax, 0xa000
    ja .place_bomb
    ret
    .place_bomb:
    call get_position
    add ax, 20
    mov di, ax
    es mov [di], word BOMB
    ret

get_position:
    xor dx, dx
    mov bx, 60*2
    div bx
    inc dx
    and dx, 0xfffe
    mov ax, dx
    ret
rand:
    push dx
    mov ax, 25173       ; LCG Multiplier
    mul word [seed]     ; DX:AX = LCG multiplier * seed
    add ax, 13849       ; Add LCG increment value
    mov [seed], ax      ; Update seed
    ; AX = (multiplier * seed + increment) mod 65536
    pop dx
    ret


    position    dw 22*LINE+LINE/2
    oldtime     dw 0
    seed        dw 0
    pavement_l  dw 10*2
    pavement_r  dw LINE-10*2

    times 510-($-$$) db 0x00
    dw 0xaa55
