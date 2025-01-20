from bench import make_bench

make_bench("bearssl").add_input("chacha20_ct")

rule clone_bearssl:
    input:
        patch = "bearssl.patch",
    output:
        git_repo = directory("bearssl/bin/{bin}/git"),
    params:
        git_url = "https://www.bearssl.org/git/BearSSL"
    shell:
        "git clone {params.git_url} {output.git_repo} && "
        "(cd {output.git_repo} && git apply) < {input.patch} "

# TODO: Link against our libc.
rule build_bearssl:
    input:
        # TODO: Inherit from common rule?
        clang = "compilers/{bin}/llvm/bin/clang",
        cflags = "compilers/{bin}/cflags", # TODO: This should be in a config file.
        git_repo = "bearssl/bin/{bin}/git",
    output:
        exe = "bearssl/bin/{bin}/exe",
        run = directory("bearssl/bin/{bin}/run"),
    threads: 8
    shell:
        "CC=$(realpath {input.clang}) "
        "CFLAGS=\"$(cat {input.cflags})\" "
        "make -C {input.git_repo} -B -s -j$(nproc) && " # Remake everything every time.
        "ln -sf git/build/testspeed {output.exe} && "
        "ln -sf . {output.run} "
