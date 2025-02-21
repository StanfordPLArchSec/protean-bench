#!/usr/bin/env python3

import argparse
from benchsuites import benchsuites
import os

parser = argparse.ArgumentParser()
parser.add_argument("--group", "-g", required=True)
parser.add_argument("--suite", "-s", action="append", default=[])
parser.add_argument("--bench", "-b", action="append", default=[])
parser.add_argument("--exp", "-e", action="append", required=True)
parser.add_argument("--exp-suffix", action="append", default=None)
parser.add_argument("--print", "-p", action="store_true")
parser.add_argument("--skip-bench", action="append", default=[])
parser.add_argument("snakemake_cmd")
parser.add_argument("snakemake_args", nargs="*")
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
        result = os.path.join(bench, "exp", "0", args.group, exp, "results.json")
        cmd.append(result)


cmdv = [args.snakemake_cmd, *args.snakemake_args, *cmd]

if args.print:
    print(*cmdv)
    exit(0)

os.execvp(cmdv[0], cmdv)
