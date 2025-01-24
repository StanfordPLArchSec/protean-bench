rule build_libcxx:
    input:
        "llvm/{bin}/libcxx",
        "llvm/{bin}/libcxxabi",
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
