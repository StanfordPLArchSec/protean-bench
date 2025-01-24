rule build_libc:
    input:
        clang = "compilers/{bin}/llvm/bin/clang",
        clangxx = "compilers/{bin}/llvm/bin/clang++",
        cflags = "compilers/{bin}/cflags",
        llvm_libc_src = "llvm/{bin}/libc",
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
