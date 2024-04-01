
data = '/data/scDNA-seq-sim-trees/'
ts = range(50)
#ts = set(ts) - {9,23,29,43,45}
m = 2

time = '/usr/bin/time'
timeout = '/usr/bin/timeout'
mp3 = 'mp3treesim'

tools = ['scite', 'sasc', 'phiscs']
scite = 'SCITE/scite'
sasc = 'sasc/sasc'
phiscs = 'PhISCS/PhISCS-I'

nCells = 100
FNrate = 0.1
FPrate = 0.0001
dRate = 0.2

#----------------------------------------------------------------------

rule master :
    input :
        #...
        expand(data + 'accuracies/mp3s_{tool}_stats.txt',
               tool = ['sasc', 'scite'])

        # compute gt gv trees
#        expand(data + 'New_trees/tree_{t}.gv', t = ts)

        # compute clones + do some sanity checks
#        expand(data + 'clones/snvs_{t}.txt', t = ts),

        # generate the data
#        expand(data + 'New_lists/sample_{t}.csv', t = ts),

        # run the tools
#        expand(data + 'New_lists/{tool}/sample_{t}.txt',
#               tool = tools, t = ts),

        # compute accuracies
#        expand(data + 'accuracies/ada_dla_{tool}_{t}.txt',
#               tool = tools, t = ts),

        # compute stats on accuracies
#        expand(data + 'accuracies/ada_dla.stats.csv')

#----------------------------------------------------------------------

# quick mean +/- SD for tool
rule quick_stats :
    input : '{path}/mp3s_{tool}.txt'
    output : '{path}/mp3s_{tool}_stats.txt'
    log : '{path}/mp3s_{tool}_stats.txt.log'

    shell : 'python3 scripts/quick_stats.py {input} > {output} 2> {log}'

# gather accuracies mp3 for given tool
rule gather_accuracies_mp3 :
    input :
        expand('{{path}}/mp3_{{tool}}_{t}.txt', t = ts)

    output : '{path}/mp3s_{tool}.txt'
    log : '{path}/mp3s_{tool}.txt.log'

    shell : 'cat {input} > {output} 2> {log}'

# compute mp3 distance for tree from tool
rule get_mp3_dist :
    input :
        ground = '{path}/New_trees/tree_{t}.gv',
        tool = '{path}/New_lists/{tool}/sample_{t}_{tool}.gv'

    output : '{path}/accuracies/mp3_{tool}_{t}.txt'
    log : '{path}/accuracies/mp3_{tool}_{t}.txt.log'

    shell : '{mp3} --labeled-only {input} > {output} 2> {log}'

# convert ground truth tree to a mutational tree for comparison
rule get_mut_tree :
    input :
        tree = '{path}/New_trees/tree_{t}.csv',
        new = '{path}/clones/new_{t}.txt'

    output : '{path}/New_trees/tree_{t}.gv'
    log : '{path}/New_trees/tree_{t}.gv.log'

    shell : 'python3 scripts/mut_tree.py {input} > {output} 2> {log}'

# for ancestor-descendant and different lineages accuracies
#----------------------------------------------------------------------

# gather accuracies for each tool and compute some stats
rule compute_stats :
    input :
        expand('{{path}}/ada_dla_{tool}.txt', tool = tools)

    output :
        csv = '{path}/ada_dla.stats.csv',
        ad = '{path}/anc-dec.png',
        dl = '{path}/diff-lin.png'

    log : '{path}/ada_dla.stats.csv.log'

    shell : '''

  python3 scripts/compute_stats.py {input} {output} > {log} 2>&1 '''

# gather accuracies for a given tool
rule gather_accuracies :
    input :
        expand('{{path}}/ada_dla_{{tool}}_{t}.txt', t = ts)

    output : '{path}/ada_dla_{tool}.txt'
    log : '{path}/ada_dla_{tool}.txt.log'

    shell : 'cat {input} > {output} 2> {log}'

# compute anc-dec and diff-lin accuracies for tree t from tool
rule get_accuracies :
    input :
        tree = '{path}/New_trees/tree_{t}.csv',
        new = '{path}/clones/new_{t}.txt',
        inferred = '{path}/New_lists/{tool}/sample_{t}.txt'

    output : '{path}/accuracies/ada_dla_{tool}_{t}.txt'
    log : '{path}/accuracies/ada_dla_{tool}_{t}.txt.log'

    shell : '''

  python3 scripts/accuracies.py {input} > {output} 2> {log} '''

# run scite on the data
#----------------------------------------------------------------------

# for mp3 (naming convention)
rule from_scite_to_mp3 :
    input : '{path}/sample_{t}_ml0.gv'
    output : '{path}/sample_{t}_scite.gv'
    log : '{path}/sample_{t}_scite.gv.log'

    shell : 'python3 scripts/scite2mp3.py {input} > {output} 2> {log}'

# translate scite output to a standard mutational tree format
rule from_scite :
    input : '{path}/sample_{t}_ml0.gv'
    output : '{path}/sample_{t}.txt'
    log : '{path}/sample_{t}.txt.log'

    shell : 'python3 scripts/from_scite.py {input} > {output} 2> {log}'

# run scite on an input
rule run_scite :
    input :
        prog = scite,
        mat = '{path}/sample_{t}.in',
        snvs = '{path}/snvs_{t}.txt'

    output : '{path}/sample_{t}_ml0.gv'

    log :
        log = '{path}/sample_{t}_ml0.gv.log',
        time = '{path}/sample_{t}_ml0.gv.time'

    run :
        with open(input.mat) as mat :
            m = len(mat.readline().split())
            n = sum(1 for line in mat) + 1

        shell('''

  {time} -vo {log.time} \
    {scite} -i {input.mat} -n {n} -m {m} -r 1 -l 900000 \
      -fd {FPrate} -ad {FNrate} -names {input.snvs} -max_treelist_size 1 \
        > {log.log} 2>&1
  touch {output} ''')

# convert sample to scite format
rule to_scite :
    input : '{path}/sample_{t}.csv'

    output :
        mat = '{path}/scite/sample_{t}.in',
        snvs = '{path}/scite/snvs_{t}.txt'

    log : '{path}/scite/sample_{t}.in.log'

    shell : '''

  head -1 {input} | awk -F, '{{for(i=2;i<=NF;i++){{print $i}}}}' \
    > {output.snvs} 2> {log}
  tail -n +2 {input} | cut -d, -f2- | csvtool transpose - \
    | sed 's/,/ /g' | sed 's/[2-9][0-9]*/1/g' | sed 's/?/3/g' \
      > {output.mat} 2> {log} '''

# run sasc on the data
#----------------------------------------------------------------------

# remove losses from sasc output
rule from_sasc_to_mp3 :
    input : '{path}/sample_{t}_mlt.gv'
    output : '{path}/sample_{t}_sasc.gv'
    log : '{path}/sample_{t}_sasc.gv.log'

    shell : 'grep -v "indianred" {input} > {output} 2> {log}'

# translate sasc output to a standard mutational tree format
rule from_sasc :
    input : '{path}/sample_{t}_mlt.gv'
    output : '{path}/sample_{t}.txt'
    log : '{path}/sample_{t}.txt.log'

    shell : 'python3 scripts/from_sasc.py {input} > {output} 2> {log}'

# run sasc on an input
rule run_sasc :
    input :
        prog = sasc,
        mat = '{path}/sample_{t}.mat',
        snvs = '{path}/snvs_{t}.txt',
        cells = '{path}/cells_{t}.txt'

    output : '{path}/sample_{t}_mlt.gv'

    log :
        log = '{path}/sample_{t}_mlt.log',
        time = '{path}/sample_{t}_mlt.time',

    threads : 16

    run :
        with open(input.mat) as mat :
            m = len(mat.readline().split())
            n = sum(1 for line in mat) + 1

        shell('''

  {time} -vo {log.time} \
    {sasc} -n {n} -m {m} -a {FNrate} -b {FPrate} -k 1 -d 5 -xp {threads} \
      -i {input.mat} -e {input.snvs} -E {input.cells} > {log.log} 2>&1
  touch {output} ''')

# convert sample to sasc format
rule to_sasc :
    input : '{path}/sample_{t}.csv'
    output :
        mat = '{path}/sasc/sample_{t}.mat',
        snvs = '{path}/sasc/snvs_{t}.txt',
        cells = '{path}/sasc/cells_{t}.txt'

    log : '{path}/sasc/sample_{t}.mat.log'

    shell : '''

  head -1 {input} | awk -F, '{{for(i=2;i<=NF;i++){{print $i}}}}' \
    > {output.snvs} 2> {log}
  tail -n +2 {input} | cut -d, -f1 \
    > {output.cells} 2>> {log}
  tail -n +2 {input} | cut -d, -f2- | \
    sed 's/,/ /g' | sed 's/[2-9][0-9]*/1/g' | sed 's/?/2/g' \
      > {output.mat} 2>> {log} '''

# run PhISCS on the data
#----------------------------------------------------------------------

# run phiscs on an input
rule run_phiscs :
    input :
        prog = phiscs,
        sc = '{path}/sample_{t}.SC',
        bulk = '{path}/sample_{t}.bulk'

    output : '{path}/sample_{t}.txt'

    log :
        log = '{path}/sample_{t}.csv.log',
        time = '{path}/sample_{t}.csv.time'

    threads : 16

    shell : '''

  {time} -vo {log.time} {timeout} 24h \
    python3 {input.prog} -SCFile {input.sc} -fn {FNrate} -fp {FPrate} \
      -o {wildcards.path} -kmax 1 -bulkFile {input.bulk} \
        -threads {threads} --drawTree > {log.log} 2>&1
  touch {output} '''

# covert sample to PhISCS format
rule to_phiscs :
    input : '{path}/sample_{t}.csv'
    output :
        sc = '{path}/phiscs/sample_{t}.SC',
        bulk = '{path}/phiscs/sample_{t}.bulk'

    log : '{path}/phiscs/sample_{t}.SC.log'

    shell : '''

  head -1 {input} | sed 's|cell\\\mut|cellID/mutID|' \
    | tr ',' '\t' > {output.sc} 2> {log}
  tail -n +2 {input} | sed 's/^/cell/' \
    | sed 's/,[2-9][0-9]*/,1/g' | tr ',' '\t' \
      >> {output.sc} 2>> {log}
  python3 scripts/to_bulk.py {input} \
    > {output.bulk} 2>> {log} '''

# prepare the data
#----------------------------------------------------------------------

# amplify and add noise to a profile to generate a simulated SCS sample
rule amplify_profile :
    input : '{path}/profile_{t}.csv'
    output : '{path}/sample_{t}.csv'
    params :
        cells = nCells,
        a = FNrate,
        b = FPrate,
        u = dRate

    log : '{path}/sample_{t}.csv.log'

    shell : '''

  python3 scripts/amplify_profile.py {input} {params} \
    > {output} 2> {log} '''

# generate the mutational profile for each clone from a list
rule generate_profile :
    input : '{path}/list_{t}.csv'
    output : '{path}/profile_{t}.csv'
    log : '{path}/profile_{t}.csv.log'

    shell : '''

  python3 scripts/generate_profile.py {input} {m} \
    > {output} 2> {log} '''

# compute info on mutations in each clone (w/ sanity checks)
rule compute_clones :
    input :
        tree = '{path}/New_trees/tree_{t}.csv',
        liste = '{path}/New_lists/list_{t}.csv'

    output :
        snvs = '{path}/clones/snvs_{t}.txt',
        new = '{path}/clones/new_{t}.txt',
        loss = '{path}/clones/loss_{t}.txt'

    log : '{path}/clones/snvs_{t}.txt.log'

    shell : '''

  python3 scripts/compute_clones.py {input} {m} {output} > {log} 2>&1 '''

# setup scite
#----------------------------------------------------------------------
rule build_scite :
    input : 'SCITE/README.md'
    output : scite
    shell : '''

  cd SCITE && g++ -std=c++11 *.cpp -o scite
  cd .. && touch {output} '''

rule get_scite :
    output : 'SCITE/README.md'
    shell : '''

  git clone https://github.com/cbg-ethz/SCITE.git
  touch {output} '''

# setup sasc
#----------------------------------------------------------------------

# build sasc
rule build_sasc :
    input : 'sasc/README.md'
    output : sasc
    shell : '''

  cd sasc && make
  cd .. && touch {output} '''

# obtain sasc
rule get_sasc :
    output : 'sasc/README.md'
    shell : '''

  git clone https://github.com/sciccolella/sasc.git
  touch {output} '''

# setup phiscs
#----------------------------------------------------------------------

# obtain phiscs
rule get_phiscs :
    output : directory(phiscs)
    shell : '''

  git clone https://github.com/murraypatterson/PhISCS.git
  touch {output} '''
