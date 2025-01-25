def get_compiler_addons(wildcards):
    addons_dir = expand("compilers/{bin}/addons", bin=wildcards.bin)
    assert len(addons_dir) == 1
    addons_dir = addons_dir[0]
    addons = wildcards.addons.split(".")
    return expand("compilers/{bin}/addons/{addon}", bin=wildcards.bin, addon=addons)

rule derivative_compiler:
    input:
        build = "compilers/{bin}/build",
        cflags = "compilers/{bin}/cflags",
        fflags = "compilers/{bin}/fflags",
        src = "compilers/{bin}/src",
        addons = lambda wildcards: get_compiler_addons(wildcards)
    output:
        build = directory("compilers/{bin}.{addons}/build"),
        clang = "compilers/{bin}.{addons}/build/bin/clang",
        clangxx = "compilers/{bin}.{addons}/build/bin/clang++",
        flang = "compilers/{bin}.{addons}/build/bin/flang-new",
        cflags = "compilers/{bin}.{addons}/cflags",
        fflags = "compilers/{bin}.{addons}/fflags",
        src = directory("compilers/{bin}.{addons}/src"),
        src_libc = directory("compilers/{bin}.{addons}/src/libc"),
        src_libcxx = directory("compilers/{bin}.{addons}/src/libcxx"),
        src_libcxxabi = directory("compilers/{bin}.{addons}/src/libcxxabi"),
    params:
        outdir = "compilers/{bin}.{addons}"
    wildcard_constraints:
        bin = r"\w+",
        addons = r"\w+(\.\w+)*",
    shell:
        "rm -r {params.outdir} && mkdir {params.outdir} && "
        "ln -s ../../{input.build} {output.build} && "
        "ln -s ../../{input.src} {output.src} && "
        "echo $(cat {input.cflags} {input.addons}) > {output.cflags} && "
        "echo $(cat {input.fflags} {input.addons}) > {output.fflags} "
