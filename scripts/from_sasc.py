import sys
from collections import defaultdict

lines = open(sys.argv[1],'r')
line = lines.readline().strip()
assert line == 'digraph g {'

children = defaultdict(list) # mapping from parent -> child
label = {} # "" node -> label
for line in lines :
    line = line.strip()

    if line == '}' :
        continue

    if line == 'labelloc="t";' :
        continue

    if line.startswith('label="Confidence score:') :
        continue

    assert line[-1] == ';'
    line = line[:-1]

    if '->' in line : # parent x -> child y
        x, _, y = line.split()
        x = int(x.strip('"'))
        y = int(y.strip('"'))

        children[x].append(y)

    else :
        assert 'label=' in line, line # node -> label        

        x, *_, y = line.split()
        x = int(x.strip('"'))
        y = y.split('=')[1].strip(']').strip('"')

        if x == 0 :
            assert y == 'germline'
            y = -100000

        y = int(y)

        if 'color=indianred1' in line : # it's a loss node
            y = -y

        label[x] = y

assert line == '}'

for x in label :
    print('>', label[x], sep = '')

    for child in children[x] :
        if child in label :
            print(label[child])
