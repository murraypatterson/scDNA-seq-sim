import sys
from loading import get_tree

print('digraph g {')

# tree
t = get_tree(open(sys.argv[1],'r'))
for u in t.traverse('postorder') :
    if u.name == '0' :
        continue

    print('  "{}" -> "{}";'.format(u.up.name, u.name))

# labels
for line in open(sys.argv[2],'r') :
    a, *bs = line.split()

    print('  "{}" [label="{}"];'.format(a, ','.join(str(b) for b in bs)))

print('}')
