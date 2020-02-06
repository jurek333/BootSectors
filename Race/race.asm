    bits 16
    org 0x7c00

    VIDEO_MEM   EQU 0xb800
    LINE        EQU 80*2
    LEFT        EQU 2
    RIGHT       EQU 1
    GRASS       EQU 0x27b0 
    GRASS2      EQU 0x2eb3
    ROAD        EQU 0x0f00
    SCREEN_AREA EQU 80*25*2

    BONUS       EQU 0x0e24
    BOMB        EQU 0x04eb

    LEFT_WHEEL  EQU 0x0fc7
    RIGHT_WHEEL EQU 0x0fb6 ;182
    CAR_BODY    EQU 0xe9df ;219
    FRONT_AXIS  EQU 0x0eca ;202
    REAR_AXIS   EQU 0x0ed2 ;210
    B_0         EQU 0
    B_E         EQU LINE-2
    BORDER_L    EQU 20
    BORDER_R    EQU LINE-20
    SCORE_POS   EQU 80*2*24+LINE-6

start:
    xor ax, ax
    mov ss, ax
    mov ds, ax
    mov bp, 0x7c00
    mov sp, bp
    push word VIDEO_MEM
    pop es
    ;mov es, VIDEO_MEM
    std

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

    mov di, SCREEN_AREA-2
    mov cx, 80*25
    mov bx, 10
    jmp .paint_grass

    .grass:
    mov bx, 0
    .paint_grass:
    inc bx
    cmp bx, 20
    ja .road
    mov ax, GRASS
    stosw
    loop .paint_grass
    jmp .end_board

    .road:
    mov bx, 0
    .paint_road:
    inc bx
    cmp bx, 60
    ja .grass
    mov ax, ROAD
    stosw
    loop .paint_road
    .end_board:

    ;; init frame counter
    xor ax, ax
    push ax
main:
    pop ax
    inc ax
    cmp ax, 2
    jb .skip_movement

    ;; move road under the car
    push ds
    push es
    pop ds
    mov si, 80*2*24-2
    mov di, 80*2*25-2
    mov cx, 80*24
    rep movsw
    mov ax, ROAD
    mov di, 69*2
    mov cx, 60
    rep stosw
    pop ds
    
    mov ax, BOMB
    mov bx, 0xa000
    call rand

    mov ax, BONUS
    mov bx, 0x0fff
    call rand

    ;; draw score    
    mov bx, word [score]
    mov di, SCORE_POS
    mov ah, 0x2e
    mov cx,4
    .nibble:
    mov al, bl
    and al, 0x0f
    cmp al, 0x0a
    jb .digit
    add al, 0x41-0x0a-0x30
    .digit:
    add al, 0x30
    stosw
    shr bx, 4
    loop .nibble
    
    xor ax, ax
    .skip_movement:
    push ax

    ;; check if car not crashed
    mov di, [position]
    mov al, 0x0f
    es and al, [di+1]
    es and al, [di+1-LINE]
    es and al, [di+1-LINE-2]
    es and al, [di+1-LINE+2]
    es and al, [di+1+LINE]
    es and al, [di+1+LINE+2]
    es and al, [di+1+LINE-2]
    cmp al, 0x0f
    je .ride
    cmp al, 0x0e
    je .score

    .crash:
    mov di, [position]
    call car
    es mov byte [di+1], 0x44
    es mov byte [di+1-LINE], 0x04
    es mov byte [di+1+LINE], 0x04
    es mov byte [di+1-LINE-2], 0x04
    es mov byte [di+1-LINE+2], 0x04
    es mov byte [di+1+LINE-2], 0x04
    es mov byte [di+1+LINE+2], 0x04
    
    .end:    
    xor ah, ah
    int 0x16
    cmp ah, 0x1c
    jne .end
    int 0x19

    .score:
    inc word [score]
    .ride:
    ;; draw car at ax
    mov di, [position]
    call car

    ;; wait till tick
    .time:
    mov ah, 0x00
    int 0x1a
    cmp dx, [oldtime]
    je .time
    mov [oldtime],dx

    ;; clear car
    mov di, [position]
    mov ax, ROAD
    es mov [di], ax
    es mov [di-LINE], ax
    es mov [di+LINE], ax
    es mov [di-LINE-2], ax
    es mov [di-LINE+2], ax
    es mov [di+LINE-2], ax
    es mov [di+LINE+2], ax

    ;mov ah, 0x01
    ;int 0x16
    ;je main
    ;mov di, 0x041a
    ;ds mov dword [di], 0x041e041e    
    mov ah, 0x02
    int 0x16

    cmp al, LEFT               ;left
    jne .skip_left
    mov bx, [position]
    sub bx, 2
    mov [position], bx
    jmp main
    .skip_left:
    cmp al, RIGHT               ; right
    jne main
    mov bx, [position]
    add bx, 2
    mov [position], bx
    jmp main

car:
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

rand:
    push ax             ; item symbol
    push bx             ; probability
    mov ax, 25173       ; LCG Multiplier
    mul word [seed]     ; DX:AX = LCG multiplier * seed
    add ax, 13849       ; Add LCG increment value
    mov [seed], ax      ; Update seed
                        ; AX = (multiplier * seed + increment) mod 65536
    pop bx              ; probability
    cmp ax, bx
    ja .return
        
    xor dx, dx
    mov bx, 59*2
    div bx
    inc dx
    and dx, 0xfffe
    mov ax, dx
    add ax, 20
    mov di, ax
    pop bx              ; item symbol
    es mov [di], bx
    ret
    .return:
    pop bx              ; item symbol
    ret

    position    dw 22*LINE+LINE/2
    score       dw 0x0000
    oldtime     dw 0
    seed        dw 0

    times 510-($-$$) db 0x00
    dw 0xaa55
