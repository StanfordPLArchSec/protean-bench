# Run UniqueLeak on the heaviest SimPoints.
def get_leakconf(leakconf):
    cores = {
        "leak": ["--check-leak"],
        "check": ["--check-path"],
    }
    core, *extras = leakconf.split(".")
    args = [*cores[core]]
    for extra in extras:
        if extra.startswith("t"):
            args.append(f"--timeout-newleak={extra.removeprefix("t")}ms")
        elif extra.startswith("f"):
            args.append(f"--symbolic-reset-every={extra.removeprefix("f")}")
        else:
            assert False
    return args
    
rule unique_leak:
    input:
        script = "../gem5/utrace/analysis/main.py",
        dbgout = lambda wildcards: get_exp_heaviest_checkpoint({**wildcards, "hwconf": "utrace.ecore"}, "dbgout.txt.gz"),
    output:
        leak = "{bench}/leak/{input}/{bingroup}/{bin}/{leakconf}.txt.gz",
        time = "{bench}/leak/{input}/{bingroup}/{bin}/{leakconf}.time.txt",
    params:
        args = lambda wildcards: get_leakconf(wildcards.leakconf)
    shell:
        "/usr/bin/time -vo {output.time} {input.script} {params.args} {input.dbgout} | gzip > {output.leak}"
