import sys
from math import sqrt
from collections import defaultdict
import matplotlib.pyplot as plt

# mean
def mean(xs) :
    return sum(xs) / float(len(xs))

# variance
def var(xs) :
    m = mean(xs)
    return sum([(x-m)**2 for x in xs]) / float(len(xs))

# compute a box plot dic of tools with title and output to filename
def box_plot(dic, tools, title, filename) :

    fig = plt.figure(figsize=(10,7))
    ax = fig.add_subplot()

    data = [dic[tool] for tool in tools]
    bp = ax.boxplot(data, patch_artist=True, vert=0)
    for patch, color in zip(bp['boxes'], ['r','g','b']) :
        patch.set_facecolor(color)

    ax.set_yticklabels(tools) # y axis labels
    ax.set_xlim([0,1]) # x axis range
    plt.title(title)
    plt.savefig(filename)

# Main
#----------------------------------------------------------------------

basename, _ = sys.argv[1].rsplit('/',1)
tools = [x.rsplit('_',1)[1].strip('.txt') for x in sys.argv[1:]]

a, d = defaultdict(list), defaultdict(list) # anc-dec and diff-lin accuracies
for i, tool in enumerate(tools) :
    for line in open(sys.argv[i+1],'r') :
        x, y = line.split()

        a[tool].append(float(x))
        d[tool].append(float(y))

# mean +/- sd for each of anc-dec and diff-lin over all tools
print(r'tool\acc,anc-dec (mean +/- sd),diff-lin (mean +/- sd)')
for tool in tools :
    at = a[tool]
    dt = d[tool]

    ad = '{} +/- {}'.format(mean(at), sqrt(var(at)))
    dl = '{} +/- {}'.format(mean(dt), sqrt(var(dt)))

    print(tool, ad, dl, sep = ',')

# box plots
box_plot(a, tools, 'Ancestor-Descendant Accuracy', '{}/anc-dec.png'.format(basename))
box_plot(d, tools, 'Different Lineages Accuracy', '{}/diff-lin.png'.format(basename))
