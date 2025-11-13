# Rules for building the SPEC benchmarks.

from rules.cpu2017 import *

def compile_mem(wildcards):
    d = {
        "602.gcc_s": "4GiB",
        "607.cactuBSSN_s": "2GiB",
        "620.omnetpp_s": "2GiB",
        "621.wrf_s": "16GiB",
        "623.xalancbmk_s": "2GiB",
        "628.pop2_s": "2GiB",
        "641.leela_s": "2GiB",
        "627.cam4_s": "8GiB",
    }
    return d.get(wildcards.bench, "1GiB")

rule build_spec_cpu2017:
    input:
        clang = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang",
        clangxx = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang++",
        flang = lambda w: get_compiler(w.bin)["bin"] + "/bin/flang-new",
        libc = "libraries/{bin}/libc/projects/libc/lib/libllvmlibc.a",
        libcxx = "libraries/{bin}/libcxx/lib/libc++.a",
        libcxxabi = "libraries/{bin}/libcxx/lib/libc++abi.a",
    output:
        exe = "{bench}/bin/{bin}/exe",
    params:
        # TODO: Replace realpath with $PWD for simplicity?
        spec_cpu2017_src = cpu2017_src,
        test_suite_src = test_suite_src,
        test_suite_build = "{bench}/bin/{bin}/test-suite",
        compile_flags = "-nostdinc++ -nostdlib++ -isystem $PWD/libraries/{bin}/libcxx/include/c++/v1",
        cflags = lambda w: ["-Wno-implicit-int"] + get_compiler(w.bin)["cflags"],
        fflags = lambda w: get_compiler(w.bin)["fflags"],
        ldflags = lambda w: expand("-static -Wl,--allow-multiple-definition -fuse-ld=lld -lm -L$(realpath libraries/{bin}/libc/projects/libc/lib) -lllvmlibc -L$(realpath {llvm}/lib) -nostdlib++ -L$(realpath libraries/{bin}/libcxx/lib) -lc++ -lc++abi",
                                   bin=w.bin,
                                   llvm=get_compiler(w.bin)["bin"]),
        run = "{bench}/bin/{bin}/run",
        type = lambda wildcards: types[wildcards.bench],
    wildcard_constraints:
        bench = r"6\d\d\.[a-zA-Z0-9]+_s"
    threads: 8
    resources:
        mem = compile_mem,
        runtime = "12h",
    shell:
        "rm -rf {params.test_suite_build} && "
        "cmake -S {params.test_suite_src} -B {params.test_suite_build} -DCMAKE_BUILD_TYPE=RelWithDebInfo "
        "-DCMAKE_C_COMPILER=$PWD/{input.clang} -DCMAKE_CXX_COMPILER=$PWD/{input.clangxx} -DCMAKE_Fortran_COMPILER=$PWD/{input.flang} "
        "-DCMAKE_C_FLAGS=\"{params.compile_flags} {params.cflags}\" -DCMAKE_CXX_FLAGS=\"{params.compile_flags} {params.cflags}\" "
        "-DCMAKE_Fortran_FLAGS=\"{params.compile_flags} {params.fflags}\" "
        "-DCMAKE_EXE_LINKER_FLAGS=\"{params.ldflags}\" "
        "-DTEST_SUITE_FORTRAN=1 -DTEST_SUITE_SUBDIRS=External -DTEST_SUITE_SPEC2017_ROOT={params.spec_cpu2017_src} "
        "-DTEST_SUITE_RUN_TYPE=ref -DTEST_SUITE_COLLECT_STATS=0 "
        "-DTEST_SUITE_COLLECT_CODE_SIZE=0 "
        "-Wno-dev --log-level=ERROR "
        "-DTEST_SUITE_COLLECT_COMPILE_TIME=0 "
        "&& cmake --build {params.test_suite_build} --target timeit-target "
        "&& cmake --build {params.test_suite_build} --target {wildcards.bench} "
        "&& BENCH_DIR=$(realpath {params.test_suite_build}/External/SPEC/C{params.type}2017speed/{wildcards.bench}) "
        "&& ln -sf $BENCH_DIR/{wildcards.bench} {output.exe} "
        "&& ln -sf $BENCH_DIR/run_ref {params.run} "
