import sys
from loading import get_profiles
from collections import Counter

p = get_profiles(open(sys.argv[1],'r'), int(sys.argv[2]))

q = {}
for i in p :
    q[i] = Counter([x for xss in p[i] for xs in xss for x in xs]) # collapse

u = set([]) # universal set of mutations
for i in q :
    u |= set(q[i])

u = sorted(u)
    
print('clone\mut', *sorted(u), sep = ',')
for i in q :
    print(i, *(q[i][x] for x in u), sep = ',')

# logging info:
print('no. mutations =', len(u), file = sys.stderr)

c = Counter() # count the counts
for i in q :
    c += Counter(x for _,x in q[i].items())

print('multiplicities =', dict(c), file = sys.stderr)
