#!/usr/bin/env python3

import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument("--exp", "-x", action="append", required=True)
parser.add_argument("--bench", "-b", action="append")
parser.add_argument("snakemake_cmd", nargs="+")
args = parser.parse_args()

cmd = [*args.snakemake_cmd]
benches = [
    "apps/blackscholes",
    "apps/bodytrack",
    "apps/facesim",
    "apps/ferret",
    "apps/fluidanimate",
    "apps/freqmine",
    "apps/raytrace",
    "apps/swaptions",
    "apps/vips",
    "apps/x264",
    "kernels/canneal",
    "kernels/dedup",
    "kernels/streamcluster",
]
if args.bench and len(args.bench) > 0:
    benches = args.bench

for bench in benches:
    for exp in args.exp:
        cmd.append(f"parsec/pkgs/{bench}/run/exp/{exp}/stamp.txt")

os.execvp(cmd[0], cmd)

