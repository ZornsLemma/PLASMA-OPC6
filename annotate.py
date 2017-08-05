import sys
with open(sys.argv[1], 'r') as f:
    i = 0
    for i, line in enumerate(f):
        line = line.strip()
        print("%04x: %s" % (i * 16, line))
