@echo off

echo Build...
nasm -f bin -o prank.img prank.asm

IF "%1" == "run" GOTO run
goto:eof

:run
    echo Run...
    qemu-system-i386.exe -drive format=raw,file=prank.img
    goto:eof
