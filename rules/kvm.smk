# TODO: Inherit from _pincpu?
rule kvm:
    input:
        gem5 = "../gem5/kvmcpu/build/X86_MESI_Three_Level/gem5.opt",
        exe = "{bench}/bin/{bin}/exe",
        script = "../gem5/kvmcpu/configs/AlderLake/se.py",
    output:
        "{bench}/kvm/{input}/{bin}/stamp.txt"
    params:
        rundir = "{bench}/bin/{bin}/run",
        workload_args = lambda wildcards: get_input(wildcards).args,
        mem = lambda wildcards: get_input(wildcards).mem_size,
        stack = lambda wildcards: get_input(wildcards).stack_size,
        stdin = lambda wildcards: get_input(wildcards).stdin,
        outdir = "{bench}/kvm/0/{bin}",
    resources:
        # TODO: Intelligent dynamic memory: use /usr/bin/time -vo {outdir}/time.txt to get max memory usage.
        # Then, when dynamically computing mem, check whether such a file from a previous run exists and grab the memory limit from there.
        mem = lambda wildcards: get_input(wildcards).mem_plus("2GiB"), # Grant extra memory for gem5. A resonable value will meet needs for most benchmarks, but not all. For those that need more, override the `host_mem` parameter when creating the benchmark input.
        runtime = lambda wildcards: get_input(wildcards).runtime_seconds(),
    threads: 1
    shell:
        "if [ -d {params.outdir} ]; then rm -r {params.outdir}; fi && "
        "{input.gem5} -re --silent-redirect -d {params.outdir} "
        "{input.script} --input={params.stdin} --output=stdout.txt --errout=stderr.txt "
        "--cpu-type=X86KvmCPU "
        "--mem-size={params.mem} --max-stack-size={params.stack} --chdir={params.rundir} "
        "--cmd={input.exe} "
        "--options='{params.workload_args}' && "
        "touch {output}"
