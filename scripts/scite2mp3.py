import sys

h = open(sys.argv[1],'r')

line = h.readline().strip()
assert line == 'digraph G {'
print(line)

line = h.readline().strip()
assert line == 'node [color=deeppink4, style=filled, fontcolor=white];'

for line in h :
    line = line.strip().rstrip(';')

    if line == '}' :
        print(line)
        continue

    u, _, v = line.split()

    if u != 'Root' :
        print('  "{}" [label="{}"];'.format(u,u))

    print('  "{}" -> "{}";'.format(u,v))
