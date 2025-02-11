wildcard_constraints:
    winlen = r"\d+",
    winidx = r"\d+",
    leakconf = re_name,

# Run UniqueLeak on the heaviest SimPoints.
def get_leakconf(wildcards):
    leakconf = wildcards.leakconf
    cores = {
        "leak": ["--check-leak"],
        "check": ["--check-path"],
    }
    core, *extras = leakconf.split(".")
    args = [*cores[core]]
    for extra in extras:
        if extra.startswith("t"):
            args.append(f"--timeout-newleak={extra.removeprefix("t")}ms")
        else:
            assert False
    return args

# TODO: Shared wildcard constraints.
rule unique_leak_link_utrace:
    input:
        lambda wildcards: get_exp_heaviest_checkpoint({**wildcards, "hwconf": "utrace.ecore"}, "dbgout.txt.gz"),
    output:
        "{bench}/leak/{input}/{bingroup}/{bin}/utrace.txt.gz"
    shell:
        "ln -s $PWD/{input} {output}"

checkpoint unique_leak_make_chunks:
    input: 
        utrace = "{bench}/leak/{input}/{bingroup}/{bin}/utrace.txt.gz",
        script = "helpers/uniqleak/chunk.py",
    output:
        "{bench}/leak/{input}/{bingroup}/{bin}/{winlen}/utraces/stamp.txt"
    params:
        outdir = "{bench}/leak/{input}/{bingroup}/{bin}/{winlen}/utraces"
    shell:
        "rm -rf {params.outdir} && "
        "mkdir {params.outdir} && "
        "{input.script} -n{wildcards.winlen} --outdir={params.outdir} {input.utrace} && "
        "touch {output}"

def get_unique_leak_chunked_utrace(wildcards):
    outdir = checkpoints.unique_leak_make_chunks.get(**wildcards).rule.params.outdir
    utrace = os.path.join(outdir, "{winidx}/utrace.txt.gz")
    return expand(utrace, **wildcards)

rule unique_leak_run_chunk:
    input:
        script = "../gem5/utrace/analysis/main.py",
        utrace = get_unique_leak_chunked_utrace,
    output:
        stdout = "{bench}/leak/{input}/{bingroup}/{bin}/{winlen}/analysis/{leakconf}/{winidx}/stdout.txt.gz",
        time = "{bench}/leak/{input}/{bingroup}/{bin}/{winlen}/analysis/{leakconf}/{winidx}/time.txt",
    params:
        args = get_leakconf
    resources:
        mem_mib = lambda wildcards, attempt: 1024 * (2 ** (attempt - 1)) # Start with 1 GiB, then double with each attempt.
    shell:
        "/usr/bin/time -vo {output.time} {input.script} {params.args} --output {output.stdout} {input.utrace}"

def get_unique_leak_chunked_output(wildcards):
    outdir = checkpoints.unique_leak_make_chunks.get(**wildcards).rule.params.outdir
    utraces = glob.glob(os.path.join(expand(outdir, **wildcards)[0], "*", "utrace.txt.gz"))
    winidxs = [utrace.split("/")[-2] for utrace in utraces]
    stdouts =  expand(rules.unique_leak_run_chunk.output.stdout, **wildcards, winidx=winidxs)
    def key(path):
        return int(path.split("/")[-2])
    stdouts.sort(key=key)
    return stdouts

rule unique_leak_aggregate:
    input:
        get_unique_leak_chunked_output
    output:
        "{bench}/leak/{input}/{bingroup}/{bin}/{winlen}/analysis/{leakconf}/stdout.txt.gz"
    # run:
    #     with gzip.open(output, "wt") as f_out:
    #         for inpath in input:
    #             with gzip.open(inpath, "rt") as f_in:
    #                 shutil.copyfileobj(f_in, f_out)
    shell:
        "gunzip -c {input} | gzip > {output}"
        
