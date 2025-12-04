from bench import make_bench

make_bench("ctaes").add_input()

# TODO: Factor out this code; use inheritance.
rule clone_ctaes:
    output:
        git_repo = directory("ctaes/bin/{bin}/git")
    params:
        git_url = "https://github.com/bitcoin-core/ctaes",
        commit = "3b10b89b05ca1ef5fff33316777249df25c8b930",
    shell:
        "git clone {params.git_url} {output.git_repo} && "
        "git -C {output.git_repo} checkout {params.commit}"

rule build_ctaes:
    input:
        clang = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang",
        libc = "libraries/{bin}/libc/projects/libc/lib/libllvmlibc.a",
        git_repo = "ctaes/bin/{bin}/git",
    output:
        exe = "ctaes/bin/{bin}/exe",
        run = directory("ctaes/bin/{bin}/run"),
    params:
        cflags = lambda w: get_compiler(w.bin)["cflags"] + ["-O2", "-g"]
    shell:
        "{input.clang} {input.git_repo}/ctaes.c {input.git_repo}/bench.c -o {output.exe} {params.cflags} -static -L$(dirname {input.libc}) -lllvmlibc -fuse-ld=lld && "
        "ln -sf . {output.run} "
