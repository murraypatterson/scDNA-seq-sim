import sys
import loading
from collections import defaultdict

# build set of pairs of nodes in an ancestor-descendant
# (resp. different lineages) relationship in tree t with nodes
# {0..n-1} (note that latter is the complement of the former)
def build_ad_dl(t, n) :

    ad, dl = set(), set()
    for i in range(n) :
        si = str(i)

        for j in range(i+1,n) :
            sj = str(j)

            a = t.get_common_ancestor(si,sj).name
            if a == si or a == sj :
                ad.add((i,j))
            else :
                dl.add((i,j))

    return ad, dl

# build a mapping from a mutation to its clone ("inverse" of cs)
def build_cmap(cs) :

    clone = defaultdict(lambda:-1) # default value is -1
    for c in cs :
        for x in cs[c] :
            clone[x] = c

    return clone

# Main
#----------------------------------------------------------------------

t = loading.get_tree(open(sys.argv[1],'r')) # load ground truth tree & clones
cs = {i:set(int(x) for x in y.split()) for i,y in enumerate(open(sys.argv[2],'r'))}

it, ics = loading.get_inferred(open(sys.argv[3],'r')) # inferred t & clones

ms = set().union(*(cs[i] for i in cs))
ims = set().union(*(ics[i] for i in ics))

nonc = ims - ms
for x in nonc :
    assert x < 0, nonc

print('dummy mutations =', '{}' if not nonc else nonc, file = sys.stderr)

diff = ms - ims
print('missing mutations =', '{}' if not diff else diff, file = sys.stderr)

ad, dl = build_ad_dl(t, len(cs)) # build ad/dl relationships
iad, idl = build_ad_dl(it, len(ics))

clone = build_cmap(cs) # mapping from mutation -> clone
iclone = build_cmap(ics)

a = {'tp': 0, 'tn': 0, 'fp': 0, 'fn': 0} # for anc-dec
d = {'tp': 0, 'tn': 0, 'fp': 0, 'fn': 0} # for diff-lin
m = sorted(ms)
for i in range(len(m)) :
    for j in range(i) :

        xy = iclone[m[i]], iclone[m[j]]
        if (clone[m[i]], clone[m[j]]) in ad : # in ad rel. in ground truth

            if xy in iad : # in ad rel. in inferred
                a['tp'] += 1

            else : # not in ad rel. in inferred
                a['fn'] += 1

            if xy in idl : # in dl rel. in inferred
                d['fp'] += 1

            else : # not in dl rel. in iferred
                d['tn'] += 1

        else : # in dl rel. in ground truth

            if xy in idl :
                d['tp'] += 1

            else :
                d['fn'] += 1

            if xy in iad :
                a['fp'] += 1

            else :
                a['tn'] += 1

ada = float(a['tp'] + a['tn']) / sum(a[x] for x in a)
dla = float(d['tp'] + d['tn']) / sum(d[x] for x in d)

assert 0. <= ada and ada <= 1.
assert 0. <= dla and dla <= 1.

print(ada, dla)
