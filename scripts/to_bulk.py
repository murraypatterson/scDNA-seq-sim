import sys
from csv import DictReader

rows = DictReader(open(sys.argv[1],'r'))
cols = rows.fieldnames
ms = cols[1:]

count = {m:0 for m in ms} # mutational count (over cells)
for row in rows :
    for m in ms :
        x = row[m]

        if x == '?' :
            continue

        count[m] += int(x)

maxc = max(count[m] for m in ms)
        
head = 'ID Chromosome Position Mutantcount ReferenceCount INFO'.split()
print(*head, sep = '\t')

for i, m in enumerate(ms) :
    print(m, 1, i, count[m], maxc * 5, 'sampleIDs=primary', sep = '\t')
