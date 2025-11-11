from bench import make_bench

make_bench("ctsbench.libsodium.salsa20").add_input("8192 400000")
make_bench("ctsbench.libsodium.sha256").add_input("8192 400000")
make_bench("ctsbench.openssl.chacha20").add_input("8192 400000")
make_bench("ctsbench.openssl.sha256").add_input("8192 400000")
make_bench("ctsbench.openssl.curve25519").add_input("400000")
make_bench("ctsbench.hacl.chacha20").add_input("8192 400000")
make_bench("ctsbench.hacl.curve25519").add_input("400000")
make_bench("ctsbench.hacl.poly1305").add_input("8192 400000")
    
rule build_libsodium_bench:
    input:
        src = "../ctsbench/bench-libsodium-{bench}.c",
        lib = "libraries/{bin}/libsodium/lib/libsodium.a",
        clang = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang",
        libc = "libraries/{bin}/libc/projects/libc/lib/libllvmlibc.a",        
    output:
        "ctsbench.libsodium.{bench}/bin/{bin}/exe"
    params:
        libsodium = lambda w: expand("libraries/{bin}/libsodium", bin=w.bin),
        cflags = get_cflags,
        ldflags = lambda w: expand("-static -Wl,--allow-multiple-definition -fuse-ld=lld -lm -L$(realpath libraries/{bin}/libc/projects/libc/lib) -lllvmlibc", bin=w.bin, llvm=get_compiler(w.bin)["bin"]),
        run = "ctsbench.libsodium.{bench}/bin/{bin}/run",
    shell:
        'rm -rf {params.run} && '
        'mkdir -p {params.run} && '
        '{input.clang} {input.src} {input.lib} {params.cflags} {params.ldflags} -o {output}'

        
rule build_openssl_bench:
    input:
        src = "../{suite}/bench-openssl-{bench}.c",
        libs = lambda w: expand("libraries/{bin}/openssl/lib64/lib{name}.a", bin=w.bin, name=["crypto", "ssl"]),
        clang = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang",
        libc = "libraries/{bin}/libc/projects/libc/lib/libllvmlibc.a",        
    output:
        "{suite}.openssl.{bench}/bin/{bin}/exe"
    params:
        openssl = lambda w: expand("libraries/{bin}/openssl", bin=w.bin),
        cflags = lambda w: get_cflags,
        ldflags = lambda w: expand("-static -Wl,--allow-multiple-definition -fuse-ld=lld -lm -L$(realpath libraries/{bin}/libc/projects/libc/lib) -lllvmlibc", bin=w.bin, llvm=get_compiler(w.bin)["bin"]),
        run = "{suite}.openssl.{bench}/bin/{bin}/run",
    shell:
        'rm -rf {params.run} && '
        'mkdir -p {params.run} && '
        '{input.clang} {input.src} {input.libs} {params.cflags} {params.ldflags} -o {output}'

rule build_hacl_bench:
    input:
        src = "../ctsbench/bench-hacl-{bench}.c",
        srcdir = "libraries/{bin}/hacl/src",
        clang = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang",
        libc = "libraries/{bin}/libc/projects/libc/lib/libllvmlibc.a",        
    output:
        "ctsbench.hacl.{bench}/bin/{bin}/exe",
    params:
        srcs = lambda w: expand("libraries/{bin}/hacl/src/dist/gcc-compatible/{src}",
                                bin=w.bin,
                                src=["Hacl_Chacha20.c", "Hacl_Poly1305_32.c", "Hacl_Curve25519_51.c"]),
        includes = lambda w: expand("-Ilibraries/{bin}/hacl/src/dist/{incdir}",
                                    bin=w.bin,
                                    incdir=["gcc-compatible", "karamel/include", "karamel/krmllib/dist/minimal", "kremlin/include", "kremlin/kremlib/dist/minimal"]),
        run = "ctsbench.hacl.{bench}/bin/{bin}/run",
        cflags = lambda w: get_cflags,
        ldflags = lambda w: expand("-static -Wl,--allow-multiple-definition -fuse-ld=lld -lm -L$(realpath libraries/{bin}/libc/projects/libc/lib) -lllvmlibc", bin=w.bin, llvm=get_compiler(w.bin)["bin"]),
    shell:
        'rm -rf {params.run} && '
        'mkdir -p {params.run} && '
        '{input.clang} {input.src} {params.srcs} {params.includes} {params.cflags} {params.ldflags} -o {output}'
