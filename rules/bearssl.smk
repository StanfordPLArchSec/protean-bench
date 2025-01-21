from bench import make_bench

make_bench("bearssl").add_input("chacha20_ct")

rule clone_bearssl:
    input:
        clang = "compilers/{bin}/llvm/bin/clang",
        cflags = "compilers/{bin}/cflags", # TODO: This should be in a config file.
        patch = "rules/bearssl.patch",
        conf = "rules/bearssl.mk",
        libc = "libraries/{bin}/libc/projects/libc/lib/libllvmlibc.a",
    output:
        git_repo = directory("bearssl/bin/{bin}/git"),
    params:
        git_url = "https://www.bearssl.org/git/BearSSL"
    shell:
        "git clone {params.git_url} {output.git_repo} && "
        "(cd {output.git_repo} && git apply) < {input.patch} && "
        "CC=$(realpath {input.clang}) "
        "CFLAGS=\"$(cat {input.cflags})\" "
        "LDFLAGS=\"-L$(realpath $(dirname {input.libc})) -lllvmlibc\" "
        "envsubst < {input.conf} > {output.git_repo}/conf/PTeX.mk"

rule build_bearssl:
    input:
        # TODO: Inherit from common rule?
        git_repo = "bearssl/bin/{bin}/git",
    output:
        exe = "bearssl/bin/{bin}/exe",
        run = directory("bearssl/bin/{bin}/run"),
    threads: 8
    shell:
        "make -C {input.git_repo} CONF=PTeX -B -s -j$(nproc) && " # Remake everything every time.
        "ln -sf git/build/testspeed {output.exe} && "
        "ln -sf . {output.run} "
