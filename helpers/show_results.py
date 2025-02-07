#!/usr/bin/env python3

import sys
import os
import argparse
import json

sys.path.append(".")
from benchsuites import benchsuites

parser = argparse.ArgumentParser()
parser.add_argument("--bench", "-b", action="append", default=[])
parser.add_argument("--exp", "-e", action="append", required=True)
parser.add_argument("--quiet", "-q", action="store_true")
parser.add_argument("--bingroup", "-g")
parser.add_argument("--metric", "-m", default="cycles")
parser.add_argument("--suite", "-s", action="append", default=[])
parser.add_argument("--exp-suffix")
parser.add_argument("--exclude-bench", "-x", action="append", default=[])
args = parser.parse_args()
input = "0" # TODO: Don't hard-code this.

# Collect list of benches.
benches = set(args.bench)
for suite in args.suite:
    benches.update(benchsuites[suite])
for bench in args.exclude_bench:
    benches.remove(bench)
benches = sorted(list(benches))

if args.exp_suffix:
    for i, exp in enumerate(args.exp):
        args.exp[i] = exp + args.exp_suffix

if not args.quiet:
    print("bench", *args.exp)

for bench in benches:
    if not os.path.isdir(bench):
        print(f"not a benchmark directory: {bench}", file=sys.stderr)
        exit(1)
    line = [bench]
    for exp in args.exp:
        if args.bingroup:
            exp = os.path.join(args.bingroup, exp)
        results_json = os.path.join(bench, "exp", input, exp, "results.json")
        if not os.path.isfile(results_json):
            print(f"file does not exist: {results_json}", file=sys.stderr)
        with open(results_json) as f:
            j = json.load(f)
        metric = j["stats"][args.metric]
        line.append(metric)
    print(*line)
