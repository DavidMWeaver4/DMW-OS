;I have very little working knowledge of ASM, this is my first time paying
;attention to ASM. As a result this code is overreferenced and commented
;I wanted to know exactly what everything was doing at all times incase
;I needed to debug it. Please excuse the clutter of comments



org 0x7C00   ;base memeory
bits 16        ;start at 16 bit

;define newline
%define ENDL 0x0D, 0x0A

;FAT12 headers
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'   ;8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880          ;2880*512 is 1.44mb
bdb_media_descriptor_type:  db 0F0h
bdb_sectors_per_fat:        dw 9
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

;extended boot record
ebr_drive_number:           db 0
                            db 0
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h
ebr_volume_label:           db 'DMWeaver OS'
ebr_system_id:              db 'FAT12   '

;code starts below


start:
    jmp main ;jump to main function


;print hello world to screen
puts:
    ;pushing registers that will be modified
    push si
    push ax
    push bx

.loop:
    lodsb  ;loads next char al
    or al, al   ;verify is next char is null
    jz .done    ;if null then job is finished

    ;interrupt the bios so we can print to screen INT 10
    mov ah, 0x0e
    mov bh, 0
    int 0x10

    jmp .loop

.done:
    pop bx
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

    mov [ebr_drive_number], dl
    mov ax, 1
    mov cl, 1
    mov bx, 0x7E00
    call disk_read

    ;print message
    mov si, msg_hello_world         ;move msg into si
    call puts                       ;call the stack puts

    cli
    hlt ;halt

floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h
    jmp 0FFFFh:0

.halt:
    cli
    hlt



;disk routines

;LBA address to a CHS address
; Params -ax: LBA address
;returns
;cx[bits 0-5]: sector number
;cx[bits 6-15]: sylinder
;dh: head

lba_to_chs:
    push ax
    push dx

    xor dx, dx                                  ;dx == 0
    div word [bdb_sectors_per_track]            ;ax = LBA / sectors per track

    inc dx                                      ;dx = (LBA % sectors per track + 1) == sector
    mov cx, dx                                  ;put dx value into cx

    xor dx, dx                                  ;0
    div word [bdb_heads]                        ;ax = (LBA/ sectors per track)/ heads = cylinder
                                                ;dx = lba/sec per track) % heads = head
    mov dh, dl                                  ;dh = head
    mov ch, al                                  ;ch = cylinder
    shl ah, 6
    or cl, ah                                   ;put upper 2 bits of cylinder in CL

    pop ax
    mov dl, al                                  ;restore DL
    pop ax
    ret


;reads sectors from disk
;params
;ax:LBA address
;cl: numbers of sectors to reads
;dl:drive number
;es:bx memory address to store and read

disk_read:
    push ax
    push bx
    push cx
    push dx
    push di

    push cx
    call lba_to_chs
    pop ax

    mov ah, 02h
    mov di, 3   ;retry

.retry:
    pusha
    stc
    int 13h
    jnc .done

    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    jmp floppy_error

.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;resets disk controller
;param- dl:drive number
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret


msg_hello_world: db 'Hello World!', ENDL, 0
msg_read_failed db 'Read from floppy disk failed!', ENDL, 0

;filling spare memory with 0s
times 510-($-$$) db 0
dw 0AA55h
