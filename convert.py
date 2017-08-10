import sys

def is_label_type(label, prefix):
    # TODO: This should perhaps check the label is of the form _prefixn* but
    # let's just do this for now.
    return len(label) >= 3 and label[0:2] == '_' + prefix

for line in sys.stdin:
    c = line[:-1].split('\t')

    if len(c) >= 2:
        if c[1] == 'JMP':
            c[1] = 'mov pc,'
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

    if len(c) >= 1:
        if c[0] == '_INIT' or is_label_type(c[0], 'C'):
            print('\tALIGN')
            c[0] = c[0].strip() + ':'
        elif is_label_type(c[0], 'B') or is_label_type(c[0], 'F'):
            c[0] = c[0].strip() + ':B'

    print '\t'.join(c)
