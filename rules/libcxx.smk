rule build_libcxx:
    input:
        clang = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang",
        clangxx = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang++",
    output:
        build = directory("libraries/{bin}/libcxx"),
        lib_cxx = "libraries/{bin}/libcxx/lib/libc++.a",
        lib_cxxabi = "libraries/{bin}/libcxx/lib/libc++abi.a",
    params:
        llvm_runtimes_src = lambda w: get_compiler(w.bin)["src"] + "/runtimes",
        cflags = lambda w: get_compiler(w.bin)["cflags"],
    threads: 8
    resources:
        mem = "4GiB"         
    shell:
        "rm -rf {output.build} && "
        "cmake -S {params.llvm_runtimes_src} -B {output.build} -DCMAKE_BUILD_TYPE=RelWithDebInfo "
        "-DCMAKE_C_COMPILER=$PWD/{input.clang} -DCMAKE_CXX_COMPILER=$PWD/{input.clangxx} "
        "-DCMAKE_C_FLAGS=\"{params.cflags}\" -DCMAKE_CXX_FLAGS=\"{params.cflags}\" -DLLVM_ENABLE_RUNTIMES='libcxx;libcxxabi' "
        "-Wno-dev --log-level=ERROR "
        "&& ninja --quiet -C {output.build} cxx cxxabi "
