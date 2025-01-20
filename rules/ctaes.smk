from bench import make_bench

make_bench("ctaes").add_input()

# TODO: Factor out this code; use inheritance.
rule clone_ctaes:
    output:
        git_repo = directory("ctaes/bin/{bin}/git")
    params:
        git_url = "https://github.com/nmosier/ctaes"
    shell:
        "git clone {params.git_url} {output.git_repo}"

rule build_ctaes:
    input:
        # TODO: Inherit from common rule?
        clang = "compilers/{bin}/llvm/bin/clang",
        cflags = "compilers/{bin}/cflags", # TODO: This should be in a config file.
        git_repo = "ctaes/bin/{bin}/git",
    output:
        exe = "ctaes/bin/{bin}/exe",
        run = directory("ctaes/bin/{bin}/run"),
    shell:
        "{input.clang} {input.git_repo}/ctaes.c {input.git_repo}/bench.c -o {output.exe} $(cat {input.cflags}) && "
        "ln -sf . {output.run} "
