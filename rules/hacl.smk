rule clone_hacl:
    output:
        directory("libraries/{bin}/hacl/src")
    params:
        git_url = "https://github.com/hacl-star/hacl-star.git",
        git_tag = "ocaml-v0.4.5",
    shell:
        "git clone {params.git_url} -b {params.git_tag} {output}"


def get_hacl_srcs(w, suffix):
    return expand("libraries/{bin}/hacl/src/dist/gcc-compatible/{src}{suffix}",
                  bin=w.bin, src=["Hacl_Chacha20", "Hacl_Poly1305_32", "Hacl_Curve25519_51"],
                  suffix=suffix)

rule build_hacl:
    input:
        src = "libraries/{bin}/hacl/src",
        clang = get_clang,
        ld = lambda w: get_compiler(w.bin)["bin"] + "/bin/ld.lld",
    output:
        "libraries/{bin}/hacl/lib/hacl.o"
    params:
        cflags = get_cflags,
        ldflags = lambda w: expand("-static -Wl,--allow-multiple-definition -fuse-ld=lld -lm -L$(realpath libraries/{bin}/libc/projects/libc/lib) -lllvmlibc -L$(realpath {llvm}/lib)", bin=w.bin, llvm=get_compiler(w.bin)["bin"]),
        srcs = lambda w: get_hacl_srcs(w, ".c"),
        objs = lambda w: get_hacl_srcs(w, ".o"),
        includes = lambda w: expand("-Ilibraries/{bin}/hacl/src/dist/{incdir}",
                                    bin=w.bin,
                                    incdir=["gcc-compatible", "karamel/include", "karamel/krmllib/dist/minimal", "kremlin/include", "kremlin/kremlib/dist/minimal"]),        
    shell:
        "{input.clang} {params.srcs} {params.includes} -c && "
        "{input.ld} -r {params.objs} -o {output}"
        
    
