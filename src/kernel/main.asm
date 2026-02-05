;I have very little working knowledge of ASM, this is my first time paying
;attention to ASM. As a result this code is overreferenced and commented
;I wanted to know exactly what everything was doing at all times incase
;I needed to debug it. Please excuse the clutter of comments



org 0x7C00   ;base memeory
bits 16        ;start at 16 bit

;define newline
%define ENDL 0x0D, 0x0A


start:
    jmp main ;jump to main function


;print hello world to screen
puts:
    ;pushing registers that will be modified
    push si
    push ax

.loop:
    lodsb  ;loads next char al
    or al, al   ;verify is next char is null
    jz .done    ;if null then job is finished

    ;interrupt the bios so we can print to screen INT 10
    mov ah, 0x0e
    int 0x10

    jmp .loop

.done:
    pop ax
    pop si
    ret

main:
    ; setup data segments
    mov ax, 0   ;move 0 into ax
    mov ds, ax  ;move ax into ds
    mov es, ax  ;move ax into es

    ; setup stack
    mov ss, ax
    mov sp, 0x7c00    ;memeory grows negative from our default load location

    ;print message
    mov si, msg_hello_world ;move msg into si
    call puts           ;call the stack puts


    hlt ;halt

.halt:
    jmp .halt       ;endless loop halt

msg_hello_world: db 'Hello World!', ENDL, 0

;filling spare memory with 0s
times 510-($-$$) db 0
dw 0AA55h
