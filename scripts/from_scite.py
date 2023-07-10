import sys
from collections import defaultdict

lines = open(sys.argv[1],'r')

line = lines.readline().strip()
assert line == 'digraph G {'

line = lines.readline().strip()
assert line == 'node [color=deeppink4, style=filled, fontcolor=white];'

children = defaultdict(list) # mapping from parent -> child
label = {} # "" node -> label
for line in lines :
    line = line.strip()

    if line == '}' :
        continue

    assert line[-1] == ';'
    line = line[:-1]

    assert '->' in line # parent x -> child y
    print(line,file=sys.stderr)
    x, _, y = line.split()

    if x == 'Root' :
        continue

    x = int(x)
    y = int(y)

    children[x].append(y)

assert line == '}'

for x in children :
    print('>', x, sep = '')

    for child in children[x] :
        print(child)
