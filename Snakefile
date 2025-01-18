import glob

# TODO: Move these to config file?
gem5_pin_src = "../gem5/pincpu"
gem5_pin_exe = gem5_pin_src + "/build/X86/gem5.opt"
gem5_pin_configs = gem5_pin_src + "/configs"
# TODO: Use this using the 'bin' setup.
addr2line = "../llvm/base-17/build/bin/llvm-addr2line"
spec_cpu2017_src = "../cpu2017"
test_suite_src = "../test-suite"

# TODO: Define these in the filesystem, too.
bingroups = {
    "main": ["base", "nst"],
}

warmup = 10000000
interval = 50000000
simpoint_exe = "../simpoint/bin/simpoint"
num_simpoints = 10

rule build_libc:
    input:
        clang = "compilers/{bin}/bin/clang",
        clangxx = "compilers/{bin}/bin/clang++",
        llvm_libc_src = directory("llvm/{bin}/libc"),
    output:
        build = directory("libraries/{bin}/libc"),
        lib = "libraries/{bin}/libc/projects/libc/lib/libllvmlibc.a",
    params:
        llvm_src = "llvm/{bin}",
    shell:
        "rm -rf {output.build} && "
        "cmake -S {params.llvm_src}/llvm -B {output.build} -DCMAKE_BUILD_TYPE=Release "
        "-DCMAKE_C_COMPILER=$(realpath {input.clang}) -DCMAKE_CXX_COMPILER=$(realpath {input.clangxx}) "
        "-DCMAKE_C_FLAGS='-O3 -g' -DCMAKE_CXX_FLAGS='-O3 -g' -DLLVM_ENABLE_PROJECTS=libc "
        "&& cmake --build {output.build} --target libc "

rule build_spec_cpu2017:
    input:
        clang = "compilers/{bin}/bin/clang",
        clangxx = "compilers/{bin}/bin/clang++",
        flang = "compilers/{bin}/bin/flang-new",
    output:
        exe = "{bench}/bin/{bin}/exe",
        run = directory("{bench}/bin/{bin}/run"),
    params:
        spec_cpu2017_src = spec_cpu2017_src,
        test_suite_src = test_suite_src,
        test_suite_build = "{bench}/bin/{bin}/test-suite",
    wildcard_constraints:
        bench = r"6\d\d\.[a-zA-Z0-9]+_s"
    shell:
        "rm -rf {params.test_suite_build} && "
        "cmake -S {params.test_suite_src} -B {params.test_suite_build} -DCMAKE_BUILD_TYPE=Release "
        "-DCMAKE_C_COMPILER=$(realpath {input.clang}) -DCMAKE_CXX_COMPILER=$(realpath {input.clangxx}) -DCMAKE_Fortran_COMPILER=$(realpath {input.flang}) "
        "-DCMAKE_C_FLAGS='-O3 -g' -DCMAKE_CXX_FLAGS='-O3 -g' -DCMAKE_Fortran_FLAGS='-O2 -g' "
        "-DCMAKE_EXE_LINKER_FLAGS=\"-static -Wl,--allow-multiple-definition -fuse-ld=lld -lm -L$(realpath compilers/{wildcards.bin}/lib)\" "
        "-DTEST_SUITE_FORTRAN=1 -DTEST_SUITE_SUBDIRS=External -DTEST_SUITE_SPEC2017_ROOT={params.spec_cpu2017_src} "
        "-DTEST_SUITE_RUN_TYPE=ref -DTEST_SUITE_COLLECT_STATS=0 "
        "&& cmake --build {params.test_suite_build} --target timeit-target "
        "&& cmake --build {params.test_suite_build} --target {wildcards.bench} "
        "&& BENCH_DIR=$(find {params.test_suite_build} -name {wildcards.bench} -type d) "
        "&& BENCH_DIR=$(realpath $BENCH_DIR) "
        "&& ln -sf $BENCH_DIR/{wildcards.bench} {output.exe} "
        "&& ln -sf $BENCH_DIR/run_ref {output.run} "
        
rule bbhist:
    input:
        gem5 = gem5_pin_exe,
        bbhist_py = gem5_pin_configs + "/pin-bbhist.py",
        exe = "{bench}/bin/{bin}/exe",
        argfile = "{bench}/inputs/{input}",
    output:
        bbhist_txt = "{bench}/cpt/{input}/{bingroup}/{bin}/bbhist.txt",
    params:
        bindir = "{bench}/bin/{bin}",
        # TODO: Remove this.
        exe = "{bench}/bin/{bin}/exe",
        rundir = "{bench}/bin/{bin}/run",
        outdir = "{bench}/cpt/{input}/{bingroup}/{bin}/bbhist",
    shell:
        "if [ -d {params.outdir} ]; then rm -r {params.outdir}; fi && " \
        "{input.gem5} -re --silent-redirect -d {params.outdir} " \
        "{input.bbhist_py} --stdin=/dev/null --stdout=stdout.txt --stderr=stderr.txt " \
        "--mem-size=512MiB --max-stack-size=8MiB --chdir={params.rundir} " \
        "--bbhist={output.bbhist_txt} " \
        "-- {input.exe} $(cat {input.argfile})"

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
