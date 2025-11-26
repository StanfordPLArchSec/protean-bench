#!/usr/bin/env python3

import argparse
import os
import sys

parser = argparse.ArgumentParser()
parser.add_argument("exp", nargs="+")
parser.add_argument("--bench", "-b", action="append")
args = parser.parse_args()

if not args.bench:
    args.bench = [
        "apps/blackscholes",
        # "apps/facesim",
        "apps/ferret",
        "apps/fluidanimate",
        # "apps/freqmine",
        # "apps/raytrace",
        "apps/swaptions",
        # "apps/vips",
        # "apps/x264",
        "kernels/canneal",
        "kernels/dedup",
        # "kernels/streamcluster",
    ]

def get_sim_seconds(path):
    t = None
    try:
        with open(path) as f:
            for line in f:
                if line.startswith("simSeconds"):
                    t = float(line.split()[1])
    except:
        pass
    return t

for bench in args.bench:
    out = [bench]
    for exp in args.exp:
        path = os.path.join("parsec", "pkgs", bench, "run", "exp", exp, "stats.txt")
        t = get_sim_seconds(path)
        if t == None:
            out.append("-")
        else:
            out.append(f"{t:.6f}")
    print(*out)
