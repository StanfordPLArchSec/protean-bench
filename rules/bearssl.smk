from bench import make_bench

make_bench("bearssl").add_input("chacha20_ct")

rule clone_bearssl:
    input:
        clang = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang",
        patch = "rules/bearssl.patch",
        conf = "rules/bearssl.mk",
        libc = "libraries/{bin}/libc/projects/libc/lib/libllvmlibc.a",
    output:
        git_repo = directory("bearssl/bin/{bin}/git"),
    params:
        cflags = get_cflags,
        git_url = "https://www.bearssl.org/git/BearSSL",
        commit = "3d9be2f60b7764e46836514bcd6e453abdfa864a",
    shell:
        "git clone {params.git_url} {output.git_repo} && "
        "git -C {output.git_repo} checkout {params.commit} && "
        "(cd {output.git_repo} && git apply) < {input.patch} && "
        "CC=$(realpath {input.clang}) "
        "CFLAGS=\"{params.cflags}\" "
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
