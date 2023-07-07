import sys
import random
from csv import DictReader

# add noise to profile p according to a (FN), b (FP) and u (dropout)
def add_noise(p, a, b, u) :

    # add dropouts with probability u
    for i in range(len(p)) :
        if random.random() < u :
            p[i] = '?'

    # add FNs, resp. FPs with probability a, resp. b
    for i in range(len(p)) :
        if p[i] == '?' :
            continue

        if p[i] == '0' :
            if random.random() < b :
                p[i] = '1' # default to multiplicity 1 for FP
    
        else :
            if random.random() < a :
                p[i] = '0'

    return p

# Main
#----------------------------------------------------------------------

rows = DictReader(open(sys.argv[1],'r'))
cols = rows.fieldnames
i = cols[0]

n = int(sys.argv[2])
a, b, u = (float(x) for x in sys.argv[3:])

p = {}
for row in rows :
    p[int(row[i])] = [row[x] for x in cols[1:]]

m = len(p)
s = []
print('cell\mut', *cols[1:], sep = ',')
for i in range(n) :
    j = random.randrange(m)
    s.append(j)

    print(i, *add_noise(list(p[j]), a, b, u), sep = ',')

# log the source
print(*s, sep = ',', file = sys.stderr)
