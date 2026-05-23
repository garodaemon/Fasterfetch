default rel
global _start

%macro PRT 1
    lea rsi, [%1]
    call append
%endmacro

%macro ENV 2
    PRT %1
    lea rsi, [%2]
    call envprt
    call crnl
%endmacro

%macro SYS 2
    PRT %1
    lea rdi, [%2]
    call sysfsr
    call crnl
%endmacro

%macro IPOCT 1
    movzx eax, byte [saddr+%1]
    call numcat
    PRT s_dot
%endmacro

%macro GPU 2
    db %1, 0, %2, 0
%endmacro

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

    gpudb:
        GPU "0x15ad:0x0405", "VirtualBox Graphics Adapter"
        GPU "0x10de:0x1b82", "NVIDIA GTX 1070 Ti"
        GPU "0x10de:0x1b87", "NVIDIA GTX 1070 Ti"
        GPU "0x10de:0x1b80", "NVIDIA GTX 1080"
        GPU "0x10de:0x1b06", "NVIDIA GTX 1080 Ti"
        GPU "0x10de:0x1f08", "NVIDIA RTX 2060"
        GPU "0x10de:0x1e89", "NVIDIA RTX 2060"
        GPU "0x10de:0x1f02", "NVIDIA RTX 2070"
        GPU "0x10de:0x1e84", "NVIDIA RTX 2070"
        GPU "0x10de:0x1e82", "NVIDIA RTX 2080"
        GPU "0x10de:0x1e87", "NVIDIA RTX 2080"
        GPU "0x10de:0x1e04", "NVIDIA RTX 2080 Ti"
        GPU "0x10de:0x1e07", "NVIDIA RTX 2080 Ti"
        GPU "0x10de:0x2507", "NVIDIA RTX 3050"
        GPU "0x10de:0x2582", "NVIDIA RTX 3050"
        GPU "0x10de:0x2503", "NVIDIA RTX 3060"
        GPU "0x10de:0x2504", "NVIDIA RTX 3060"
        GPU "0x10de:0x2486", "NVIDIA RTX 3060 Ti"
        GPU "0x10de:0x2489", "NVIDIA RTX 3060 Ti"
        GPU "0x10de:0x2484", "NVIDIA RTX 3070"
        GPU "0x10de:0x2488", "NVIDIA RTX 3070"
        GPU "0x10de:0x2482", "NVIDIA RTX 3070 Ti"
        GPU "0x10de:0x2206", "NVIDIA RTX 3080"
        GPU "0x10de:0x2216", "NVIDIA RTX 3080"
        GPU "0x10de:0x2208", "NVIDIA RTX 3080 Ti"
        GPU "0x10de:0x2204", "NVIDIA RTX 3090"
        GPU "0x10de:0x2203", "NVIDIA RTX 3090 Ti"
        GPU "0x10de:0x2882", "NVIDIA RTX 4060"
        GPU "0x10de:0x2803", "NVIDIA RTX 4060 Ti"
        GPU "0x10de:0x2786", "NVIDIA RTX 4070"
        GPU "0x10de:0x2782", "NVIDIA RTX 4070 Ti"
        GPU "0x10de:0x2704", "NVIDIA RTX 4080"
        GPU "0x10de:0x2684", "NVIDIA RTX 4090"
        GPU "0x1002:0x67df", "AMD Radeon RX 580"
        GPU "0x1002:0x7340", "AMD Radeon RX 5500 XT"
        GPU "0x1002:0x731f", "AMD Radeon RX 5700 XT"
        GPU "0x1002:0x73ff", "AMD Radeon RX 6600"
        GPU "0x1002:0x73ef", "AMD Radeon RX 6600 XT"
        GPU "0x1002:0x73df", "AMD Radeon RX 6700 XT"
        db 0

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
apploop:
    movzx ecx, byte [rsi]
    test  ecx, ecx
    jz    appdone
    cmp   rbx, 4090
    jl    appok
    push  rax
    push  rdi
    push  rsi
    push  rdx
    mov   eax, 1
    mov   edi, 1
    lea   rsi, [outbuf]
    mov   rdx, rbx
    syscall
    pop   rdx
    pop   rsi
    pop   rdi
    pop   rax
    xor   rbx, rbx
appok:
    mov   [outbuf+rbx], cl
    inc   rsi
    inc   rbx
    jmp   apploop
appdone:
    mov   [outpos], rbx
    pop   rcx
    pop   rbx
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
    push r8
    lea  rcx, [rawbuf+7900]
    mov  byte [rcx], 0
    mov  r8, 0xCCCCCCCCCCCCCCCD
numloop:
    mov  rbx, rax
    mul  r8
    shr  rdx, 3
    mov  rax, rdx
    lea  rdx, [rdx + rdx*4]
    add  rdx, rdx
    sub  rbx, rdx
    add  bl, '0'
    dec  rcx
    mov  [rcx], bl
    test rax, rax
    jnz  numloop
    lea  rsi, [rcx]
    call append
    pop  r8
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
    js   slperr
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
slperr:
    xor  eax, eax
    pop  rbx
    ret

skipws:
    movzx ecx, byte [rbx]
    cmp   ecx, 32
    je    skpspc
    cmp   ecx, 9
    je    skpspc
    ret
skpspc:
    inc   rbx
    jmp   skipws

atoi:
    xor  eax, eax
atloop:
    movzx edx, byte [rbx]
    sub   edx, '0'
    js    atdone
    cmp   edx, 9
    jg    atdone
    imul  rax, rax, 10
    add   eax, edx
    inc   rbx
    jmp   atloop
atdone:
    ret

cmpn:
    push rsi
    push rdi
    push rcx
cmploop:
    test  rcx, rcx
    jz    cmpok
    movzx r8d, byte [rsi]
    movzx r9d, byte [rdi]
    cmp   r8d, r9d
    jne   cmpno
    inc   rsi
    inc   rdi
    dec   rcx
    jmp   cmploop
cmpok:
    xor  eax, eax
    pop  rcx
    pop  rdi
    pop  rsi
    ret
cmpno:
    mov  eax, 1
    pop  rcx
    pop  rdi
    pop  rsi
    ret

getenv:
    mov r8, [envptr]
envloop:
    mov rdi, [r8]
    test rdi, rdi
    jz enverr
    push rsi
    push rdi
envchk:
    movzx eax, byte [rsi]
    test eax, eax
    jz envok
    movzx ebx, byte [rdi]
    cmp eax, ebx
    jne envnxt
    inc rsi
    inc rdi
    jmp envchk
envok:
    mov rax, rdi
    pop rdi
    pop rsi
    ret
envnxt:
    pop rdi
    pop rsi
    add r8, 8
    jmp envloop
enverr:
    xor eax, eax
    ret

sysfsr:
    call slurp
    test rax, rax
    jz syserr
    lea rbx, [rawbuf]
    add rbx, rax
    dec rbx
    cmp byte [rbx], 10
    jne sysprt
    mov byte [rbx], 0
sysprt:
    PRT rawbuf
    ret
syserr:
    PRT unk
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
    jz   memdone
    mov  byte [rawbuf+rax], 0
    lea  rbx, [rawbuf]
memloop:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    memdone
    lea   rsi, [k_memt]
    mov   rdi, rbx
    mov   ecx, 9
    call  cmpn
    jnz   memt2
    add   rbx, 9
    call  skipws
    call  atoi
    mov   [memt], rax
    jmp   memnl
memt2:
    lea   rsi, [k_mema]
    mov   rdi, rbx
    mov   ecx, 13
    call  cmpn
    jnz   memt3
    add   rbx, 13
    call  skipws
    call  atoi
    mov   [mema], rax
    jmp   memnl
memt3:
    lea   rsi, [k_swpt]
    mov   rdi, rbx
    mov   ecx, 9
    call  cmpn
    jnz   memt4
    add   rbx, 9
    call  skipws
    call  atoi
    mov   [swpt], rax
    jmp   memnl
memt4:
    lea   rsi, [k_swpf]
    mov   rdi, rbx
    mov   ecx, 9
    call  cmpn
    jnz   memskp
    add   rbx, 9
    call  skipws
    call  atoi
    mov   [swpf], rax
memskp:
memnl:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    memdone
    cmp   ecx, 10
    je    memnxt
    inc   rbx
    jmp   memnl
memnxt:
    inc   rbx
    jmp   memloop
memdone:
    pop  rcx
    pop  rbx
    ret

osname:
    push rbx
    push rcx
    lea  rdi, [p_os]
    call slurp
    test rax, rax
    jz   oserr
    mov  byte [rawbuf+rax], 0
    lea  rbx, [rawbuf]
osloop:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    oserr
    lea   rsi, [k_pn]
    mov   rdi, rbx
    mov   ecx, 12
    call  cmpn
    jnz   oschk
    add   rbx, 12
    movzx ecx, byte [rbx]
    cmp   ecx, 34
    jne   oscpy
    inc   rbx
oscpy:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    osdone
    cmp   ecx, 34
    je    osdone
    cmp   ecx, 10
    je    osdone
    mov   cl, byte [rbx]
    call  putch
    inc   rbx
    jmp   oscpy
osdone:
    pop  rcx
    pop  rbx
    ret
oschk:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    oserr
    cmp   ecx, 10
    je    osnxt
    inc   rbx
    jmp   oschk
osnxt:
    inc   rbx
    jmp   osloop
oserr:
    PRT unk
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
cpuskp:
    cmp  byte [rax], 32
    jne  cpudone
    inc  rax
    jmp  cpuskp
cpudone:
    ret

getip:
    push rbp
    mov eax, 41
    mov edi, 2
    mov esi, 2
    xor edx, edx
    syscall
    test eax, eax
    js iperr
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
    IPOCT 4
    IPOCT 5
    IPOCT 6
    movzx eax, byte [saddr+7]
    call numcat
    pop rbp
    ret
iperr:
    PRT unk
    pop rbp
    ret

getdsk:
    mov eax, 137
    lea rdi, [p_root]
    lea rsi, [rawbuf+4000]
    syscall
    test eax, eax
    js dskerr
    mov rax, [rawbuf+4016]
    sub rax, [rawbuf+4024]
    mov rcx, [rawbuf+4008]
    mul rcx
    shr rax, 30
    call numcat
    PRT s_gb
    PRT s_sep
    mov rax, [rawbuf+4016]
    mov rcx, [rawbuf+4008]
    mul rcx
    shr rax, 30
    call numcat
    PRT s_gb
    ret
dskerr:
    PRT unk
    ret

getpkg:
    mov eax, 2
    lea rdi, [p_pac]
    xor esi, esi
    xor edx, edx
    syscall
    test eax, eax
    js pkgdpkg
    jmp pkgcnt
pkgdpkg:
    mov eax, 2
    lea rdi, [p_dpkg]
    xor esi, esi
    xor edx, edx
    syscall
    test eax, eax
    js pkgerr
pkgcnt:
    mov ebx, eax
    xor r12, r12
pkgrd:
    mov eax, 217
    mov edi, ebx
    lea rsi, [rawbuf+2000]
    mov edx, 2000
    syscall
    test eax, eax
    jle pkgdone
    mov r8, rax
    xor r9, r9
pkgprs:
    cmp r9, r8
    jge pkgrd
    movzx rcx, word [rawbuf+2000+r9+16]
    inc r12
    add r9, rcx
    jmp pkgprs
pkgdone:
    mov eax, 3
    mov edi, ebx
    syscall
    sub r12, 2
    mov rax, r12
    call numcat
    ret
pkgerr:
    PRT unk
    ret

getgpu:
    push rbx
    push rcx
    lea rdi, [p_gpuv]
    call slurp
    test rax, rax
    jz gperr
    mov rax, [rawbuf]
    mov [rawbuf+5000], rax
    mov byte [rawbuf+5006], ':'
    lea rdi, [p_gpud]
    call slurp
    test rax, rax
    jz gperr
    mov rax, [rawbuf]
    mov [rawbuf+5007], rax
    mov byte [rawbuf+5013], 0
    lea rbx, [gpudb]
gploop:
    movzx ecx, byte [rbx]
    test ecx, ecx
    jz gpraw
    lea rsi, [rawbuf+5000]
    mov rdi, rbx
    mov ecx, 13
    call cmpn
    test eax, eax
    jz gpmat
gpskp1:
    movzx ecx, byte [rbx]
    inc rbx
    test ecx, ecx
    jnz gpskp1
gpskp2:
    movzx ecx, byte [rbx]
    inc rbx
    test ecx, ecx
    jnz gpskp2
    jmp gploop
gpmat:
    add rbx, 14
    lea rsi, [rbx]
    call append
    pop rcx
    pop rbx
    ret
gpraw:
    lea rsi, [rawbuf+5000]
    call append
    pop rcx
    pop rbx
    ret
gperr:
    PRT unk
    pop rcx
    pop rbx
    ret

envprt:
    call getenv
    test rax, rax
    jz enverr2
    PRT rax
    ret
enverr2:
    PRT unk
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

    ; user
    lea  rsi, [e_usr]
    call getenv
    test rax, rax
    jz   stnousr
    mov  rsi, rax
    call append
stnousr:
    PRT s_at
    PRT un+65
    call crnl
    PRT s_dash

    ; os
    PRT l_os
    call osname
    call crnl

    ; host
    SYS l_host, p_host

    ; kernel
    PRT l_ker
    PRT un+130
    call crnl

    ; uptime
    PRT l_up
    lea  rdi, [p_upt]
    call slurp
    test rax, rax
    jz   stupe
    lea  rbx, [rawbuf]
    call atoi
    xor  edx, edx
    mov  ecx, 60
    div  rcx
    call numcat
    PRT s_min
    jmp  stupd
stupe:
    PRT unk
stupd:
    call crnl

    ; pkg
    PRT l_pkg
    call getpkg
    call crnl

    ; env
    ENV l_sh, e_sh
    ENV l_de, e_de
    ENV l_wm, e_wm
    ENV l_term, e_term

    ; cpu
    PRT l_cpu
    call getcpu
    mov  rsi, rax
    call append
    call crnl

    ; gpu
    PRT l_gpu
    call getgpu
    call crnl

    ; ram
    PRT l_ram
    mov  rax, [memt]
    sub  rax, [mema]
    shr  rax, 10
    call numcat
    PRT s_sep
    mov  rax, [memt]
    shr  rax, 10
    call numcat
    PRT s_mb
    call crnl

    ; swap
    PRT l_swp
    mov  rax, [swpt]
    mov  rdx, [swpf]
    xor  rbx, rbx
    cmp  rax, rdx
    cmovb rax, rbx
    cmovb rdx, rbx
    sub  rax, rdx
    shr  rax, 10
    call numcat
    PRT s_sep
    mov  rax, [swpt]
    shr  rax, 10
    call numcat
    PRT s_mb
    call crnl

    ; disk
    PRT l_dsk
    call getdsk
    call crnl

    ; ip
    PRT l_ip
    call getip
    call crnl

    ; locale
    ENV l_loc, e_loc

    call flush

quit:
    xor  edi, edi
    mov  eax, 60
    syscall
