Fasterfetch



Fasterfetch is a lightweight and blazing fast system information tool written in pure assembly. 



The project aims to provide a system fetch tool that is significantly faster, lighter, and adheres to the suckless philosophy more strictly than existing alternatives like fastfetch. By stripping away shell script dependencies and unnecessary bloat, we achieve near-instant execution times.



## Why Fasterfetch?



- **Pure Assembly:** No shell script overhead, no heavy dependencies. The code is optimized for performance at the lowest level.

- **Extreme Speed:** Because it's written in assembly, it interacts directly with the system and avoids the slow initialization times of interpreted languages or shell wrappers.

- **Suckless Philosophy:** We prioritize minimalism, efficiency, and clarity. If it isn't absolutely necessary for showing system information, it isn't in the code.

- **Lightweight:** Designed to be the smallest and fastest way to display your system specs.



## Current Status



Fasterfetch is currently optimized for Arch and Debian-based distributions. We are constantly working to improve stability and portability.



## Installation



To run Fasterfetch, simply execute the binary in the installed directory or compile it yourself with NASM!



Contributing

We are actively working on removing all remaining shell script remnants. If you are familiar with assembly and want to help us push the boundaries of system performance, feel free to submit a pull request.

Please note that we have not yet tested Fasterfetch on all distributions, so feedback and testing are highly appreciated.

