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
        elif extra.startswith("f"):
            args.append(f"--symbolic-reset-every={extra.removeprefix("f")}")
        else:
            assert False

    winlen = int(wildcards["winlen"])
    winidx = int(wildcards["winidx"])
    winbegin = winidx * winlen
    winend = (winidx + 1) * winlen
    args.extend([f"--begin={winbegin}", f"--end={winend}"])
    return args
    
rule unique_leak:
    input:
        script = "../gem5/utrace/analysis/main.py",
        dbgout = lambda wildcards: get_exp_heaviest_checkpoint({**wildcards, "hwconf": "utrace.ecore"}, "dbgout.txt.gz"),
    output:
        stdout = "{bench}/leak/{input}/{bingroup}/{bin}/{winlen}/{leakconf}/{winidx}/stdout.txt.gz",
        time = "{bench}/leak/{input}/{bingroup}/{bin}/{winlen}/{leakconf}/{winidx}/time.txt",
    params:
        args = get_leakconf
    shell:
        "/usr/bin/time -vo {output.time} {input.script} {params.args} --output {output.stdout} {input.dbgout}"
