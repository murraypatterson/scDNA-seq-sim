
data = '/data/'
n = 50
m = 2

time = '/usr/bin/time'
scite = 'SCITE/scite'
sasc = 'sasc/sasc'
phiscs = 'PhISCS/PhISCS-I'
threads = 16

nCells = 100
FNrate = 0.1
FPrate = 0.0001
dRate = 0.2

#----------------------------------------------------------------------

rule master :
    input :
        # sanity check
        expand(data + 'sanity_checks/sanity_check_{i}.log', i = range(n)),

        # generate the data
        expand(data + 'New_lists/sample_{i}.csv', i = range(n)),

        # scite
        expand(data + 'New_lists/scite/sample_{i}_ml0.gv', i = range(n)),

        # sasc
        #expand(data + 'New_lists/sasc/sample_{i}.txt', i = range(n)),

        # phiscs
        #expand(data + 'New_lists/phiscs/sample_{i}.csv', i = range(n))

# run scite on the data
#----------------------------------------------------------------------

# run scite on an input
rule run_scite :
    input :
        prog = scite,
        mat = '{path}/sample_{i}.in',
        snvs = '{path}/snvs_{i}.txt'

    output : '{path}/sample_{i}_ml0.gv'

    log :
        log = '{path}/sample_{i}_ml0.gv.log',
        time = '{path}/sample_{i}_ml0.gv.time'

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
    input : '{path}/sample_{i}.csv'

    output :
        mat = '{path}/scite/sample_{i}.in',
        snvs = '{path}/scite/snvs_{i}.txt'

    log : '{path}/scite/sample_{i}.in.log'

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
    input :
        '{path}/sample_{i}_mlt.gv'

    output : '{path}/sample_{i}.txt'
    log : '{path}/sample_{i}.txt.log'

    shell : 'python3 scripts/from_sasc.py {input} > {output} 2> {log}'

# run sasc on an input
rule run_sasc :
    input :
        prog = sasc,
        mat = '{path}/sample_{i}.mat',
        snvs = '{path}/snvs_{i}.txt',
        cells = '{path}/cells_{i}.txt'

    output : '{path}/sample_{i}_mlt.gv'

    log :
        log = '{path}/sample_{i}.out.log',
        time = '{path}/sample_{i}.out.time',

    threads : threads

    run :
        with open(input.mat) as mat :
            m = len(mat.readline().split())
            n = sum(1 for line in mat) + 1

        shell('''

  {time} -vo {log.time} \
    {sasc} -n {n} -m {m} -a {FNrate} -b {FPrate} -k 1 -lxp {threads} \
      -i {input.mat} -e {input.snvs} -E {input.cells} \
        > {output} 2> {log.log}
  touch {output} ''')

# convert sample to sasc format
rule to_sasc :
    input : '{path}/sample_{i}.csv'
    output :
        mat = '{path}/sasc/sample_{i}.mat',
        snvs = '{path}/sasc/snvs_{i}.txt',
        cells = '{path}/sasc/cells_{i}.txt'

    log : '{path}/sasc/sample_{i}.mat.log'

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
        sc = '{path}/sample_{i}.SC',
        bulk = '{path}/sample_{i}.bulk'

    output : '{path}/sample_{i}.csv'

    log :
        log = '{path}/sample_{i}.csv.log',
        time = '{path}/sample_{i}.csv.time'

    threads : threads

    shell : '''

  {time} -vo {log.time} \
    python3 {input.prog} -SCFile {input.sc} -fn {FNrate} -fp {FPrate} -kmax 1 \
      -bulkFile {input.bulk} -threads {threads} --drawTree > {log.log} 2>&1
  touch {output} '''

# covert sample to PhISCS format
rule to_phiscs :
    input : '{path}/sample_{i}.csv'
    output :
        sc = '{path}/phiscs/sample_{i}.SC',
        bulk = '{path}/phiscs/sample_{i}.bulk'

    log : '{path}/phiscs/sample_{i}.SC.log'

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
    input : '{path}/profile_{i}.csv'
    output : '{path}/sample_{i}.csv'
    params :
        cells = nCells,
        a = FNrate,
        b = FPrate,
        u = dRate

    log : '{path}/sample_{i}.csv.log'

    shell : '''

  python3 scripts/amplify_profile.py {input} {params} \
    > {output} 2> {log} '''

# generate the mutational profile for each clone from a list
rule generate_profile :
    input : '{path}/list_{i}.csv'
    output : '{path}/profile_{i}.csv'
    log : '{path}/profile_{i}.csv.log'

    shell : '''

  python3 scripts/generate_profile.py {input} {m} \
    > {output} 2> {log} '''

# sanity check
#----------------------------------------------------------------------

# check if children come from parents and that new mutations are unique
rule sanity_check :
    input :
        tree = '{path}/New_trees/tree_{i}.csv',
        liste = '{path}/New_lists/list_{i}.csv'

    output : '{path}/sanity_checks/sanity_check_{i}.log'

    shell : 'python3 scripts/sanity_check.py {input} > {output} 2>&1'

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
