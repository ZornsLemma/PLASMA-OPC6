import sys

def is_label_type(label, prefix):
    # TODO: This should perhaps check the label is of the form _prefixn* but
    # let's just do this for now.
    return len(label) >= 3 and label[0:2] == '_' + prefix

for line in sys.stdin:
    c = line[:-1].split('\t')

    if len(c) >= 2:
        if c[1] == 'JMP':
            c[1] = 'mov pc, r0,'
        elif c[1] == 'JSR':
            c[1] = 'jsr ripw, r0, interp'
            del c[2:]
        elif c[1] == '!BYTE':
            c[1] = 'UBYTE'
        elif c[1] == '!WORD':
            c[1] = 'UWORD'
        elif c[1] == '=':
            assert len(c) == 3
            c = ['', 'EQU ' + c[0] + ', ' + c[2]]
        elif c[1] == '!FILL':
            c[1] = 'UBYTE'
            count = int(c[2])
            c[2] = ''
            for i in range(count):
                c[2] += '0x00,'
            c[2] = c[2][:-1]

    if len(c) >= 3:
        c[2] = c[2].replace('$', '0x')
        c[2] = c[2].replace('*', '_BPC_')

    if len(c) >= 1:
        c[0] = c[0].strip()
        if c[0] == '_INIT' or is_label_type(c[0], 'C'):
            print '\tALIGN'
            c[0] = c[0].strip() + ':'
        # TODO: 'D' labels allocate data and therefore they need to be "saved
        # up" and put into the actual plasma_data area with their values set to
        # their address within the plasma_data area. What we're currently doing
        # is nonsense, though we get away with it.
        elif is_label_type(c[0], 'B') or is_label_type(c[0], 'D') or is_label_type(c[0], 'F'):
            c[0] = c[0].strip() + ':B'

    s = '\t'.join(c)
    s = s.replace(';', '#')
    print s
