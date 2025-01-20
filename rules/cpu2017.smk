# Rules for building the SPEC benchmarks.

from bench import make_bench

cpu2017_src = "../cpu2017"
test_suite_src = "../test-suite"

def get_cpu2017_int() -> list:
    perlbench = make_bench("600.perlbench_s")
    perlbench.add_input("-I./lib checkspam.pl 2500 5 25 11 150 1 1 1 1")
    perlbench.add_input("-I./lib diffmail.pl 4 800 10 17 19 300")
    perlbench.add_input("-I./lib splitmail.pl 6400 12 26 16 100 0")

    gcc = make_bench("602.gcc_s")
    gcc.add_input("gcc-pp.c -O5 -fipa-pta -o gcc-pp.opts-O5_-fipa-pta.s", mem_size = "16GiB")
    gcc.add_input("gcc-pp.c -O5 -finline-limit=1000 -fselective-scheduling -fselective-scheduling2 -o gcc-pp.opts-O5_-finline-limit_1000_-fselective-scheduling_-fselective-scheduling2.s", mem_size = "4GiB")
    gcc.add_input("gcc-pp.c -O5 -finline-limit=24000 -fgcse -fgcse-las -fgcse-lm -fgcse-sm -o gcc-pp.opts-O5_-finline-limit_24000_-fgcse_-fgcse-las_-fgcse-lm_-fgcse-sm.s", mem_size = "4GiB")

    mcf = make_bench("605.mcf_s").add_input("inp.in", mem_size = "16GiB")

    omnetpp = make_bench("620.omnetpp_s").add_input("-c General -r 0")

    xalancbmk = make_bench("623.xalancbmk_s").add_input("-v t5.xml xalanc.xsl")

    x264 = make_bench("625.x264_s")
    x264.add_input("--pass 1 --stats x264_stats.log --bitrate 1000 --frames 1000 -o BuckBunny_New.264 BuckBunny.yuv 1280x720")
    x264.add_input("--pass 2 --stats x264_stats.log --bitrate 1000 --dumpyuv 200 --frames 1000 -o BuckBunny_New.264 BuckBunny.yuv 1280x720", deps = [x264.inputs[0]])
    x264.add_input("--seek 500 --dumpyuv 200 --frames 1250 -o BuckBunny_New.264 BuckBunny.yuv 1280x720", deps = [x264.inputs[1]])
    
    deepsjeng = make_bench("631.deepsjeng_s").add_input("ref.txt", mem_size = "8GiB")

    leela = make_bench("641.leela_s").add_input("ref.sgf")

    exchange2 = make_bench("648.exchange2_s").add_input("6")

    xz = make_bench("657.xz_s")
    xz.add_input("cpu2006docs.tar.xz 6643 055ce243071129412e9dd0b3b69a21654033a9b723d874b2015c774fac1553d9713be561ca86f74e4f16f22e664fc17a79f30caa5ad2c04fbc447549c2810fae 1036078272 1111795472 4", mem_size = "32GiB")
    xz.add_input("cld.tar.xz 1400 19cf30ae51eddcbefda78dd06014b4b96281456e078ca7c13e1c0c9e6aaea8dff3efb4ad6b0456697718cede6bd5454852652806a657bb56e07d61128434b474 536995164 539938872 8", mem_size = "8GiB")

get_cpu2017_int()

rule build_spec_cpu2017:
    input:
        clang = "compilers/{bin}/llvm/bin/clang",
        clangxx = "compilers/{bin}/llvm/bin/clang++",
        flang = "compilers/{bin}/llvm/bin/flang-new",
        cflags = "compilers/{bin}/cflags",
        fflags = "compilers/{bin}/fflags",
        libc = "libraries/{bin}/libc/projects/libc/lib/libllvmlibc.a",
        libcxx = "libraries/{bin}/libcxx/lib/libc++.a",
        libcxxabi = "libraries/{bin}/libcxx/lib/libc++abi.a",
    output:
        exe = "{bench}/bin/{bin}/exe",
        run = directory("{bench}/bin/{bin}/run"),
    params:
        # TODO: Replace realpath with $PWD for simplicity?
        spec_cpu2017_src = cpu2017_src,
        test_suite_src = test_suite_src,
        test_suite_build = "{bench}/bin/{bin}/test-suite",
        cflags = "-nostdinc++ -nostdlib++ -isystem $PWD/libraries/{bin}/libcxx/include/c++/v1",
        ldflags = "-static -Wl,--allow-multiple-definition -fuse-ld=lld -lm -L$(realpath libraries/{bin}/libc/projects/libc/lib) -lllvmlibc -L$(realpath compilers/{bin}/llvm/lib) -nostdlib++ -L$(realpath libraries/{bin}/libcxx/lib) -lc++ -lc++abi",
    wildcard_constraints:
        bench = r"6\d\d\.[a-zA-Z0-9]+_s"
    threads: 8
    resources:
        mem = "4GiB" # Only 602.gcc_s appears to need this, so far.
    shell:
        "rm -rf {params.test_suite_build} && "
        "cmake -S {params.test_suite_src} -B {params.test_suite_build} -DCMAKE_BUILD_TYPE=Release "
        "-DCMAKE_C_COMPILER=$PWD/{input.clang} -DCMAKE_CXX_COMPILER=$PWD/{input.clangxx} -DCMAKE_Fortran_COMPILER=$PWD/{input.flang} "
        "-DCMAKE_C_FLAGS=\"{params.cflags} $(cat {input.cflags})\" -DCMAKE_CXX_FLAGS=\"{params.cflags} $(cat {input.cflags})\" -DCMAKE_Fortran_FLAGS=\"{params.cflags} $(cat {input.fflags})\" "
        "-DCMAKE_EXE_LINKER_FLAGS=\"{params.ldflags}\" "
        "-DTEST_SUITE_FORTRAN=1 -DTEST_SUITE_SUBDIRS=External -DTEST_SUITE_SPEC2017_ROOT={params.spec_cpu2017_src} "
        "-DTEST_SUITE_RUN_TYPE=ref -DTEST_SUITE_COLLECT_STATS=0 "
        "-Wno-dev --log-level=ERROR "
        "&& cmake --build {params.test_suite_build} --target timeit-target "
        "&& cmake --build {params.test_suite_build} --target {wildcards.bench} "
        "&& BENCH_DIR=$(find {params.test_suite_build} -name {wildcards.bench} -type d) "
        "&& BENCH_DIR=$(realpath $BENCH_DIR) "
        "&& ln -sf $BENCH_DIR/{wildcards.bench} {output.exe} "
        "&& ln -sf $BENCH_DIR/run_ref {output.run} "
