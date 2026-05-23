default rel
global _start

section .data
    l_os    db "OS:         ", 0
    l_host  db "Host:       ", 0
    l_ker   db "Kernel:     ", 0
    l_up    db "Uptime:     ", 0
    l_pkg   db "Packages:   ", 0
    l_sh    db "Shell:      ", 0
    l_de    db "DE:         ", 0
    l_wm    db "WM:         ", 0
    l_term  db "Terminal:   ", 0
    l_cpu   db "CPU:        ", 0
    l_gpu   db "GPU:        ", 0
    l_ram   db "Memory:     ", 0
    l_swp   db "Swap:       ", 0
    l_dsk   db "Disk:       ", 0
    l_ip    db "Local IP:   ", 0
    l_loc   db "Locale:     ", 0

    s_at    db "@", 0
    s_mb    db " MB", 0
    s_gb    db " GB", 0
    s_sep   db " / ", 0
    s_min   db " mins", 0
    s_dash  db "-----------------", 10, 0
    s_dot   db ".", 0
    s_col   db ":", 0
    unk     db "n/a", 0

    p_os    db "/etc/os-release", 0
    p_mem   db "/proc/meminfo", 0
    p_upt   db "/proc/uptime", 0
    p_host  db "/sys/class/dmi/id/product_name", 0
    p_gpuv  db "/sys/class/drm/card0/device/vendor", 0
    p_gpud  db "/sys/class/drm/card0/device/device", 0
    p_root  db "/", 0
    p_pac   db "/var/lib/pacman/local", 0
    p_dpkg  db "/var/lib/dpkg/info", 0

    k_memt  db "MemTotal:", 0
    k_mema  db "MemAvailable:", 0
    k_swpt  db "SwapTotal:", 0
    k_swpf  db "SwapFree:", 0
    k_pn    db "PRETTY_NAME=", 0

    e_usr   db "USER=", 0
    e_sh    db "SHELL=", 0
    e_de    db "XDG_CURRENT_DESKTOP=", 0
    e_wm    db "XDG_SESSION_DESKTOP=", 0
    e_term  db "TERM=", 0
    e_loc   db "LANG=", 0

    saddr   dw 2
            dw 0x3500
            dd 0x01010101
            dq 0
    slen    dd 16

section .bss
    rawbuf  resb 8192
    outbuf  resb 4096
    un      resb 390
    envptr  resq 1
    outpos  resq 1
    memt    resq 1
    mema    resq 1
    swpt    resq 1
    swpf    resq 1

section .text

append:
    push rbx
    push rcx
    mov  rbx, [outpos]
.lp:
    movzx ecx, byte [rsi]
    test  ecx, ecx
    jz    .fin
    mov   [outbuf+rbx], cl
    inc   rsi
    inc   rbx
    jmp   .lp
.fin:
    mov  [outpos], rbx
    pop  rcx
    pop  rbx
    ret

putch:
    push rbx
    mov  rbx, [outpos]
    mov  [outbuf+rbx], cl
    inc  rbx
    mov  [outpos], rbx
    pop  rbx
    ret

crnl:
    mov  cl, 10
    jmp  putch

numcat:
    push rbx
    push rcx
    push rdx
    mov  ebx, 10
    lea  rcx, [rawbuf+7900]
    mov  byte [rcx], 0
.dig:
    xor  edx, edx
    div  rbx
    add  dl, '0'
    dec  rcx
    mov  [rcx], dl
    test rax, rax
    jnz  .dig
    mov  rsi, rcx
    call append
    pop  rdx
    pop  rcx
    pop  rbx
    ret

slurp:
    push rbx
    mov  eax, 2
    xor  esi, esi
    xor  edx, edx
    syscall
    test rax, rax
    js   .err
    mov  rbx, rax
    xor  eax, eax
    mov  edi, ebx
    lea  rsi, [rawbuf]
    mov  edx, 8191
    syscall
    push rax
    mov  eax, 3
    mov  edi, ebx
    syscall
    pop  rax
    pop  rbx
    ret
.err:
    xor  eax, eax
    pop  rbx
    ret

skipws:
    movzx ecx, byte [rbx]
    cmp   ecx, 32
    je    .sp
    cmp   ecx, 9
    je    .sp
    ret
.sp:
    inc   rbx
    jmp   skipws

atoi:
    xor  eax, eax
.d:
    movzx edx, byte [rbx]
    sub   edx, '0'
    js    .fin
    cmp   edx, 9
    jg    .fin
    imul  rax, rax, 10
    add   eax, edx
    inc   rbx
    jmp   .d
.fin:
    ret

cmpn:
    push rsi
    push rdi
    push rcx
.c:
    test  rcx, rcx
    jz    .yes
    movzx r8d, byte [rsi]
    movzx r9d, byte [rdi]
    cmp   r8d, r9d
    jne   .no
    inc   rsi
    inc   rdi
    dec   rcx
    jmp   .c
.yes:
    xor  eax, eax
    pop  rcx
    pop  rdi
    pop  rsi
    ret
.no:
    mov  eax, 1
    pop  rcx
    pop  rdi
    pop  rsi
    ret

getenv:
    mov r8, [envptr]
.lp:
    mov rdi, [r8]
    test rdi, rdi
    jz .fail
    push rsi
    push rdi
.chr:
    movzx eax, byte [rsi]
    test eax, eax
    jz .mtc
    movzx ebx, byte [rdi]
    cmp eax, ebx
    jne .nxt
    inc rsi
    inc rdi
    jmp .chr
.mtc:
    mov rax, rdi
    pop rdi
    pop rsi
    ret
.nxt:
    pop rdi
    pop rsi
    add r8, 8
    jmp .lp
.fail:
    xor eax, eax
    ret

sysfsr:
    call slurp
    test rax, rax
    jz .err
    lea rbx, [rawbuf]
    add rbx, rax
    dec rbx
    cmp byte [rbx], 10
    jne .prt
    mov byte [rbx], 0
.prt:
    lea rsi, [rawbuf]
    call append
    ret
.err:
    lea rsi, [unk]
    call append
    ret

memparse:
    push rbx
    push rcx
    xor  rax, rax
    mov  [memt], rax
    mov  [mema], rax
    mov  [swpt], rax
    mov  [swpf], rax
    lea  rdi, [p_mem]
    call slurp
    test rax, rax
    jz   .fin
    mov  byte [rawbuf+rax], 0
    lea  rbx, [rawbuf]
.scn:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    .fin
    lea   rsi, [k_memt]
    mov   rdi, rbx
    mov   ecx, 9
    call  cmpn
    jnz   .t2
    add   rbx, 9
    call  skipws
    call  atoi
    mov   [memt], rax
    jmp   .nl
.t2:
    lea   rsi, [k_mema]
    mov   rdi, rbx
    mov   ecx, 13
    call  cmpn
    jnz   .t3
    add   rbx, 13
    call  skipws
    call  atoi
    mov   [mema], rax
    jmp   .nl
.t3:
    lea   rsi, [k_swpt]
    mov   rdi, rbx
    mov   ecx, 9
    call  cmpn
    jnz   .t4
    add   rbx, 9
    call  skipws
    call  atoi
    mov   [swpt], rax
    jmp   .nl
.t4:
    lea   rsi, [k_swpf]
    mov   rdi, rbx
    mov   ecx, 9
    call  cmpn
    jnz   .skp
    add   rbx, 9
    call  skipws
    call  atoi
    mov   [swpf], rax
.skp:
.nl:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    .fin
    cmp   ecx, 10
    je    .stp
    inc   rbx
    jmp   .nl
.stp:
    inc   rbx
    jmp   .scn
.fin:
    pop  rcx
    pop  rbx
    ret

osname:
    push rbx
    push rcx
    lea  rdi, [p_os]
    call slurp
    test rax, rax
    jz   .fail
    mov  byte [rawbuf+rax], 0
    lea  rbx, [rawbuf]
.scn:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    .fail
    lea   rsi, [k_pn]
    mov   rdi, rbx
    mov   ecx, 12
    call  cmpn
    jnz   .nxt
    add   rbx, 12
    movzx ecx, byte [rbx]
    cmp   ecx, 34
    jne   .cpy
    inc   rbx
.cpy:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    .fin
    cmp   ecx, 34
    je    .fin
    cmp   ecx, 10
    je    .fin
    mov   cl, byte [rbx]
    call  putch
    inc   rbx
    jmp   .cpy
.fin:
    pop  rcx
    pop  rbx
    ret
.nxt:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    .fail
    cmp   ecx, 10
    je    .stp
    inc   rbx
    jmp   .nxt
.stp:
    inc   rbx
    jmp   .scn
.fail:
    lea  rsi, [unk]
    call append
    pop  rcx
    pop  rbx
    ret

getcpu:
    lea  rdi, [rawbuf+6000]
    mov  eax, 0x80000002
    cpuid
    mov  [rdi],    eax
    mov  [rdi+4],  ebx
    mov  [rdi+8],  ecx
    mov  [rdi+12], edx
    mov  eax, 0x80000003
    cpuid
    mov  [rdi+16], eax
    mov  [rdi+20], ebx
    mov  [rdi+24], ecx
    mov  [rdi+28], edx
    mov  eax, 0x80000004
    cpuid
    mov  [rdi+32], eax
    mov  [rdi+36], ebx
    mov  [rdi+40], ecx
    mov  [rdi+44], edx
    mov  byte [rdi+48], 0
    lea  rax, [rawbuf+6000]
    ret

getip:
    push rbp
    mov eax, 41
    mov edi, 2
    mov esi, 2
    xor edx, edx
    syscall
    test eax, eax
    js .fail
    mov ebx, eax
    mov eax, 42
    mov edi, ebx
    lea rsi, [saddr]
    mov edx, 16
    syscall
    mov eax, 51
    mov edi, ebx
    lea rsi, [saddr]
    lea rdx, [slen]
    syscall
    mov eax, 3
    mov edi, ebx
    syscall
    movzx eax, byte [saddr+4]
    call numcat
    lea rsi, [s_dot]
    call append
    movzx eax, byte [saddr+5]
    call numcat
    lea rsi, [s_dot]
    call append
    movzx eax, byte [saddr+6]
    call numcat
    lea rsi, [s_dot]
    call append
    movzx eax, byte [saddr+7]
    call numcat
    pop rbp
    ret
.fail:
    lea rsi, [unk]
    call append
    pop rbp
    ret

getdsk:
    mov eax, 137
    lea rdi, [p_root]
    lea rsi, [rawbuf+4000]
    syscall
    test eax, eax
    js .fail
    mov rax, [rawbuf+4000+16]
    sub rax, [rawbuf+4000+24]
    mov rcx, [rawbuf+4000+8]
    mul rcx
    mov rcx, 1073741824
    xor rdx, rdx
    div rcx
    call numcat
    lea rsi, [s_gb]
    call append
    lea rsi, [s_sep]
    call append
    mov rax, [rawbuf+4000+16]
    mov rcx, [rawbuf+4000+8]
    mul rcx
    mov rcx, 1073741824
    xor rdx, rdx
    div rcx
    call numcat
    lea rsi, [s_gb]
    call append
    ret
.fail:
    lea rsi, [unk]
    call append
    ret

getpkg:
    mov eax, 2
    lea rdi, [p_pac]
    xor esi, esi
    xor edx, edx
    syscall
    test eax, eax
    js .dpkg
    jmp .cnt
.dpkg:
    mov eax, 2
    lea rdi, [p_dpkg]
    xor esi, esi
    xor edx, edx
    syscall
    test eax, eax
    js .fail
.cnt:
    mov ebx, eax
    xor r12, r12
.rd:
    mov eax, 217
    mov edi, ebx
    lea rsi, [rawbuf+2000]
    mov edx, 2000
    syscall
    test eax, eax
    jle .fin
    mov r8, rax
    xor r9, r9
.prs:
    cmp r9, r8
    jge .rd
    movzx rcx, word [rawbuf+2000+r9+16]
    inc r12
    add r9, rcx
    jmp .prs
.fin:
    mov eax, 3
    mov edi, ebx
    syscall
    sub r12, 2
    mov rax, r12
    call numcat
    ret
.fail:
    lea rsi, [unk]
    call append
    ret

envprt:
    call getenv
    test rax, rax
    jz .unk
    mov rsi, rax
    call append
    ret
.unk:
    lea rsi, [unk]
    call append
    ret

flush:
    mov  eax, 1
    mov  edi, 1
    lea  rsi, [outbuf]
    mov  rdx, [outpos]
    syscall
    ret

_start:
    mov  rcx, [rsp]
    lea  r12, [rsp + rcx*8 + 16]
    mov  [envptr], r12
    xor  eax, eax
    mov  [outpos], rax
    mov  eax, 63
    lea  rdi, [un]
    syscall
    call memparse

    ; header
    lea  rsi, [e_usr]
    call getenv
    test rax, rax
    jz   .nousr
    mov  rsi, rax
    call append
.nousr:
    lea  rsi, [s_at]
    call append
    lea  rsi, [un+65]
    call append
    call crnl
    lea  rsi, [s_dash]
    call append

    ; os
    lea  rsi, [l_os]
    call append
    call osname
    call crnl

    ; host
    lea  rsi, [l_host]
    call append
    lea  rdi, [p_host]
    call sysfsr
    call crnl

    ; kernel
    lea  rsi, [l_ker]
    call append
    lea  rsi, [un+130]
    call append
    call crnl

    ; uptime
    lea  rsi, [l_up]
    call append
    lea  rdi, [p_upt]
    call slurp
    test rax, rax
    jz   .ufail
    lea  rbx, [rawbuf]
    call atoi
    xor  edx, edx
    mov  ecx, 60
    div  rcx
    call numcat
    lea  rsi, [s_min]
    call append
    jmp  .udone
.ufail:
    lea  rsi, [unk]
    call append
.udone:
    call crnl

    ; packages
    lea  rsi, [l_pkg]
    call append
    call getpkg
    call crnl

    ; shell
    lea  rsi, [l_sh]
    call append
    lea  rsi, [e_sh]
    call envprt
    call crnl

    ; de
    lea  rsi, [l_de]
    call append
    lea  rsi, [e_de]
    call envprt
    call crnl

    ; wm
    lea  rsi, [l_wm]
    call append
    lea  rsi, [e_wm]
    call envprt
    call crnl

    ; terminal
    lea  rsi, [l_term]
    call append
    lea  rsi, [e_term]
    call envprt
    call crnl

    ; cpu
    lea  rsi, [l_cpu]
    call append
    call getcpu
    mov  rsi, rax
    call append
    call crnl

    ; gpu
    lea  rsi, [l_gpu]
    call append
    lea  rdi, [p_gpuv]
    call sysfsr
    lea  rsi, [s_col]
    call append
    lea  rdi, [p_gpud]
    call sysfsr
    call crnl

    ; ram
    lea  rsi, [l_ram]
    call append
    mov  rax, [memt]
    sub  rax, [mema]
    xor  edx, edx
    mov  ecx, 1024
    div  rcx
    call numcat
    lea  rsi, [s_sep]
    call append
    mov  rax, [memt]
    xor  edx, edx
    mov  ecx, 1024
    div  rcx
    call numcat
    lea  rsi, [s_mb]
    call append
    call crnl

    ; swap
    lea  rsi, [l_swp]
    call append
    mov  rax, [swpt]
    mov  rdx, [swpf]
    cmp  rax, rdx
    jae  .safe
    xor  rax, rax
    xor  rdx, rdx
.safe:
    sub  rax, rdx
    xor  edx, edx
    mov  ecx, 1024
    div  rcx
    call numcat
    lea  rsi, [s_sep]
    call append
    mov  rax, [swpt]
    xor  edx, edx
    mov  ecx, 1024
    div  rcx
    call numcat
    lea  rsi, [s_mb]
    call append
    call crnl

    ; disk
    lea  rsi, [l_dsk]
    call append
    call getdsk
    call crnl

    ; ip
    lea  rsi, [l_ip]
    call append
    call getip
    call crnl

    ; locale
    lea  rsi, [l_loc]
    call append
    lea  rsi, [e_loc]
    call envprt
    call crnl

    call flush

quit:
    xor  edi, edi
    mov  eax, 60
    syscall
