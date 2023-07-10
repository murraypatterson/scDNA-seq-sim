import sys
import loading
from ete3 import Tree

# build set of pairs of nodes in an ancestor-descendant relationship
# in tree t with nodes {0..n-1} (note that the set of pairs of nodes
# in a different lineage relationship is complementary)
def build_ad(t, n) :

    ad = set() # set of pairs of nodes
    for i in range(n) :
        si = str(i)
        ad.add((i,i)) # by definition

        for j in range(i+1,n) :
            sj = str(j)

            a = t.get_common_ancestor(si,sj).name
            if a == si or a == sj :
                ad.add((i,j))

    return ad

# build a mapping from a mutation to its clone ("inverse" of cs)
def build_cmap(cs) :

    clone = {} # mapping from mutation to its clone
    for c in cs :
        for x in cs[c] :
            clone[x] = c

    return clone

# Main
#----------------------------------------------------------------------

t = loading.get_tree(open(sys.argv[1],'r')) # load ground truth tree & clones
cs = {i:set(int(x) for x in y.split()) for i,y in enumerate(open(sys.argv[2],'r'))}

it, ics, diff = loading.get_inferred(open(sys.argv[3],'r')) # inferred tree & clones
print('non-clonal nodes =', '{}' if not diff else diff, file = sys.stderr)

ad = build_ad(t, len(cs)) # build ancestor-descendant relationships
iad = build_ad(it, len(ics))

print(t.get_ascii())
print(cs)
print(ad)

print(it.get_ascii())
print(ics)
print(iad)
