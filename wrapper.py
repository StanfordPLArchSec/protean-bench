#!/usr/bin/env python3

import argparse
from benchsuites import benchsuites
import os

parser = argparse.ArgumentParser()
parser.add_argument("--bingroup", "-g", required=True)
parser.add_argument("--suite", "-s", action="append", default=[])
parser.add_argument("--bench", "-b", action="append", default=[])
parser.add_argument("--exp", "-e", action="append", required=True)
parser.add_argument("--exp-suffix", action="append", default=None)
parser.add_argument("--print", "-p", action="store_true")
parser.add_argument("--skip-bench", action="append", default=[])
args = parser.parse_args()

# First, get the full list of benchmarks.
benches = set(args.bench)
for suite in args.suite:
    benches.update(benchsuites[suite])
for bench in args.skip_bench:
    benches.remove(bench)
# print("Running benchmarks:", " ".join(benches))

# Then, get the full list of experiments.
exps = set()
if args.exp_suffix:
    for suffix in args.exp_suffix:
        for exp in args.exp:
            exps.add(exp + suffix)
else:
    exps.update(args.exp)

# Construct the snakemake command.
# cmd = ["./snakemake-slurm-apptainer.sh"]
cmd = []
for bench in benches:
    for exp in exps:
        result = os.path.join(bench, "exp", "0", args.bingroup, exp, "results.json")
        cmd.append(result)

if args.print:
    print(*cmd)
    exit(0)

os.execlp("./snakemake-slurm-apptainer.sh", *cmd)

