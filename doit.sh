#!/bin/bash
set -e
set -o pipefail
~/src/PLASMA/src/plasm -AO < "$1" > compiled.a
cat plasma.s > merged.s
echo '; Start executing compiled PLASMA code here' >> merged.s
echo 'a1cmd:' >> merged.s
python convert.py < compiled.a >> merged.s
# I don't think it will be necessary for the heap to be aligned, but it may
# be useful for optimisations if we can keep it aligned at all times. Let's
# align it for now and revisit this later.
echo -e '\tALIGN' >> merged.s
echo 'heap_start:' >> merged.s
python opc6byteasm.py merged.s merged.o | tee asmout.txt
python opc6emu.py merged.o mem | tee emuout.txt
