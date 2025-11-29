rule download_wasi_sdk:
    output:
        "wasm/wasi-sdk/bin/clang",
        "wasm/wasi-sdk/bin/clang++",
    params:
        url = "https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-14/wasi-sdk-14.0-linux.tar.gz"
    shell:
        "rm -r wasm/wasi-sdk && mkdir -p wasm/wasi-sdk "
        " && "
        "wget -O- {params.url} | "
        "tar -C wasm/wasi-sdk -x --gzip --strip-components=1"

rule clone_wabt:
    output:
        directory("wasm/wabt/src")
    shell:
        "git clone https://github.com/StanfordPLArchSec/protean-bench-wabt.git {output} "
        " && "
        "git -C {output} submodule update --init "

rule build_wabt:
    input:
        "wasm/wabt/src"
    output:
        "wasm/wabt/bin/wasm2c",
    params:
        build = "wasm/wabt/src/build",
        install = "wasm/wabt",
    shell:
        "rm -r {params.build} "
        " && "
        "cmake -G Ninja -S {input} -B {params.build} -DCMAKE_BUILD_TYPE=Release "
        "-DCMAKE_INSTALL_PREFIX={params.install} "
        "-DCMAKE_POLICY_VERSION_MINIMUM=3.5 "
        "-DWasmSafetyEnforcement=WASM_USE_GUARD_PAGES "
        " && "
        "cmake --build {params.build} "
        " && "
        "cmake --install {params.build} "

rule build_libuv:
    input:
        "wasm/wabt/src"
    output:
        libuv = "wasm/wabt/lib/libuv_a.a",
        libuvwasi = "wasm/wabt/lib/libuvwasi_a.a",
    params:
        src = "wasm/wabt/src/third_party/uvwasi",
        build = "wasm/wabt/src/third_party/uvwasi/build",
        install = "wasm/wabt",
    shell:
        "rm -r {params.build} "
        " && "
        "cmake -G Ninja -S {params.src} -B {params.build} "
        "-DCMAKE_BUILD_TYPE=Release "
        " && "
        "cmake --build {params.build} "
        " && "
        "cp {params.build}/libuvwasi_a.a {output.libuvwasi} "
        " && "
        "cp {params.build}/_deps/libuv-build/libuv_a.a {output.libuv} "

