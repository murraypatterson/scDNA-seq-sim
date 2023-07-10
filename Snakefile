
data = '/data/'
ts = range(50)
m = 2

time = '/usr/bin/time'
timeout = '/usr/bin/timeout'

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
        # compute clones + do some sanity checks
        expand(data + 'clones/clones_{t}.txt', t = ts),

        # generate the data
        expand(data + 'New_lists/sample_{t}.csv', t = ts),

        # run the tools
        expand(data + 'New_lists/{tool}/sample_{t}.txt', tool = tools, t = ts),

# run scite on the data
#----------------------------------------------------------------------

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
    {sasc} -n {n} -m {m} -a {FNrate} -b {FPrate} -k 1 -lxp {threads} \
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

# compute the new mutations acquired in each clone (w/ sanity checks)
rule compute_clones :
    input :
        tree = '{path}/New_trees/tree_{t}.csv',
        liste = '{path}/New_lists/list_{t}.csv'

    output : '{path}/clones/clones_{t}.txt'
    log : '{path}/clones/clones_{t}.txt.log'

    shell : '''

  python3 scripts/compute_clones.py {input} {m} > {output} 2> {log} '''

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
