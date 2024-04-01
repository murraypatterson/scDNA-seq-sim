import sys
from math import sqrt

# mean
def mean(xs) :
    return sum(xs) / float(len(xs))

# variance
def var(xs) :
    m = mean(xs)
    return sum([(x-m)**2 for x in xs]) / float(len(xs))

# Main
#----------------------------------------------------------------------

a = []
for line in open(sys.argv[1], 'r') :
    a.append(float(line.strip()))

print('{} +/- {}'.format(mean(a), sqrt(var(a))))
