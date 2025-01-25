import glob
import sys
import json

import bench

container: "ptex.sif"

# TODO: Move these to config file?
gem5_pin_src = "../gem5/pincpu"
gem5_pin_exe = gem5_pin_src + "/build/X86_MESI_Three_Level/gem5.opt"
gem5_pin_configs = gem5_pin_src + "/configs"
# TODO: Use this using the 'bin' setup.
addr2line = "../llvm/base-17/build/bin/llvm-addr2line"

# TODO: Investigate why partial build of libc doesn't work.

# TODO: Define these in the filesystem, too.
bingroups = {
    "main": ["base", "sni.", "sni.c"],
}

sim_gem5_opts = {
    "tpt": [ "--debug-flag=TPT,TransmitterStalls"],
    "spt-ptex": ["--debug-flag=PTeX"],
}

warmup = 10000000
interval = 50000000
simpoint_exe = "../simpoint/bin/simpoint"
num_simpoints = 10

# TODO: Create a base rule from which to inherit that depend on the compiler like this.
# TODO: Make builds quiet.

include: "rules/libc.smk"
include: "rules/libcxx.smk"
include: "rules/cpu2017.smk"
include: "rules/bearssl.smk"
include: "rules/ctaes.smk"
include: "rules/djbsort.smk"

# TODO: This is not actually dependent on the bingroup. Should relocate this accordingly.
# Only the shared results should be for the bingroups.

def get_input(wildcards):
    return bench.get_bench(wildcards.bench).get_input(wildcards.input)

# This abstract rule requires:
# input:
#   - script: the gem5 run script
# output:
#   - ???: the output file produced by the run (stats.txt, etc., not included)
# params:
#   - script_args: the arguments to pass to the gem5 run script (input.script)
#   - outdir: gem5's output directory (containing stats.txt, etc.)
rule _pincpu:
    input:
        gem5 = gem5_pin_exe,
        exe = "{bench}/bin/{bin}/exe",
    params:
        rundir = "{bench}/bin/{bin}/run",
        workload_args = lambda wildcards: get_input(wildcards).args,
        mem = lambda wildcards: get_input(wildcards).mem_size,
        stack = lambda wildcards: get_input(wildcards).stack_size,
    resources:
        # TODO: Intelligent dynamic memory: use /usr/bin/time -vo {outdir}/time.txt to get max memory usage.
        # Then, when dynamically computing mem, check whether such a file from a previous run exists and grab the memory limit from there.
        mem = lambda wildcards: get_input(wildcards).mem_plus("2GiB"), # Grant extra memory for gem5. A resonable value will meet needs for most benchmarks, but not all. For those that need more, override the `host_mem` parameter when creating the benchmark input.
        runtime = lambda wildcards: get_input(wildcards).runtime_seconds(),
    threads: 1
    shell:
        "if [ -d {params.outdir} ]; then rm -r {params.outdir}; fi && "
        "{input.gem5} -re --silent-redirect -d {params.outdir} "
        "{input.script} --stdin=/dev/null --stdout=stdout.txt --stderr=stderr.txt "
        "--mem-size={params.mem} --max-stack-size={params.stack} --chdir={params.rundir} "
        "{params.script_args} "
        "-- {input.exe} {params.workload_args} "

use rule _pincpu as bbhist with:
    input:
        **rules._pincpu.input,
        script = gem5_pin_configs + "/pin-bbhist.py"
    output:
        **rules._pincpu.output,
        bbhist_txt = "{bench}/cpt/{input}/{bingroup}/{bin}/bbhist.txt",
    params:
        **rules._pincpu.params,
        outdir = "{bench}/cpt/{input}/{bingroup}/{bin}/bbhist",
        script_args = "--bbhist={bench}/cpt/{input}/{bingroup}/{bin}/bbhist.txt" # TODO: Reuse definition of bbhist_txt somehow?

rule instlist:
    input:
        bbhist_txt = "{dir}/bbhist.txt",
        instlist_py = "helpers/instlist.py",
    output:
        instlist_txt = "{dir,.*}/instlist.txt",
    shell:
        "{input.instlist_py} < {input.bbhist_txt} > {output.instlist_txt}"

rule srclist:
    input:
        exe = "{bench}/bin/{bin}/exe",
        instlist = "{bench}/cpt/{input}/{bingroup}/{bin}/instlist.txt",
    output:
        srclist = "{bench}/cpt/{input}/{bingroup}/{bin}/srclist.txt"
    shell:
        addr2line + " --exe {input.exe} --output-style=JSON < {input.instlist} > {output.srclist}"

rule srclocs:
    input:
        srclist_txt = "{dir}/srclist.txt",
        srclocs_py = "helpers/srclocs.py",
    output:
        srclocs = "{dir,.*}/srclocs.txt"
    shell:
        "{input.srclocs_py} < {input.srclist_txt} > {output.srclocs}"

rule lehist:
    input:
        bbhist_txt = "{dir}/bbhist.txt",
        srclocs_txt = "{dir}/srclocs.txt",
        lehist_py = "helpers/lehist.py",
    output:
        lehist_txt = "{dir,.*}/lehist.txt"
    shell:
        "{input.lehist_py} --bbhist={input.bbhist_txt} --srclocs={input.srclocs_txt} > {output.lehist_txt}"

rule shlocedges:
    input:
        # FIXME: This is a bug!
        lehist_txts = lambda wildcards: expand("{bench}/cpt/{input}/{bingroup}/{bin}/lehist.txt", bench=wildcards.bench, input=wildcards.input, bingroup=wildcards.bingroup, bin=bingroups[wildcards.bingroup]),
        shlocedges_py = "helpers/shlocedges.py",
    output:
        shlocedges_txt = "{bench}/cpt/{input}/{bingroup}/shlocedges.txt"
    shell:
        "{input.shlocedges_py} {input.lehist_txts} > {output.shlocedges_txt}"

rule waypoints:
    input:
        bbhist_txt = "{bench}/cpt/{input}/{bingroup}/{bin}/bbhist.txt",
        srclocs_txt = "{bench}/cpt/{input}/{bingroup}/{bin}/srclocs.txt",
        shlocedges_txt = "{bench}/cpt/{input}/{bingroup}/shlocedges.txt",
        waypoints_py = "helpers/waypoints.py",
    output:
        waypoints_txt = "{bench}/cpt/{input}/{bingroup}/{bin}/waypoints.txt",
    shell:
        "{input.waypoints_py} --bbhist={input.bbhist_txt} --srclocs={input.srclocs_txt} --shlocedges={input.shlocedges_txt} > {output.waypoints_txt}"

use rule _pincpu as bbv with:
    input:
        **rules._pincpu.input,
        script = gem5_pin_configs + "/pin-bbv.py", # TODO: Factor out the prefix.
        waypoints_txt = "{bench}/cpt/{input}/{bingroup}/{bin}/waypoints.txt",
    output:
        **rules._pincpu.output,
        bbv_txt = "{bench}/cpt/{input}/{bingroup}/{bin}/bbv.txt",
        bbvinfo_txt = "{bench}/cpt/{input}/{bingroup}/{bin}/bbvinfo.txt",
    params:
        **rules._pincpu.params,
        outdir = "{bench}/cpt/{input}/{bingroup}/{bin}/bbv",
        script_args = lambda wildcards, input, output: f"--bbv={output.bbv_txt} --bbvinfo={output.bbvinfo_txt} --warmup={warmup} --interval={interval} --waypoints={input.waypoints_txt}"

rule intervals:
    input:
        bbv_txt = "{dir}/bbv.txt",
        simpoint_exe = simpoint_exe,
    output:
        intervals_txt = "{dir,.*}/intervals.txt",
        weights_txt = "{dir,.*}/weights.txt",
    params:
        outdir = "{dir,.*}/intervals",
        num_simpoints = num_simpoints,
    shell:
        "if ! [ -d {params.outdir} ]; then mkdir {params.outdir}; fi && "
        "{input.simpoint_exe} -loadFVFile {input.bbv_txt} -maxK {params.num_simpoints} -saveSimpoints "
        "{output.intervals_txt} -saveSimpointWeights {output.weights_txt} -fixedLength off "
        "> {params.outdir}/stdout 2> {params.outdir}/stderr"

def get_leader_file(filename, wildcards):
    return expand("{bench}/cpt/{input}/{bingroup}/{bin}/{filename}",
                  bench=wildcards.bench,
                  input=wildcards.input,
                  bingroup=wildcards.bingroup,
                  bin=bingroups[wildcards.bingroup][0],
                  filename=filename)
        
rule simpoints_json:
    input:
        intervals_txt = lambda wildcards: get_leader_file("intervals.txt", wildcards),
        weights_txt = lambda wildcards: get_leader_file("weights.txt", wildcards),
        bbvinfo_txt = lambda wildcards: get_leader_file("bbvinfo.txt", wildcards),
        simpoints_py = "helpers/simpoints.py",
    output:
        simpoints_json = "{bench}/cpt/{input}/{bingroup}/simpoints.json"
    shell:
        "{input.simpoints_py} --intervals={input.intervals_txt} --weights={input.weights_txt} --bbvinfo={input.bbvinfo_txt} > {output.simpoints_json}"

checkpoint checkpoint:
    input:
        **rules._pincpu.input,
        simpoints_json = "{bench}/cpt/{input}/{bingroup}/simpoints.json",
        waypoints_txt = "{bench}/cpt/{input}/{bingroup}/{bin}/waypoints.txt",
        script = gem5_pin_configs + "/pin-cpt.py",
    output:
        **rules._pincpu.output,
        cptdir = directory("{bench}/cpt/{input}/{bingroup}/{bin}/cpt"),
    params:
        **rules._pincpu.params,
        outdir = "{bench}/cpt/{input}/{bingroup}/{bin}/cpt", # TODO: duplicate of outdir
        script_args = lambda wildcards, input: f"--simpoints-json={input.simpoints_json} --waypoints={input.waypoints_txt}"
    threads: 1
    resources:
        **rules._pincpu.rule.resources
    shell:
        rules._pincpu.rule.shellcmd

def get_checkpoint(wildcards):
    checkpoint_output = checkpoints.checkpoint.get(**wildcards)
    return expand("{dir}/cpt.{cptid}/{filename}",
                  dir = checkpoint_output.output,
                  cptid = wildcards.cptid,
                  filename = ["m5.cpt", "system.physmem.store0.pmem"])

rule resume_from_checkpoint:
    input:
        cpt_data = get_checkpoint,
        gem5 = "../gem5/{sim}/build/X86_MESI_Three_Level/gem5.opt",
        exe = "{bench}/bin/{bin}/exe",
        run_script = "../gem5/{sim}/configs/AlderLake/se.py",
        hwconfig = "hwconfs/{hwconf}",
    output:
        stats_txt = "{bench}/exp/{input}/{bingroup}/{bin}/{sim}/{hwconf}/{cptid}/stats.txt",
        dbgout_txt_gz = "{bench}/exp/{input}/{bingroup}/{bin}/{sim}/{hwconf}/{cptid}/dbgout.txt.gz",
    params:
        **rules._pincpu.params, # TODO: Shouldn't inherit it from PinCPU!
        cptdir = "{bench}/cpt/{input}/{bingroup}/{bin}/cpt",
        outdir = "{bench}/exp/{input}/{bingroup}/{bin}/{sim}/{hwconf}/{cptid}",
        gem5_opts = lambda wildcards: " ".join(sim_gem5_opts.get(wildcards.sim, []))
    threads: 1
    resources:
        mem = rules._pincpu.rule.resources["mem"], # TOOD: Shouldn't inherit directly from PinCPU.
        # TODO: Specify runtime?
    shell:
        "if [ -d {params.outdir} ]; then rm -r {params.outdir}; fi && "
        "{input.gem5} -re --silent-redirect -d {params.outdir} --debug-file=dbgout.txt.gz {params.gem5_opts} "
        "{input.run_script} --input=/dev/null --output=stdout.txt --errout=stderr.txt "
        "--cpu-type=X86O3CPU "
        "--mem-size={params.mem} --max-stack-size={params.stack} --chdir={params.rundir} "
        "--checkpoint-dir={params.cptdir} "
        "--checkpoint-restore=$(({wildcards.cptid}+1)) "
        "--restore-simpoint-checkpoint "
        "--cmd={input.exe} "
        "--options=\"{params.workload_args}\" "
        "$(cat {input.hwconfig})" # TODO: Build this into a config file.

rule checkpoint_results:
    input:
        script = "helpers/generate-leaf-results.py",
        stats_txt = "{bench}/exp/{input}/{bingroup}/{bin}/{sim}/{hwconf}/{cptid}/stats.txt",
        simpoints_json = "{bench}/cpt/{input}/{bingroup}/simpoints.json",
    output:
        "{bench}/exp/{input}/{bingroup}/{bin}/{sim}/{hwconf}/{cptid}/results.json"
    shell:
        "{input.script} --stats={input.stats_txt} --simpoints-json={input.simpoints_json} --simpoint-idx={wildcards.cptid} --output={output}"

def get_simpoints_json(wildcards):
    # Make sure we've executed the checkpoint.
    # This should ensure that simpoints.json is available, right?
    checkpoints.checkpoint.get(**wildcards) 
    simpoints_json = expand("{bench}/cpt/{input}/{bingroup}/simpoints.json", **wildcards)
    assert len(simpoints_json) == 1
    simpoints_json = simpoints_json[0]
    with open(simpoints_json) as f:
        return json.load(f)

def get_simpoint_weight(wildcards):
    simpoints = get_simpoints_json(wildcards)
    i = int(wildcards.cptid)
    return simpoints[i]["weight"]
    
def get_exp_checkpoints(wildcards, *path_components):
    j = get_simpoints_json(wildcards)
    n = len(j)
    paths = expand("{bench}/exp/{input}/{bingroup}/{bin}/{sim}/{hwconf}/{cptid}",
                   **wildcards, cptid = map(str, range(0, n)))
    return [os.path.join(path, *path_components) for path in paths]

# TODO: Remove if unused.
def get_exp_weights(wildcards):
    return list(map(lambda simpoint: simpoint["weight"], get_simpoints_json(wildcards)))

rule bench_results:
    input:
        script = "helpers/generate-bench-results.py",
        cpt_results = lambda wildcards: get_exp_checkpoints(wildcards, "results.json"),
    output:
        "{bench}/exp/{input}/{bingroup}/{bin}/{sim}/{hwconf}/results.json"
    shell:
        "{input.script} {input.cpt_results} --output={output}"

include: "rules/stalls.smk"
