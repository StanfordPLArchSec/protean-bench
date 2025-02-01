rule host_bbv:
    input:
        exe = "{bench}/bin/{bin}/exe"
    output:
        bbv_txt = "{bench}/host/{input}/{bin}/bbv.txt"
    params:
        # TODO: Factor this out to common rule with pincpu.
        # TODO: Add mem resources.
        run = "{bench}/bin/{bin}/run",
        workload_args = lambda wildcards: get_input(wildcards).args,
        stdin = lambda wildcards: get_input(wildcards).stdin,
        bbv_dir = "{bench}/host/{input}/{bin}/bbv",
    resources:
        mem = lambda w: get_input(w).mem_plus("2GiB"),
    shell:
        "EXE=$(realpath {input.exe}) && "
        "BBV_DIR=$(realpath {params.bbv_dir}) && "
        "BBV_TXT=$(realpath {output.bbv_txt}) && "
        "rm -rf $BBV_DIR && mkdir -p $BBV_DIR && "
        "cd {params.run} && "
        "/usr/bin/time -vo $BBV_DIR/time.txt valgrind --tool=exp-bbv --log-file=$BBV_DIR/log.txt --bb-out-file=$BBV_TXT --interval-size=%d -- "
        "$EXE {params.workload_args} < {params.stdin} > $BBV_DIR/stdout.txt 2> $BBV_DIR/stderr.txt " % (interval)

rule host_simpoints:
    input:
        intervals = "{bench}/host/{input}/{bin}/intervals.txt",
        weights = "{bench}/host/{input}/{bin}/weights.txt",
        bbv = "{bench}/host/{input}/{bin}/bbv.txt",
        script = "helpers/host/generate_simpoints_json.py",
    output: "{bench}/host/{input}/{bin}/simpoints.json"
    shell:
        "{input.script} --intervals {input.intervals} --weights {input.weights} --bbv {input.bbv} > {output}"
            
        
rule host_instcounts:
    input:
        simpoints_json = "{bench}/host/{input}/{bin}/simpoints.json",
        script = "helpers/host/generate_instcount.py"
    output: "{bench}/host/{input}/{bin}/instcounts.txt",
    shell:
        "{input.script} < {input.simpoints_json} > {output}"

rule host_cycles:
    input:
        profiler = "src/host_interval",
        exe = "{bench}/bin/{bin}/exe",
        instcounts = "{bench}/host/{input}/{bin}/instcounts.txt",
    output: "{bench}/host/{input}/{bin}/cycles.txt"
    params:
        run = "{bench}/bin/{bin}/run",
        workload_args = lambda wildcards: get_input(wildcards).args,
        stdin = lambda wildcards: get_input(wildcards).stdin,
    shell:
        "{input.profiler} -C {params.run} -i {input.instcounts} -o {output} -- $(realpath {input.exe}) {params.workload_args} < {params.stdin}"

rule host_results:
    input:
        profile = "{bench}/host/{input}/{bin}/cycles.txt",
        simpoints_json = "{bench}/host/{input}/{bin}/simpoints.json",
        script = "helpers/host/generate_cyclediff.py",
    output: "{bench}/host/{input}/{bin}/results.json"
    shell:
        "{input.script} --simpoints-json {input.simpoints_json} --profile {input.profile} > {output}"

rule host_perf:
    input: "{bench}/bin/{bin}/exe",
    output: "{bench}/host/{input}/{bin}/perf.txt"
    params:
        # TODO: Factor this out to common rule with pincpu.
        # TODO: Add mem resources.
        run = "{bench}/bin/{bin}/run",
        workload_args = lambda wildcards: get_input(wildcards).args,
        stdin = lambda wildcards: get_input(wildcards).stdin,
    shell:
        "EXE=$(realpath {input}) && "
        "OUT=$(realpath {output}) && "
        "cd {params.run} && "
        "taskset -c 2 perf stat --all-user -e instructions -e ref-cycles -o $OUT -- $EXE {params.workload_args} < {params.stdin}"
      
