rule download_wasi_sdk:
    output:
        "wasm/wasi-sdk/bin/clang",
        "wasm/wasi-sdk/bin/clang++",
    shell:
        "wget -O- https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-29/wasi-sdk-29.0-x86_64-linux.tar.gz | "
        "tar -C wasm/wasi-sdk -x --gzip --strip-components=1"

rule download_wabt:
    output:
        "wasm/wabt/bin/wasm2c"
    shell:
        "wget -O- https://github.com/WebAssembly/wabt/releases/download/1.0.39/wabt-1.0.39-linux-x64.tar.gz | "
        "tar -C wasm/wabt -x --gzip --strip-components=1"
