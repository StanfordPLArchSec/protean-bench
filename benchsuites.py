#!/usr/bin/env python3

benchsuites = {
    "cpu2017.int": [
        "600.perlbench_s",
        "602.gcc_s",
        "605.mcf_s",
        "620.omnetpp_s",
        "623.xalancbmk_s",
        "625.x264_s",
        "631.deepsjeng_s",
        "641.leela_s",
        "648.exchange2_s",
        "657.xz_s",
    ],
    "cpu2017.fp": [
        "603.bwaves_s",
        "607.cactuBSSN_s",
        "619.lbm_s",
        "621.wrf_s",
        # "627.cam4_s",
        "628.pop2_s",
        "638.imagick_s",
        "644.nab_s",
        "649.fotonik3d_s",
        # "654.roms_s",
    ],
    "ctsbench": [
        "ctsbench.hacl.chacha20",
        "ctsbench.hacl.curve25519",
        "ctsbench.hacl.poly1305",
        "ctsbench.libsodium.salsa20",
        "ctsbench.libsodium.sha256",
        "ctsbench.openssl.chacha20",
        "ctsbench.openssl.curve25519",
        "ctsbench.openssl.sha256",
    ],
    "ctbench": [
        "bearssl",
        "ctaes",
        "djbsort",
    ],
    "nctbench": [
        "nctbench.openssl.bnexp",
        "nctbench.openssl.dh",
        "nctbench.openssl.ecadd",
    ],
    "parsec": [
        "apps/blackscholes",
        "apps/ferret",
        "apps/fluidanimate",
        "apps/swaptions",
        "kernels/canneal",
        "kernels/dedup",
    ],
    "wasmbench": [
        "wasm.401.bzip2",
        "wasm.429.mcf",
        "wasm.433.milc",
        "wasm.444.namd",
        "wasm.462.libquantum",
        # "wasm.473.astar",
        "wasm.470.lbm",
    ]
}

benchsuites["cpu2017"] = \
    benchsuites["cpu2017.int"] + \
    benchsuites["cpu2017.fp"]

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("suite", nargs="+")
    parser.add_argument("--sep", default="\n")
    args = parser.parse_args()
    benches = set()
    for suite in args.suite:
        benches.update(benchsuites[suite])
    benches = sorted(list(benches))
    print(args.sep.join(benches))
