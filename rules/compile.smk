def get_compiler_addons(wildcards):
    addons_dir = expand("compilers/{bin}/addons", bin=wildcards.bin)
    assert len(addons_dir) == 1
    addons_dir = addons_dir[0]
    addons = wildcards.addons.split(".")
    return expand("compilers/{bin}/addons/{addon}", bin=wildcards.bin, addon=addons)

def compiler_stamp(cc, f):
    return f"compilers/{cc}/.{f}.stamp"

# TODO: Can actually simplify this using recursion. We only need to support the tail addon and recursively generate the others.
# TODO: Rather than stamping, we could just provide the actual files that are used.
rule derivative_compiler:
    input:
        build = compiler_stamp("{bin}", "build"),
        cflags = "compilers/{bin}/cflags",
        fflags = "compilers/{bin}/fflags",
        src = compiler_stamp("{bin}", "src"),
        addons = lambda wildcards: get_compiler_addons(wildcards)
    output:
        build = compiler_stamp("{bin}.{addons}", "build"),
        clang = "compilers/{bin}.{addons}/build/bin/clang",
        clangxx = "compilers/{bin}.{addons}/build/bin/clang++",
        flang = "compilers/{bin}.{addons}/build/bin/flang-new",
        cflags = "compilers/{bin}.{addons}/cflags",
        fflags = "compilers/{bin}.{addons}/fflags",
        src = compiler_stamp("{bin}.{addons}", "src"),
    params:
        indir = "compilers/{bin}",
        outdir = "compilers/{bin}.{addons}",
    wildcard_constraints:
        bin = r"\w+",
        addons = r"\w+(\.\w+)*",
    shell:
        "rm -rf {params.outdir} && mkdir {params.outdir} && "
        "ln -s ../../{params.indir}/build {params.outdir}/build && touch {output.build} && "
        "ln -s ../../{params.indir}/src {params.outdir}/src && touch {output.src} && "
        "echo $(cat {input.cflags} {input.addons}) > {output.cflags} && "
        "echo $(cat {input.fflags} {input.addons}) > {output.fflags} "
