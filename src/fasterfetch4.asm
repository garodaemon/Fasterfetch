default rel
global _start

; Macros
%macro PRT 1
    lea rsi, [%1]
    call appnd
%endmacro

%macro CLR 1
    lea rsi, [%1]
    call appnd
%endmacro

%macro LBL 2
    CLR c_lbl
    PRT %1
    CLR c_rst
    lea rsi, [%2]
    call envprt
    call crnl
%endmacro

%macro SBL 2
    CLR c_lbl
    PRT %1
    CLR c_rst
    lea rdi, [%2]
    call sysfsr
    call crnl
%endmacro

%macro CBL 2
    CLR c_lbl
    PRT %1
    CLR c_rst
    call %2
    call crnl
%endmacro

%macro PBL 2
    CLR c_lbl
    PRT %1
    CLR c_rst
    PRT %2
    call crnl
%endmacro

%macro IPOCT 1
    movzx eax, byte [saddr+%1]
    call numcat
    PRT s_dot
%endmacro

%macro CPUID_CALL 2
    mov eax, %1
    cpuid
    mov [rdi+%2], eax
    mov [rdi+%2+4], ebx
    mov [rdi+%2+8], ecx
    mov [rdi+%2+12], edx
%endmacro

%macro MCMP 4
    lea   rsi, [%1]
    mov   rdi, rbx
    mov   ecx, %2
    call  cmpn
    jnz   %3
    add   rbx, %2
    call  skipws
    call  atoi
    mov   [%4], rax
    jmp   pnl
%endmacro

%macro GDEF 3
    dq (%1 << 16) | %2
    dq %%gstr
    section .rodata
    %%gstr db %3, 0
    __SECT__
%endmacro

section .data
    c_lbl   db 27, "[1;36m", 0
    c_rst   db 27, "[0m", 0

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

    gtable:
        GDEF 0x15ad, 0x0405, "VirtualBox Graphics Adapter"
        GDEF 0x10de, 0x25a1, "NVIDIA GeForce MX550"
        GDEF 0x10de, 0x1b82, "NVIDIA GTX 1070 Ti"
        GDEF 0x10de, 0x1b87, "NVIDIA GTX 1070 Ti"
        GDEF 0x10de, 0x1b80, "NVIDIA GTX 1080"
        GDEF 0x10de, 0x1b06, "NVIDIA GTX 1080 Ti"
        GDEF 0x10de, 0x1f08, "NVIDIA RTX 2060"
        GDEF 0x10de, 0x1e89, "NVIDIA RTX 2060"
        GDEF 0x10de, 0x1f02, "NVIDIA RTX 2070"
        GDEF 0x10de, 0x1e84, "NVIDIA RTX 2070"
        GDEF 0x10de, 0x1e82, "NVIDIA RTX 2080"
        GDEF 0x10de, 0x1e87, "NVIDIA RTX 2080"
        GDEF 0x10de, 0x1e04, "NVIDIA RTX 2080 Ti"
        GDEF 0x10de, 0x1e07, "NVIDIA RTX 2080 Ti"
        GDEF 0x10de, 0x2507, "NVIDIA RTX 3050"
        GDEF 0x10de, 0x2582, "NVIDIA RTX 3050"
        GDEF 0x10de, 0x2503, "NVIDIA RTX 3060"
        GDEF 0x10de, 0x2504, "NVIDIA RTX 3060"
        GDEF 0x10de, 0x2486, "NVIDIA RTX 3060 Ti"
        GDEF 0x10de, 0x2489, "NVIDIA RTX 3060 Ti"
        GDEF 0x10de, 0x2484, "NVIDIA RTX 3070"
        GDEF 0x10de, 0x2488, "NVIDIA RTX 3070"
        GDEF 0x10de, 0x2482, "NVIDIA RTX 3070 Ti"
        GDEF 0x10de, 0x2206, "NVIDIA RTX 3080"
        GDEF 0x10de, 0x2216, "NVIDIA RTX 3080"
        GDEF 0x10de, 0x2208, "NVIDIA RTX 3080 Ti"
        GDEF 0x10de, 0x2204, "NVIDIA RTX 3090"
        GDEF 0x10de, 0x2203, "NVIDIA RTX 3090 Ti"
        GDEF 0x10de, 0x2882, "NVIDIA RTX 4060"
        GDEF 0x10de, 0x2803, "NVIDIA RTX 4060 Ti"
        GDEF 0x10de, 0x2786, "NVIDIA RTX 4070"
        GDEF 0x10de, 0x2782, "NVIDIA RTX 4070 Ti"
        GDEF 0x10de, 0x2704, "NVIDIA RTX 4080"
        GDEF 0x10de, 0x2684, "NVIDIA RTX 4090"
        GDEF 0x1002, 0x67df, "AMD Radeon RX 580"
        GDEF 0x1002, 0x7340, "AMD Radeon RX 5500 XT"
        GDEF 0x1002, 0x731f, "AMD Radeon RX 5700 XT"
        GDEF 0x1002, 0x73ff, "AMD Radeon RX 6600"
        GDEF 0x1002, 0x73ef, "AMD Radeon RX 6600 XT"
        GDEF 0x1002, 0x73df, "AMD Radeon RX 6700 XT"
        dq 0

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

appnd:
    push rbx
    push rcx
    mov  rbx, [outpos]
aloop:
    movzx ecx, byte [rsi]
    test  ecx, ecx
    jz    adone
    cmp   rbx, 4090
    jl    aok
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
aok:
    mov   [outbuf+rbx], cl
    inc   rsi
    inc   rbx
    jmp   aloop
adone:
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
nloop:
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
    jnz  nloop
    lea  rsi, [rcx]
    call appnd
    pop  r8
    pop  rdx
    pop  rcx
    pop  rbx
    ret

slurp:
    ; Init
    push rbx
    push rcx
    mov  eax, 2
    xor  esi, esi
    xor  edx, edx
    syscall
    test eax, eax
    js   errrd
    mov  ebx, eax

    ; Read
    mov  eax, 17
    mov  edi, ebx
    lea  rsi, [rawbuf]
    mov  edx, 8191
    xor  r10, r10
    syscall

    ; Close
    push rax
    mov  eax, 3
    mov  edi, ebx
    syscall
    pop  rax
    pop  rcx
    pop  rbx
    ret
errrd:
    ; Error
    xor  eax, eax
    pop  rcx
    pop  rbx
    ret

skipws:
    movzx ecx, byte [rbx]
    cmp   ecx, 32
    je    sspc
    cmp   ecx, 9
    je    sspc
    ret
sspc:
    inc   rbx
    jmp   skipws

atoi:
    xor  eax, eax
tloop:
    movzx edx, byte [rbx]
    sub   edx, '0'
    js    tdone
    cmp   edx, 9
    jg    tdone
    imul  rax, rax, 10
    add   eax, edx
    inc   rbx
    jmp   tloop
tdone:
    ret

hex2int:
    ; Convert
    xor  eax, eax
hxloop:
    movzx edx, byte [rdi]
    test edx, edx
    jz   hxdone
    cmp  edx, 10
    je   hxdone
    cmp  edx, 'x'
    je   hxskip
    cmp  edx, 'X'
    je   hxskip
    cmp  edx, '0'
    jl   hxdone
    cmp  edx, '9'
    jle  hxnum
    cmp  edx, 'F'
    jle  hxup
    cmp  edx, 'f'
    jle  hxlow
    jmp  hxdone
hxnum:
    sub  edx, '0'
    jmp  hxadd
hxup:
    sub  edx, 'A'
    add  edx, 10
    jmp  hxadd
hxlow:
    sub  edx, 'a'
    add  edx, 10
hxadd:
    shl  eax, 4
    add  eax, edx
hxskip:
    inc  rdi
    jmp  hxloop
hxdone:
    ret

cmpn:
    push rsi
    push rdi
    push rcx
mploop:
    test  rcx, rcx
    jz    mpok
    movzx r8d, byte [rsi]
    movzx r9d, byte [rdi]
    cmp   r8d, r9d
    jne   mpno
    inc   rsi
    inc   rdi
    dec   rcx
    jmp   mploop
mpok:
    xor  eax, eax
    pop  rcx
    pop  rdi
    pop  rsi
    ret
mpno:
    mov  eax, 1
    pop  rcx
    pop  rdi
    pop  rsi
    ret

getenv:
    mov r8, [envptr]
vloop:
    mov rdi, [r8]
    test rdi, rdi
    jz   verr
    push rsi
    push rdi
vchk:
    movzx eax, byte [rsi]
    test eax, eax
    jz   vok
    movzx ebx, byte [rdi]
    cmp eax, ebx
    jne vnxt
    inc rsi
    inc rdi
    jmp vchk
vok:
    mov rax, rdi
    pop rdi
    pop rsi
    ret
vnxt:
    pop rdi
    pop rsi
    add r8, 8
    jmp vloop
verr:
    xor eax, eax
    ret

sysfsr:
    call slurp
    test rax, rax
    jz   ferr
    lea  rbx, [rawbuf]
    add  rbx, rax
    dec  rbx
    cmp  byte [rbx], 10
    jne  fprt
    mov  byte [rbx], 0
fprt:
    PRT  rawbuf
    ret
ferr:
    PRT  unk
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
    jz   pdone
    mov  byte [rawbuf+rax], 0
    lea  rbx, [rawbuf]
ploop:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    pdone
    MCMP  k_memt, 9, pt2, memt
pt2:
    MCMP  k_mema, 13, pt3, mema
pt3:
    MCMP  k_swpt, 9, pt4, swpt
pt4:
    lea   rsi, [k_swpf]
    mov   rdi, rbx
    mov   ecx, 9
    call  cmpn
    jnz   pskp
    add   rbx, 9
    call  skipws
    call  atoi
    mov   [swpf], rax
pskp:
pnl:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    pdone
    cmp   ecx, 10
    je    pnxt
    inc   rbx
    jmp   pnl
pnxt:
    inc   rbx
    jmp   ploop
pdone:
    pop  rcx
    pop  rbx
    ret

osname:
    push rbx
    push rcx
    lea  rdi, [p_os]
    call slurp
    test rax, rax
    jz   oerr
    mov  byte [rawbuf+rax], 0
    lea  rbx, [rawbuf]
oloop:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    oerr
    lea   rsi, [k_pn]
    mov   rdi, rbx
    mov   ecx, 12
    call  cmpn
    jnz   ochk
    add   rbx, 12
    movzx ecx, byte [rbx]
    cmp   ecx, 34
    jne   ocpy
    inc   rbx
ocpy:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    odone
    cmp   ecx, 34
    je    odone
    cmp   ecx, 10
    je    odone
    mov   cl, byte [rbx]
    call  putch
    inc   rbx
    jmp   ocpy
odone:
    pop  rcx
    pop  rbx
    ret
ochk:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    oerr
    cmp   ecx, 10
    je    onxt
    inc   rbx
    jmp   ochk
onxt:
    inc   rbx
    jmp   oloop
oerr:
    PRT  unk
    pop  rcx
    pop  rbx
    ret

getcpu:
    lea  rdi, [rawbuf+6000]
    CPUID_CALL 0x80000002, 0
    CPUID_CALL 0x80000003, 16
    CPUID_CALL 0x80000004, 32
    mov  byte [rdi+48], 0
    lea  rax, [rawbuf+6000]
cskp:
    cmp  byte [rax], 32
    jne  cdone
    inc  rax
    jmp  cskp
cdone:
    ret

printcpu:
    call getcpu
    mov  rsi, rax
    call appnd
    ret

getip:
    push rbp
    mov eax, 41
    mov edi, 2
    mov esi, 2
    xor edx, edx
    syscall
    test eax, eax
    js ierr
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
ierr:
    PRT unk
    pop rbp
    ret

getdsk:
    mov eax, 137
    lea rdi, [p_root]
    lea rsi, [rawbuf+4000]
    syscall
    test eax, eax
    js derr
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
derr:
    PRT unk
    ret

getpkg:
    mov eax, 2
    lea rdi, [p_pac]
    xor esi, esi
    xor edx, edx
    syscall
    test eax, eax
    js ppkg
    jmp pcnt
ppkg:
    mov eax, 2
    lea rdi, [p_dpkg]
    xor esi, esi
    xor edx, edx
    syscall
    test eax, eax
    js kerr
pcnt:
    mov ebx, eax
    xor r12, r12
krd:
    mov eax, 217
    mov edi, ebx
    lea rsi, [rawbuf+2000]
    mov edx, 2000
    syscall
    test eax, eax
    jle kdone
    mov r8, rax
    xor r9, r9
kprs:
    cmp r9, r8
    jge krd
    movzx rcx, word [rawbuf+2000+r9+16]
    inc r12
    add r9, rcx
    jmp kprs
kdone:
    mov eax, 3
    mov edi, ebx
    syscall
    sub r12, 2
    mov rax, r12
    call numcat
    ret
kerr:
    PRT unk
    ret

getgpu:
    ; Hash
    push rbx
    push rcx
    lea rdi, [p_gpuv]
    call slurp
    test rax, rax
    jz  gerr
    lea rdi, [rawbuf]
    call hex2int
    mov r8d, eax

    lea rdi, [p_gpud]
    call slurp
    test rax, rax
    jz  gerr
    lea rdi, [rawbuf]
    call hex2int
    mov r9d, eax

    shl r8d, 16
    or  r8d, r9d

    lea rbx, [gtable]
gloop:
    mov rax, [rbx]
    test rax, rax
    jz  graw
    cmp eax, r8d
    je  gmat
    add rbx, 16
    jmp gloop
gmat:
    mov rsi, [rbx+8]
    call appnd
    pop rcx
    pop rbx
    ret
graw:
    lea rdi, [p_gpuv]
    call sysfsr
    PRT s_col
    lea rdi, [p_gpud]
    call sysfsr
    pop rcx
    pop rbx
    ret
gerr:
    PRT unk
    pop rcx
    pop rbx
    ret

getup:
    lea  rdi, [p_upt]
    call slurp
    test rax, rax
    jz   upe
    lea  rbx, [rawbuf]
    call atoi
    xor  edx, edx
    mov  ecx, 60
    div  rcx
    call numcat
    PRT  s_min
    ret
upe:
    PRT  unk
    ret

getram:
    mov  rax, [memt]
    sub  rax, [mema]
    shr  rax, 10
    call numcat
    PRT  s_sep
    mov  rax, [memt]
    shr  rax, 10
    call numcat
    PRT  s_mb
    ret

getswp:
    mov  rax, [swpt]
    mov  rdx, [swpf]
    xor  rbx, rbx
    cmp  rax, rdx
    cmovb rax, rbx
    cmovb rdx, rbx
    sub  rax, rdx
    shr  rax, 10
    call numcat
    PRT  s_sep
    mov  rax, [swpt]
    shr  rax, 10
    call numcat
    PRT  s_mb
    ret

envprt:
    call getenv
    test rax, rax
    jz   eerr
    PRT rax
    ret
eerr:
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
    ; Init
    mov  rcx, [rsp]
    lea  r12, [rsp + rcx*8 + 16]
    mov  [envptr], r12
    xor  eax, eax
    mov  [outpos], rax
    mov  eax, 63
    lea  rdi, [un]
    syscall
    call memparse

    ; User
    lea  rsi, [e_usr]
    call getenv
    test rax, rax
    jz   nousr
    CLR  c_lbl
    mov  rsi, rax
    call appnd
nousr:
    PRT  s_at
    PRT  un+65
    CLR  c_rst
    call crnl
    PRT  s_dash

    ; System
    CBL  l_os, osname
    SBL  l_host, p_host
    PBL  l_ker, un+130
    CBL  l_up, getup
    CBL  l_pkg, getpkg
    
    LBL  l_sh, e_sh
    LBL  l_de, e_de
    LBL  l_wm, e_wm
    LBL  l_term, e_term
    
    CBL  l_cpu, printcpu
    CBL  l_gpu, getgpu
    CBL  l_ram, getram
    CBL  l_swp, getswp
    CBL  l_dsk, getdsk
    CBL  l_ip, getip
    
    LBL  l_loc, e_loc

    call flush

quit:
    xor  edi, edi
    mov  eax, 60
    syscall
