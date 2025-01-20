

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
        clang = "compilers/{bin}/llvm/bin/clang",
        cflags = "compilers/{bin}/cflags", # TODO: This should be in a config file.        
        src = "djbsort/bin/{bin}/src"
    output:
        exe = "djbsort/bin/{bin}/exe",
        run = directory("djbsort/bin/{bin}/run"),
    shell:
        "echo $(realpath {input.clang}) $(cat {input.cflags}) > {input.src}/compilers/c && "
        "(cd {input.src} && ./build && ./test && ./upgrade) && "
        "ln -sf src/link-install/command/int32-speed {output.exe} && "
        "ln -sf . {output.run}"
