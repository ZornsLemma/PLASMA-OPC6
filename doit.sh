#!/bin/bash
set -e
~/src/PLASMA/src/plasm -AO < "$1" > compiled.a
cat plasma.s > merged.s
python convert.py < compiled.a >> merged.s
echo -e '\tALIGN' >> merged.s
echo 'heap_start:' >> merged.s
python opc6byteasm.py merged.s merged.o
python opc6emu.py merged.o mem
