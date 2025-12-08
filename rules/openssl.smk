rule clone_openssl:
    output:
        directory("libraries/{bin}/openssl/src")
    params:
        git_url = "https://github.com/openssl/openssl.git",
        tag = "openssl-3.5.1",
    shell:
        'git clone {params.git_url} {output} -b {params.tag} --depth=1'

rule configure_openssl:
    input:
        src = "libraries/{bin}/openssl/src",
        clang = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang",
        libc = "libraries/{bin}/libc/projects/libc/lib/libllvmlibc.a",
    output:
        directory("libraries/{bin}/openssl/build"),
    params:
        prefix = lambda w: expand("libraries/{bin}/openssl", bin=w.bin),
        cflags = get_cflags,
        ldflags = lambda w: expand("-static -Wl,--allow-multiple-definition -fuse-ld=lld -lm -L$(realpath libraries/{bin}/libc/projects/libc/lib) -lllvmlibc -L$(realpath {llvm}/lib)", bin=w.bin, llvm=get_compiler(w.bin)["bin"]),
    shell:
        'export LDFLAGS="{params.ldflags}" && '
        'export CFLAGS="{params.cflags}" && '
        'export CC=$(realpath {input.clang}) && '
        'PREFIX=$(realpath {params.prefix}) && '
        'rm -rf {output} && mkdir -p {output} && cd {output} && '
        '../src/Configure --prefix=$PREFIX no-asm no-tests no-fuzz'

rule build_openssl:
    input:
        "libraries/{bin}/openssl/build"
    output:
        "libraries/{bin}/openssl/lib64/libssl.a",
        "libraries/{bin}/openssl/lib64/libcrypto.a",
    threads: 8
    shell:
        "make -C {input} -j$(nproc) && "
        "make -C {input} -j$(nproc) install"
