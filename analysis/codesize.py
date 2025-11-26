#!/usr/bin/env python3

import sys
import os
import subprocess

benches = ["600.perlbench_s", "602.gcc_s", "605.mcf_s", "620.omnetpp_s", "623.xalancbmk_s", "625.x264_s", "631.deepsjeng_s", "641.leela_s", "648.exchange2_s", "657.xz_s"]
bins = ["base", "cts", "ct", "nct"]

print("bench", *bins)

for bench in benches:
    tokens = [bench]
    for bin in bins:
        exe = f"{bench}/bin/{bin}/exe"
        assert os.path.isfile(exe)
        output = subprocess.check_output(["size", exe], text=True)
        lines = output.strip().splitlines()
        text_size = int(lines[1].split()[0])
        tokens.append(text_size)
    print(*tokens)
