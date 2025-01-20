import glob
import sys

import bench

container: "ptex.sif"

# TODO: Move these to config file?
gem5_pin_src = "../gem5/pincpu"
gem5_pin_exe = gem5_pin_src + "/build/X86/gem5.opt"
gem5_pin_configs = gem5_pin_src + "/configs"
# TODO: Use this using the 'bin' setup.
addr2line = "../llvm/base-17/build/bin/llvm-addr2line"

# TODO: Investigate why partial build of libc doesn't work.

# TODO: Define these in the filesystem, too.
bingroups = {
    "main": ["base", "nst"],
}

warmup = 10000000
interval = 50000000
simpoint_exe = "../simpoint/bin/simpoint"
num_simpoints = 10

# TODO: Create a base rule from which to inherit that depend on the compiler like this.
# TODO: Make builds quiet.
rule build_libc:
    input:
        clang = "compilers/{bin}/llvm/bin/clang",
        clangxx = "compilers/{bin}/llvm/bin/clang++",
        cflags = "compilers/{bin}/cflags",
        llvm_libc_src = directory("llvm/{bin}/libc"),
    output:
        build = directory("libraries/{bin}/libc"),
        lib = "libraries/{bin}/libc/projects/libc/lib/libllvmlibc.a",
    params:
        llvm_src = "llvm/{bin}"
    threads: 8
    shell:
        "rm -rf {output.build} && "
        "cmake -S {params.llvm_src}/llvm -B {output.build} -DCMAKE_BUILD_TYPE=Release "
        "-DCMAKE_C_COMPILER=$PWD/{input.clang} -DCMAKE_CXX_COMPILER=$PWD/{input.clangxx} "
        "-DCMAKE_C_FLAGS='-O3 -g' -DCMAKE_CXX_FLAGS='-O3 -g' -DLLVM_ENABLE_PROJECTS=libc "
        "-Wno-dev --log-level=ERROR "
        "-DLLVM_ENABLE_LIBCXX=1 "
        "&& ninja --quiet -C {output.build} libc "

rule build_libcxx:
    input:
        directory("llvm/{bin}/libcxx"),
        directory("llvm/{bin}/libcxxabi"),
        clang = "compilers/{bin}/llvm/bin/clang",
        clangxx = "compilers/{bin}/llvm/bin/clang++",
        cflags = "compilers/{bin}/cflags",
    output:
        build = directory("libraries/{bin}/libcxx"),
        lib_cxx = "libraries/{bin}/libcxx/lib/libc++.a",
        lib_cxxabi = "libraries/{bin}/libcxx/lib/libc++abi.a",
    params:
        llvm_src = "llvm/{bin}"
    threads: 8
    shell:
        "rm -rf {output.build} && "
        "cmake -S {params.llvm_src}/runtimes -B {output.build} -DCMAKE_BUILD_TYPE=Release "
        "-DCMAKE_C_COMPILER=$PWD/{input.clang} -DCMAKE_CXX_COMPILER=$PWD/{input.clangxx} "
        "-DCMAKE_C_FLAGS=\"$(cat {input.cflags})\" -DCMAKE_CXX_FLAGS=\"$(cat {input.cflags})\" -DLLVM_ENABLE_RUNTIMES='libcxx;libcxxabi' "
        "-Wno-dev --log-level=ERROR "
        "&& ninja --quiet -C {output.build} cxx cxxabi "

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
        bindir = "{bench}/bin/{bin}",
        rundir = "{bench}/bin/{bin}/run",
        workload_args = lambda wildcards: get_input(wildcards).args,
        mem = lambda wildcards: get_input(wildcards).mem_size,
        stack = lambda wildcards: get_input(wildcards).stack_size,
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
        bbhist_txt = "{dir,.*}/bbhist.txt",
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
        srclist_txt = "{dir,.*}/srclist.txt",
        srclocs_py = "helpers/srclocs.py",
    output:
        srclocs = "{dir,.*}/srclocs.txt"
    shell:
        "{input.srclocs_py} < {input.srclist_txt} > {output.srclocs}"

rule lehist:
    input:
        bbhist_txt = "{dir,.*}/bbhist.txt",
        srclocs_txt = "{dir,.*}/srclocs.txt",
        lehist_py = "helpers/lehist.py",
    output:
        lehist_txt = "{dir,.*}/lehist.txt"
    shell:
        "{input.lehist_py} --bbhist={input.bbhist_txt} --srclocs={input.srclocs_txt} > {output.lehist_txt}"

rule shlocedges:
    input:
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

rule bbv:
    input:
        waypoints_txt = "{bench}/cpt/{input}/{bingroup}/{bin}/waypoints.txt",
        gem5 = gem5_pin_exe,
        bbv_py = gem5_pin_configs + "/pin-bbv.py",
        exe = "{bench}/bin/{bin}/exe",
        argfile = "{bench}/inputs/{input}",
    output:
        bbv_txt = "{bench}/cpt/{input}/{bingroup}/{bin}/bbv.txt",
        bbvinfo_txt = "{bench}/cpt/{input}/{bingroup}/{bin}/bbvinfo.txt",
    params:
        outdir = "{bench}/cpt/{input}/{bingroup}/{bin}/bbv",
        rundir = "{bench}/bin/{bin}/run",
        warmup = warmup,
        interval = interval,
    shell:
        "if [ -d {params.outdir} ]; then rm -r {params.outdir}; fi && "
        "{input.gem5} -re --silent-redirect -d {params.outdir} {input.bbv_py} --stdin=/dev/null --stdout=stdout.txt --stderr=stderr.txt "
        "--mem-size=512MiB --max-stack-size=8MiB --chdir={params.rundir} --bbv={output.bbv_txt} --bbvinfo={output.bbvinfo_txt} "
        "--warmup={params.warmup} --interval={params.interval} --waypoints={input.waypoints_txt} "
        "-- {input.exe} $(cat {input.argfile})"

rule intervals:
    input:
        bbv_txt = "{dir,.*}/bbv.txt",
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
        simpoints_json = "{bench}/cpt/{input}/{bingroup}/simpoints.json",
        waypoints_txt = "{bench}/cpt/{input}/{bingroup}/{bin}/waypoints.txt",
        gem5 = gem5_pin_exe,
        checkpoint_py = gem5_pin_configs + "/pin-cpt.py",
        exe = "{bench}/bin/{bin}/exe",
        argfile = "{bench}/inputs/{input}",
    output:
        directory("{bench}/cpt/{input}/{bingroup}/{bin}/cpt")
    params:
        outdir = "{bench}/cpt/{input}/{bingroup}/{bin}/cpt",
        rundir = "{bench}/bin/{bin}/run",
    shell:
        "if [ -d {params.outdir} ]; then rm -r {params.outdir}; fi && " \
        "{input.gem5} -re --silent-redirect -d {params.outdir} " \
        "{input.checkpoint_py} --stdin=/dev/null --stdout=stdout.txt --stderr=stderr.txt " \
        "--mem-size=512MiB --max-stack-size=8MiB --chdir={params.rundir} " \
        "--simpoints-json={input.simpoints_json} --waypoints={input.waypoints_txt} " \
        "-- {input.exe} $(cat {input.argfile})"

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
        run_script = "../gem5/{sim}/configs/AlderLake/se.py",
        exe = "{bench}/bin/{bin}/exe",
        argfile = "{bench}/inputs/{input}",
        hwconfig = "hwconfs/{hwconf}",
    output:
        stats_txt = "{bench}/exp/{input}/{bingroup}/{bin}/{sim}/{hwconf}/{cptid}/stats.txt"
    params:
        cptdir = "{bench}/cpt/{input}/{bingroup}/{bin}/cpt",
        outdir = "{bench}/exp/{input}/{bingroup}/{bin}/{sim}/{hwconf}/{cptid}",
        rundir = "{bench}/bin/{bin}/run",
    shell:
        "if [ -d {params.outdir} ]; then rm -r {params.outdir}; fi && "
        "{input.gem5} -re --silent-redirect -d {params.outdir} "
        "{input.run_script} --input=/dev/null --output=stdout.txt --errout=stderr.txt "
        "--mem-size=512MiB --max-stack-size=8MiB --chdir={params.rundir} "
        "--checkpoint-dir={params.cptdir} "
        "--checkpoint-restore=$(({wildcards.cptid}+1)) "
        "--restore-simpoint-checkpoint "
        "--cmd={input.exe} "
        "--options=\"$(cat {input.argfile})\" "
        "$(cat {input.hwconfig})"


# Rules for building the SPEC benchmarks, and for adding the benchmarks to benches.
# TODO: Explore putting these into the config file?
include: "rules/cpu2017.smk"
