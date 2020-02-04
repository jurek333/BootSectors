@echo off

echo Build...
nasm -f bin -o selfie.img selfie.asm

IF "%1" == "run" GOTO run
goto:eof

:run
    echo Run...
    qemu-system-i386.exe -drive format=raw,file=selfie.img
    goto:eof