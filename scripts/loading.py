from ete3 import Tree
import ast

# obtain tree from file handle h
def get_tree(h) :

    t = Tree(name='0')
    for line in h :
        line = line.strip()

        for x in ["'",'"',','] :
            line = line.replace(x, ' ')

        s = line.split()

        p = t.search_nodes(name=s[0])[0]
        for c in s[1:] :
            p.add_child(name=c)

    return t

# obtain node profiles from file handle h
def get_profiles(h, m = None) :

    p = {}
    i = 0
    for line in h :
        line = line.strip()

        line = line.replace('"','')
        s = list(ast.literal_eval(line))

        if m :
            s = s[:m]

        p[str(i)] = s

        i += 1

    return p

# build on tree t from some node given a parent -> children mapping
def build_tree(node, t, children) :

    parent = t.search_nodes(name=node)[0]
    for child in children[int(parent.name)] :
        child = str(child)

        parent.add_child(name=child)
        build_tree(child, t, children)

# obtain inferred tree and clones from file handle h
def get_inferred(h) :

    c = {} # structure of the tree from file
    p = None
    for line in h :
        line = line.strip()

        if line.startswith('>') :
            p = line[1:]
            c[p] = set()

            continue

        c[p].add(line)

    en = {x : i for i,x in enumerate(c)} # enumerate nodes
    cs = {en[y] : set(int(x) for x in y.split(',')) for y in en} # inferred clones

    children = {} # children of a node (in numerical form)
    for p in c :
        children[en[p]] = set(en[x] for x in c[p])

    nodes = set(children) # find the root
    for node in children :
        nodes -= children[node]

    assert len(nodes) == 1, nodes
    root = str(list(nodes)[0])

    t = Tree(name=root) # build inferred tree from its root
    build_tree(root, t, children)

    nodes = set(int(node.name) for node in t.traverse('postorder'))
    assert len(set(cs) - nodes) == 0, set(cs) - nodes
    diff = nodes - set(cs)

    return t, cs, diff
