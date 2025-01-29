rule build_libc:
    input:
        clang = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang",
        clangxx = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang++",
    output:
        build = directory("libraries/{bin}/libc"),
        lib = "libraries/{bin}/libc/projects/libc/lib/libllvmlibc.a",
    params:
        src = lambda w: get_compiler(w.bin)["src"],
        cflags = lambda w: get_compiler(w.bin)["cflags"],
    threads: 8
    shell:
        "rm -rf {output.build} && "
        "cmake -S {params.src}/llvm -B {output.build} -DCMAKE_BUILD_TYPE=RelWithDebInfo "
        "-DCMAKE_C_COMPILER=$(realpath {input.clang}) -DCMAKE_CXX_COMPILER=$(realpath {input.clangxx}) "
        "-DCMAKE_C_FLAGS=\"{params.cflags}\" -DCMAKE_CXX_FLAGS=\"{params.cflags}\" -DLLVM_ENABLE_PROJECTS=libc "
        "-Wno-dev --log-level=ERROR "
        "-DLLVM_ENABLE_LIBCXX=1 "
        "&& ninja --quiet -C {output.build} libc "
