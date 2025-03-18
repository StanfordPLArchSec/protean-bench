import bench

bench.make_bench("djbsort").add_input("")

rule download_djbsort:
    output:
        src = directory("djbsort/bin/{bin}/src")
    params:
        version = "20180729"
    shell:
        "mkdir -p {output.src} && "
        "wget -O- https://sorting.cr.yp.to/djbsort-{params.version}.tar.gz | tar -x --gzip -C {output.src} --strip-components=1 && "
        "rm {output.src}/compilers/c "

rule build_djbsort:
    input: 
        clang = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang",
        libc = "libraries/{bin}/libc/projects/libc/lib/libllvmlibc.a",
        src = "djbsort/bin/{bin}/src"
    output:
        exe = "djbsort/bin/{bin}/exe",
        run = directory("djbsort/bin/{bin}/run"),
    params:
        cflags = lambda w: get_compiler(w.bin)["cflags"] + ["-O2", "-g"],
        ldflags = "-static",
    shell:
        "echo $(realpath {input.clang}) {params.cflags} -static -L$(realpath $(dirname {input.libc})) -lllvmlibc -fuse-ld=lld > {input.src}/compilers/c && "
        "(cd {input.src} && ./build && ./test && ./upgrade) && "
        "ln -sf src/link-install/command/int32-speed {output.exe} && "
        "ln -sf . {output.run}"
