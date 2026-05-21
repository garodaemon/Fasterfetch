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
    l_font  db "Font:       ", 0
    l_icn   db "Icons:      ", 0
    l_cpu   db "CPU:        ", 0
    l_gpu   db "GPU:        ", 0
    l_ram   db "Memory:     ", 0
    l_swp   db "Swap:       ", 0
    l_dsk   db "Disk:       ", 0
    l_ip    db "Local IP:   ", 0
    l_loc   db "Locale:     ", 0

    s_at    db "@", 0
    s_mb    db " MB", 0
    s_sep   db " / ", 0
    s_min   db " mins", 0
    s_dash  db "-----------------", 10, 0
    nl      db 10, 0
    unk     db "n/a", 0

    p_os    db "/etc/os-release", 0
    p_mem   db "/proc/meminfo", 0
    p_upt   db "/proc/uptime", 0

    k_memt  db "MemTotal:", 0
    k_mema  db "MemAvailable:", 0
    k_swpt  db "SwapTotal:", 0
    k_swpf  db "SwapFree:", 0
    k_pn    db "PRETTY_NAME=", 0

    sh      db "/bin/sh", 0
    flg     db "-c", 0

    c_usr   db "echo $USER", 0
    c_gpu   db "lspci 2>/dev/null | grep -i vga | cut -d: -f3 | sed 's/^ *//'", 0
    c_dsk   db "df -h / 2>/dev/null | awk 'NR==2{print $3 ", 34, " / ", 34, " $2}'", 0
    c_fnt   db "fc-match 2>/dev/null | awk '{print $1}' | tr -d ':'", 0
    c_icn   db "find /usr/share/icons -maxdepth 1 -type d 2>/dev/null | tail -1 | xargs basename", 0
    c_pkg   db "if command -v rpm >/dev/null 2>&1; then rpm -qa; elif command -v pacman >/dev/null 2>&1; then pacman -Qq; elif command -v dpkg >/dev/null 2>&1; then dpkg-query -f '.\n' -W; else ls -d /var/db/pkg/*/*; fi 2>/dev/null | wc -l", 0
    c_ip    db "ip r get 1.1.1.1 2>/dev/null | awk '{print $7}'", 0
    c_sh    db "echo $SHELL", 0
    c_de    db "echo ${XDG_CURRENT_DESKTOP:-n/a}", 0
    c_wm    db "echo ${XDG_SESSION_DESKTOP:-${DESKTOP_SESSION:-n/a}}", 0
    c_term  db "echo $TERM", 0
    c_loc   db "echo $LANG", 0

    a_usr   dq sh, flg, c_usr, 0
    a_gpu   dq sh, flg, c_gpu, 0
    a_dsk   dq sh, flg, c_dsk, 0
    a_fnt   dq sh, flg, c_fnt, 0
    a_icn   dq sh, flg, c_icn, 0
    a_pkg   dq sh, flg, c_pkg, 0
    a_ip    dq sh, flg, c_ip, 0
    a_sh    dq sh, flg, c_sh, 0
    a_de    dq sh, flg, c_de, 0
    a_wm    dq sh, flg, c_wm, 0
    a_term  dq sh, flg, c_term, 0
    a_loc   dq sh, flg, c_loc, 0

section .bss
    rawbuf  resb 8192
    outbuf  resb 4096
    xbuf    resb 1024
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
.loop:
    movzx ecx, byte [rsi]
    test  ecx, ecx
    jz    .end
    mov   [outbuf+rbx], cl
    inc   rsi
    inc   rbx
    jmp   .loop
.end:
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
    ; open
    push rbx
    mov  eax, 2
    xor  esi, esi
    xor  edx, edx
    syscall
    test rax, rax
    js   .err
    mov  rbx, rax
    ; read
    xor  eax, eax
    mov  edi, ebx
    lea  rsi, [rawbuf]
    mov  edx, 8191
    syscall
    push rax
    ; close
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
    js    .end
    cmp   edx, 9
    jg    .end
    imul  rax, rax, 10
    add   eax, edx
    inc   rbx
    jmp   .d
.end:
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

memparse:
    push rbx
    push rcx
    ; zero
    xor  rax, rax
    mov  [memt], rax
    mov  [mema], rax
    mov  [swpt], rax
    mov  [swpf], rax
    lea  rdi, [p_mem]
    call slurp
    test rax, rax
    jz   .done
    mov  byte [rawbuf+rax], 0
    lea  rbx, [rawbuf]
.scan:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    .done
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
    jnz   .skip
    add   rbx, 9
    call  skipws
    call  atoi
    mov   [swpf], rax
.skip:
.nl:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    .done
    cmp   ecx, 10
    je    .step
    inc   rbx
    jmp   .nl
.step:
    inc   rbx
    jmp   .scan
.done:
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
.scan:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    .fail
    lea   rsi, [k_pn]
    mov   rdi, rbx
    mov   ecx, 12
    call  cmpn
    jnz   .next
    add   rbx, 12
    movzx ecx, byte [rbx]
    cmp   ecx, 34
    jne   .copy
    inc   rbx
.copy:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    .end
    cmp   ecx, 34
    je    .end
    cmp   ecx, 10
    je    .end
    mov   cl, byte [rbx]
    call  putch
    inc   rbx
    jmp   .copy
.end:
    pop  rcx
    pop  rbx
    ret
.next:
    movzx ecx, byte [rbx]
    test  ecx, ecx
    jz    .fail
    cmp   ecx, 10
    je    .step
    inc   rbx
    jmp   .next
.step:
    inc   rbx
    jmp   .scan
.fail:
    lea  rsi, [unk]
    call append
    pop  rcx
    pop  rbx
    ret

exec:
    ; pipe
    push rdi
    sub  rsp, 8
    mov  rdi, rsp
    mov  eax, 22
    syscall
    ; fork
    mov  eax, 57
    syscall
    test rax, rax
    jz   child
    ; close
    mov  eax, 3
    mov  edi, dword [rsp+4]
    syscall
    ; read
    xor  eax, eax
    mov  edi, dword [rsp]
    lea  rsi, [xbuf]
    mov  edx, 1023
    syscall
    mov  r8, rax
    ; reap
    mov  eax, 61
    mov  edi, -1
    xor  esi, esi
    xor  edx, edx
    xor  r10d, r10d
    syscall
    ; close
    mov  eax, 3
    mov  edi, dword [rsp]
    syscall
    test r8, r8
    jle  xfail
    lea  rbx, [xbuf]
    mov  byte [rbx+r8], 0
rtrim:
    test  r8, r8
    jle   xfail
    movzx ecx, byte [rbx+r8-1]
    cmp   ecx, 10
    je    rstrip
    cmp   ecx, 32
    je    rstrip
    cmp   ecx, 13
    je    rstrip
    jmp   xdone
rstrip:
    mov  byte [rbx+r8-1], 0
    dec  r8
    jmp  rtrim
xdone:
    lea  rax, [xbuf]
    add  rsp, 16
    ret
xfail:
    lea  rax, [unk]
    add  rsp, 16
    ret
child:
    ; redirect
    mov  eax, 33
    mov  edi, dword [rsp+4]
    mov  esi, 1
    syscall
    ; close
    mov  eax, 3
    mov  edi, dword [rsp]
    syscall
    ; execve
    mov  rsi, [rsp+8]
    lea  rdi, [sh]
    mov  rdx, [envptr]
    mov  eax, 59
    syscall
    ; exit
    xor  edi, edi
    mov  eax, 60
    syscall

xcat:
    call exec
    mov  rsi, rax
    call append
    ret

getcpu:
    ; cpuid
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

flush:
    ; write
    mov  eax, 1
    mov  edi, 1
    lea  rsi, [outbuf]
    mov  rdx, [outpos]
    syscall
    ret

_start:
    ; init
    mov  rcx, [rsp]
    lea  r12, [rsp + rcx*8 + 16]
    mov  [envptr], r12
    xor  eax, eax
    mov  [outpos], rax

    ; uname
    mov  eax, 63
    lea  rdi, [un]
    syscall

    ; parse
    call memparse

    ; header
    lea  rdi, [a_usr]
    call xcat
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
    lea  rsi, [un+65]
    call append
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
    lea  rdi, [a_pkg]
    call xcat
    call crnl

    ; shell
    lea  rsi, [l_sh]
    call append
    lea  rdi, [a_sh]
    call xcat
    call crnl

    ; de
    lea  rsi, [l_de]
    call append
    lea  rdi, [a_de]
    call xcat
    call crnl

    ; wm
    lea  rsi, [l_wm]
    call append
    lea  rdi, [a_wm]
    call xcat
    call crnl

    ; terminal
    lea  rsi, [l_term]
    call append
    lea  rdi, [a_term]
    call xcat
    call crnl

    ; font
    lea  rsi, [l_font]
    call append
    lea  rdi, [a_fnt]
    call xcat
    call crnl

    ; icons
    lea  rsi, [l_icn]
    call append
    lea  rdi, [a_icn]
    call xcat
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
    lea  rdi, [a_gpu]
    call xcat
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
    lea  rdi, [a_dsk]
    call xcat
    call crnl

    ; ip
    lea  rsi, [l_ip]
    call append
    lea  rdi, [a_ip]
    call xcat
    call crnl

    ; locale
    lea  rsi, [l_loc]
    call append
    lea  rdi, [a_loc]
    call xcat
    call crnl

    call flush

quit:
    xor  edi, edi
    mov  eax, 60
    syscall
