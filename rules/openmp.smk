rule build_openmp:
    input:
        clang = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang",
        clangxx = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang++",
    output:
        build = directory("libraries/{bin}/openmp"),
        header = "libraries/{bin}/openmp/runtime/src/omp.h",
        library = "libraries/{bin}/openmp/runtime/src/libomp.a",
    params:
        llvm_src = lambda w: get_compiler(w.bin)["src"],
        llvm_dir = lambda w: get_compiler(w.bin)["bin"] + "/lib/cmake/llvm",
        cflags = lambda w: get_compiler(w.bin)["cflags"],
    threads: 8
    shell:
        "rm -rf {output.build} && "
        "cmake -S {params.llvm_src}/openmp -B {output.build} -DCMAKE_BUILD_TYPE=RelWithDebInfo "
        "-DCMAKE_C_COMPILER=$(realpath {input.clang}) -DCMAKE_CXX_COMPILER=$(realpath {input.clangxx}) "
        "-DCMAKE_C_FLAGS=\"{params.cflags}\" -DCMAKE_CXX_FLAGS=\"{params.cflags}\" "
        "-DLLVM_DIR=$(realpath {params.llvm_dir}) "
        "-DLIBOMP_ENABLE_SHARED=0 -DLIBOMP_USE_HWLOC=0 "
        "-Wno-dev --log-level=ERROR "
        "&& ninja --quiet -C {output.build} omp"

