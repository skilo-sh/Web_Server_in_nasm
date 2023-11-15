# A simple web server in x86\_64 nasm

## Build
```console
nasm -f elf64 main.asm -o main.o
ld main.o -o main.out
```
