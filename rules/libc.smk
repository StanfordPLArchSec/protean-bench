rule build_libc:
    input:
        clang = "compilers/{bin}/build/bin/clang",
        clangxx = "compilers/{bin}/build/bin/clang++",
        cflags = "compilers/{bin}/cflags",
        src = compiler_stamp("{bin}", "src"),
    output:
        build = directory("libraries/{bin}/libc"),
        lib = "libraries/{bin}/libc/projects/libc/lib/libllvmlibc.a",
    params:
        src = "compilers/{bin}/src",
    threads: 8
    shell:
        "rm -rf {output.build} && "
        "cmake -S {params.src}/llvm -B {output.build} -DCMAKE_BUILD_TYPE=RelWithDebInfo "
        "-DCMAKE_C_COMPILER=$PWD/{input.clang} -DCMAKE_CXX_COMPILER=$PWD/{input.clangxx} "
        "-DCMAKE_C_FLAGS=\"$(cat {input.cflags})\" -DCMAKE_CXX_FLAGS=\"$(cat {input.cflags})\" -DLLVM_ENABLE_PROJECTS=libc "
        "-Wno-dev --log-level=ERROR "
        "-DLLVM_ENABLE_LIBCXX=1 "
        "&& ninja --quiet -C {output.build} libc "
