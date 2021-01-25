#!/bin/bash
riscv64-unknown-elf-as -march=rv32ic $1 -o rom.o
riscv64-unknown-elf-objcopy -O binary -j .text rom.o ../rom/rom.bin
rm rom.o