rule download_wasi_sdk:
    output:
        "wasm/wasi-sdk/bin/clang",
        "wasm/wasi-sdk/bin/clang++",
    shell:
        "wget -O- https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-29/wasi-sdk-29.0-x86_64-linux.tar.gz | "
        "tar -C wasm/wasi-sdk -x --gzip --strip-components=1"

rule download_wabt:
    output:
        directory("wasm/wabt/src")
    shell:
        "git clone https://github.com/WebAssembly/wabt.git -b 1.0.39 {output}"

rule build_wabt:
    input:
        "wasm/wabt/src"
    output:
        "wasm/wabt/bin/wasm2c",
        "wasm/wabt/lib/libuv_a.a",
        "wasm/wabt/lib/libuvwasi_a.a",
    params:
        build = "wasm/wabt/build"
        install = "wasm/wabt",
    shell:
        "cmake -G Ninja -S {input} -B {params.build} -DCMAKE_BUILD_TYPE=Release "
        "-DCMAKE_INSTALL_PREFIX={params.install} "
        "-DWITH_WASI=1 -DCMAKE_POLICY_VERSION_MINIMUM=3.5 && "
        "cmake --build {params.build} && "
        "cmake --install {params.build} && "
        "cp {params.build}/third_party/uvwasi/libuvwasi_a.a {params.install}/lib && "
        "cp {params.build}/_deps/libuv-build/libuv_a.a {params.install}/lib"

