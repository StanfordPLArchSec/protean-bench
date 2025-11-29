import bench

bench.make_bench("wasm.401.bzip2").add_input("data/ref/input/input.source 280", mem_size="10GiB")
bench.make_bench("wasm.429.mcf").add_input("data/ref/input/inp.in", mem_size="10GiB")
bench.make_bench("wasm.462.libquantum").add_input("1397 8", mem_size="10GiB")
bench.make_bench("wasm.473.astar").add_input("BigLakes2048.cfg", mem_size="10GiB")
bench.make_bench("wasm.433.milc").add_input(stdin="data/ref/input/su3imp.in", mem_size="10GiB")
bench.make_bench("wasm.444.namd").add_input("--input data/all/input/namd.input --iterations 38 --output namd.out", mem_size="10GiB")
bench.make_bench("wasm.470.lbm").add_input("3000 reference.dat 0 0 100_100_130_ldc.of", mem_size="10GiB")

def cpu2006_type(w):
    int = {"401.bzip2", "429.mcf", "462.libquantum", "473.astar"}
    fp = {"433.milc", "444.namd", "470.lbm"}
    if w.bench in int:
        return "INT"
    elif w.bench in fp:
        return "FP"
    raise ValueError(f"cpu2006 benchmark {w.bench} has unknown type")

rule build_wasm_cpu2006:
    input:
        wasi_clang = "wasm/wasi-sdk/bin/clang",
        wasi_clangxx = "wasm/wasi-sdk/bin/clang++",
        host_clang = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang",
        wasm_link = "helpers/wasm-link.py",
        wasm2c = "wasm/wabt/bin/wasm2c",
        libuv = "wasm/wabt/lib/libuv_a.a",
        libuvwasi = "wasm/wabt/lib/libuvwasi_a.a",
    output:
        exe = "wasm.{bench}/bin/{bin}/exe",
    params:
        cpu2006_src = "../cpu2006",
        test_suite_src = "../test-suite",
        test_suite_build = "wasm.{bench}/bin/{bin}/test-suite",
        cflags = "-g -w -D_WASI_EMULATED_SIGNAL -D_WASI_EMULATED_PROCESS_CLOCKS -Wno-implicit-function-declaration -Wno-int-conversion",
        cxxflags = "-g -w -D_WASI_EMULATED_SIGNAL -D_WASI_EMULATED_PROCESS_CLOCKS -Wno-c++11-narrowing -Wno-reserved-user-defined-literal -std=c++11",
        run = "wasm.{bench}/bin/{bin}/run",
        wabt_src = "wasm/wabt/src",
        wabt_bin = "wasm/wabt",
        type = cpu2006_type,
    wildcard_constraints:
        bench = r"4\d\d\.[a-zA-Z0-9]+"
    threads: 8
    resources:
        # mem = compile_mem
    shell:
        "rm -rf {params.test_suite_build} && "
        "cmake -G Ninja -S {params.test_suite_src} -B {params.test_suite_build} "
        "-DCMAKE_BUILD_TYPE=RelWithDebInfo "
        "-DCMAKE_C_COMPILER=$PWD/{input.wasi_clang} "
        "-DCMAKE_CXX_COMPILER=$PWD/{input.wasi_clangxx} "
        "-DCMAKE_C_FLAGS=\"{params.cflags}\" "
        "-DCMAKE_CXX_FLAGS=\"{params.cxxflags}\" "
        "-DCMAKE_C_LINKER_LAUNCHER=\"$PWD/{input.wasm_link};--wasm2c=$PWD/{input.wasm2c};--wasm-linker=$PWD/{input.wasi_clang} -lwasi-emulated-signal -lwasi-emulated-process-clocks -Wl,--global-base=150000 -Wl,-z,stack-size=1048576 -Wl,--growable-table -fno-pie -no-pie -static;--host-cc=$PWD/{input.host_clang} -O2 -g -lm -mno-avx -fno-pie -no-pie -static -DWASM_USE_GUARD_PAGES;--wabt-src=$PWD/{params.wabt_src};--wabt-bin=$PWD/{params.wabt_bin};--\" "
        "-DCMAKE_CXX_LINKER_LAUNCHER=\"$PWD/{input.wasm_link};--wasm2c=$PWD/{input.wasm2c};--wasm-linker=$PWD/{input.wasi_clangxx} -std=c++11 -lwasi-emulated-signal -lwasi-emulated-process-clocks -Wl,--global-base=150000 -Wl,-z,stack-size=1048576 -Wl,--growable-table -fno-pie -no-pie -static;--host-cc=$PWD/{input.host_clang} -O2 -g -lm -mno-avx -fno-pie -no-pie -static -DWASM_USE_GUARD_PAGES;--wabt-src=$PWD/{params.wabt_src};--wabt-bin=$PWD/{params.wabt_bin};--\" "
        "-DTEST_SUITE_SUBDIRS=External "
        "-DTEST_SUITE_SPEC2006_ROOT={params.cpu2006_src} "
        "-Wno-dev --log-level=ERROR "
        "-DTEST_SUITE_COLLECT_CODE_SIZE=0 "
        "-DTEST_SUITE_COLLECT_COMPILE_TIME=0 "
        "-DTEST_SUITE_USE_PERF=1 "
        " && "
        # "cmake --build {params.test_suite_build} --target timeit-target "
        # " && "
        "cmake --build {params.test_suite_build} --target {wildcards.bench} "
        " && "
        "BENCH_DIR=$PWD/{params.test_suite_build}/External/SPEC/C{params.type}2006/{wildcards.bench} "
        " && "
        "ln -f $BENCH_DIR/{wildcards.bench} {output.exe} "
        " && "
        "ls $BENCH_DIR"
        " && "
        "ln -sf $BENCH_DIR {params.run} "

