#!/bin/bash
if [ -z "$1" ]
then
    echo "compile.sh needs an assembly source!"
else
    getmypath () {
        echo ${0%/*}/
    }
    mypath=$(getmypath)
    riscv64-unknown-elf-as -march=rv32ic $1 -o rom.o
    riscv64-unknown-elf-objcopy -O binary -j .text rom.o $mypath/../rom/rom.bin
    rm rom.o
fi