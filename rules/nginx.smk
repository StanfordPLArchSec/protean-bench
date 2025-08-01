rule clone_nginx:
    input:
        libssl = os.path.abspath("libraries/{bin}/openssl/lib64/libssl.a"),
        libcrypto = os.path.abspath("libraries/{bin}/openssl/lib64/libcrypto.a"),
    output:
        directory("applications/{bin}/nginx/src")
    params:
        git_url = "https://github.com/nginx/nginx",
        git_tag = "release-1.29.0",
    shell:
        "git clone {params.git_url} {output} -b {params.git_tag} --depth=1 && "
        "cd {output} && "
        "sed -i 's|-lssl -lcrypto|{input.libssl} {input.libcrypto}|g' auto/lib/openssl/conf && "
        "./auto/configure --prefix=$PWD/.. --with-http_ssl_module --with-ld-opt='-static'"

rule build_nginx:
    input:
        src = "applications/{bin}/nginx/src",
        conf = "rules/nginx.zip",
    output:
        "applications/{bin}/nginx/sbin/nginx"
    params:
        conf = lambda w: expand("applications/{bin}/nginx/conf", bin=w.bin)
    shell:
        "make -C {input.src} -j`nproc` && "
        "make -C {input.src} -j`nproc` install && "
        "unzip -f {input.conf} -d {params.conf}"
