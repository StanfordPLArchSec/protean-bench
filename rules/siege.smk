rule clone_siege:
    output:
        "../siege/src/utils/bootstrap"
    params:
        url = "https://github.com/JoeDog/siege.git",
        commit = "b6dd58517bcf7f89eaec29583fedab659f8ce51e",
        src = "../siege/src",
    shell:
        "rm -rf {params.src} && "
        "mkdir -p {params.src} && "
        "git clone {params.url} {params.src} && "
        "git -C {params.src} checkout {params.commit} "

rule autoconf_siege:
    input:
        "../siege/src/utils/bootstrap"
    output:
        "../siege/src/configure"
    container: "nginx.sif"
    shell:
        "cd ../siege/src && ./utils/bootstrap"

rule configure_siege:
    output:
        "../siege/src/Makefile"
    input:
        "../siege/src/configure"
    container: "nginx.sif"
    shell:
        "cd ../siege/src && "
        "./configure --prefix=$PWD/.. CPPFLAGS='-include stdint.h -include sys/types.h'"

rule build_siege:
    input:
        "../siege/src/Makefile"
    output:
        "../siege/bin/siege"
    container: "nginx.sif"
    shell:
        "cd ../siege/src && "
        "make && make install"
