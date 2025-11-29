rule clone_siege:
    output:
        directory("../siege/src")
    params:
        url = "https://github.com/JoeDog/siege.git",
        commit = "b6dd58517bcf7f89eaec29583fedab659f8ce51e",
    shell:
        "rm -rf {output} && "
        "mkdir -p {output} && "
        "git clone {params.url} {output} && "
        "git -C {output} checkout {params.commit} "

rule build_siege:
    output:
        "../siege/bin/siege"
    input:
        "../siege/src"
    params:
        prefix = "../siege",
        build = "../siege/build",
    shell:
        "prefix=$PWD/{params.prefix} && "
        "rm -rf {params.build} && mkdir -p {params.build} && cd {params.build} && "
        "{input}/configure --prefix=$prefix && "
        "make -j$(nproc) && "
        "make install "
