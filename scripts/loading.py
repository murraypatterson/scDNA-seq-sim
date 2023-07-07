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
