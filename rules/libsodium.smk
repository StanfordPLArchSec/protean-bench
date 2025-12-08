rule clone_libsodium:
    output:
        directory("libraries/{bin}/libsodium/src")
    params:
        git_url = "https://github.com/jedisct1/libsodium.git",
        git_tag = "1.0.20-RELEASE",
    shell:
        "git clone {params.git_url} {output} -b {params.git_tag}"

rule configure_libsodium:
    input:
        clang = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang",
        src = directory("libraries/{bin}/libsodium/src")
    output:
        directory("libraries/{bin}/libsodium/build")
    params:
        root = lambda w: expand("libraries/{bin}/libsodium", bin=w.bin),
        cflags = get_cflags,
        ldflags = lambda w: expand("-static -Wl,--allow-multiple-definition -fuse-ld=lld -lm -L$(realpath libraries/{bin}/libc/projects/libc/lib) -lllvmlibc -L$(realpath {llvm}/lib)", bin=w.bin, llvm=get_compiler(w.bin)["bin"]),
    shell:
        'export LDFLAGS="{params.ldflags}" && '
        'export CFLAGS="{params.cflags}" && '
        'export CC=$(realpath {input.clang}) && '
        'PREFIX=$(realpath {params.root}) && '
        'rm -rf {output} && mkdir -p {output} && cd {output} && '
        '../src/configure --prefix=$PREFIX --disable-asm'

rule build_libsodium:
    input:
        "libraries/{bin}/libsodium/build"
    output:
        "libraries/{bin}/libsodium/lib/libsodium.a"
    shell:
        'make -C {input} -j$(nproc) && '
        'make -C {input} -j$(nproc) install && '
        'rm -rf {input}/config.log'
