import sys

def is_label_type(label, prefix):
    # TODO: This should perhaps check the label is of the form _prefixn* but
    # let's just do this for now.
    return len(label) >= 3 and label[0:2] == '_' + prefix

pending_d_labels = []

in_d_label = False
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

    is_d_label = False
    if len(c) >= 1:
        c[0] = c[0].strip()
        is_d_label = is_label_type(c[0], 'D')
        if c[0] == '_INIT' or is_label_type(c[0], 'A') or is_label_type(c[0], 'C'):
            print '\tALIGN'
            c[0] = c[0].strip() + ':'
        elif is_label_type(c[0], 'B') or is_d_label or is_label_type(c[0], 'F'):
            c[0] = c[0].strip() + ':B'

    if is_d_label:
        in_d_label = True
    elif c[0]:
        in_d_label = False

    if in_d_label:
        pending_d_labels.append(c)
    else:
        s = '\t'.join(c)
        s = s.replace(';', '#')
        print s

# TODO: We might want to start this at plasma_data+0x200bytes or something like
# that, so as to leave "zero page" and the "stack page" in the data space free.
# No point wasting space, but I suspect it may be necessary/desirable to use
# "zero page" for some communication between the OPC6 machine and the PLASMA VM
# - possibly not, let's see how it goes.
print "\tORG plasma_data"
for c in pending_d_labels:
    label = None
    if c[0]:
        label = c[0]
        c[0] = '_internal' + c[0]
    s = '\t'.join(c)
    s = s.replace(';', '#')
    print s
    if label:
        assert label[-2:] == ':B'
        label = label[:-2]
        print '\tEQU ' + label + ', _internal' + label + '-2*plasma_data'
