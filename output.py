import sys
with open(sys.argv[1], 'r') as f:
    for line in f:
        if 'OUT:' in line:
            i = line.index('Data :')
            line = line[i:]
            i = line.index('(')
            line = line[i+1:]
            i = line.index(')')
            line = line[:i]
            c = int(line)
            sys.stdout.write(chr(c))
