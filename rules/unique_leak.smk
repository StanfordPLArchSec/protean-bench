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
        "{bench}/leak/{input}/{bingroup}/{bin}/chunks/{winlen}/stamp.txt"
    params:
        outdir = "{bench}/leak/{input}/{bingroup}/{bin}/chunks/{winlen}"
    wildcard_constraints:
        winlen = r"\d+"
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
        stdout = "{bench}/leak/{input}/{bingroup}/{bin}/chunks/{winlen}/{winidx}/{leakconf}/stdout.txt.gz",
        time = "{bench}/leak/{input}/{bingroup}/{bin}/chunks/{winlen}/{winidx}/{leakconf}/time.txt",
    params:
        args = get_leakconf
    shell:
        "/usr/bin/time -vo {output.time} {input.script} {params.args} --output {output.stdout} {input.utrace}"

# def get_unique_leak_full_stdouts(wildcards):
#     # Get the path to the heaviest utrace.
#     wildcards = {**wildcards, "hwconf": "utrace.ecore"}
#     utrace_path = get_exp_heaviest_checkpoint(wildcards, "dbgout.txt.gz")
#     cptid = extract_cptid(utrace_path)
#     # Read length of the interval.
#     checkpoints.resume_from_checkpoint.get(**wildcards, cptid=cptid)
#     n = 0
#     with gzip.open(utrace_path) as f:
#         for line in f:
#             n += 1
#     winlen = int(wildcards["winlen"])
#     windows = (n + winlen - 1) // winlen
#     return expand(rules.unique_leak_chunk.output, **wildcards, winidx=range(0, windows))
#         
# rule unique_leak_full:
#     input:
#         get_unique_leak_full_stdouts,
#     output:
#         "{bench}/leak/{input}/{bingroup}/{bin}/{winlen}/{leakconf}/stamp.txt"
#     shell:
#         "touch {output}"
