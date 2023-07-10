import sys

lines = open(sys.argv[1],'r')

line = lines.readline().strip()
assert line == 'digraph G {'

line = lines.readline().strip()
assert line == 'node [color=deeppink4, style=filled, fontcolor=white];'

children = {} # mapping from parent -> child
label = {} # "" node -> label
for line in lines :
    line = line.strip()

    if line == '}' :
        continue

    assert line[-1] == ';'
    line = line[:-1]

    assert '->' in line, line # parent x -> child y
    x, _, y = line.split()

    if x == 'Root' :
        x = -1

    x = int(x)
    y = int(y)

    if not x in children :
        children[x] = set()
    if not y in children :
        children[y] = set()

    children[x].add(y)

assert line == '}'

for x in children :
    print('>', x, sep = '')

    for child in children[x] :
        print(child)
