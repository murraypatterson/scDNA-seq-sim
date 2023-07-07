import sys
from loading import get_tree, get_profiles

n = 20 # number of nodes in the tree
m = 10 # number of bins
k = 1 # number of new mutations in a step

t = get_tree(open(sys.argv[1],'r'))
p = get_profiles(open(sys.argv[2],'r'))

# profile at the root (the germline)
c = p[t.name]
assert len(c) == m
for b in c :
    assert len(b) == 2 # two copies (diploid)

    for a in b :
        assert len(a) == 1 # could be customized

c = [x for xss in c for xs in xss for x in xs] # collapse
sc = set(c)
assert len(sc) == len(c), sc # all mutations are unique

# check for relationships between profiles and their parents
q = {} # for storing the "new" bins (containing only the new mutations)
q['0'] = sc
for u in t.traverse('postorder') :
    if u.name == '0' :
        continue

    v = u.up
    i = int(u.name)
    assert i > 0 and i < n # number of nodes is n
    assert i > int(v.name) # child index is higher than parent

    c = p[u.name]
    assert len(c) == m # number of bins is m
    newc = []
    for j in range(m) :
        bu = c[j] # bin of node u
        bv = p[v.name][j] # bin of parent v

        if not bv : # you can't get something from nothing
            assert not bu, '{} -> {}'.format(bv, bu)

        newb = [] # "new" bin: for only the new mutations
        for a in bu :
            assert len(a) > 1 # allele cannot be empty (a bin may be)
            
            s = set(a)
            assert len(s) == len(a), a # all mutations are unique

            newa = [] # "new" allele (with only the new mutations)
            for av in bv :
                sv = set(av)

                if sv.issubset(s) :
                    newa = list(s - sv)
                    assert len(newa) == k, '{} \ {}'.format(s,sv) # no. new muts. = k

                    break

            assert newa # we found a source
            newb.append(newa)

        newc.append(newb)

    assert len(newc) == m # number of bins is the same
    newc = [x for xss in newc for xs in xss for x in xs] # collapse
    news = set(newc)
    assert len(news) == len(newc), newc # all new mutations are unique
    q[u.name] = news

# now check that all sets of "new" bins are disjoint for any pair of nodes
for i in range(n) :
    si = str(i)

    for j in range(i) :
        sj = str(j)

        assert not q[si] & q[sj], q[si] & q[sj]
