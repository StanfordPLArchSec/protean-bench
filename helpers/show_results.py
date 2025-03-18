#!/usr/bin/env python3

import sys
import os
import argparse
import json
import re

sys.path.append(".")
from benchsuites import benchsuites

def commalist(s):
    return s.split(",")

parser = argparse.ArgumentParser()
parser.add_argument("--bench", "-b", action="extend", type=commalist, default=[])
parser.add_argument("--exp", "-e", action="extend", type=commalist, default=[])
parser.add_argument("--quiet", "-q", action="store_true")
parser.add_argument("--group", "-g")
parser.add_argument("--metric", "-m", default="cycles")
parser.add_argument("--suite", "-s", action="extend", type=commalist, default=[])
parser.add_argument("--exp-suffix", action="append")
parser.add_argument("--exclude-bench", "--skip-bench", "-x", action="extend", type=commalist, default=[])
parser.add_argument("--check-time")
parser.add_argument("exps", nargs="*")
args = parser.parse_args()
args.exp.extend(args.exps)
input = "0" # TODO: Don't hard-code this.

# Collect list of benches.
benches = set(args.bench)
for suite in args.suite:
    benches.update(benchsuites[suite])
def should_include_bench(bench):
    return not any([re.search(x, bench) for x in args.exclude_bench])
benches = filter(should_include_bench, benches)
benches = sorted(list(benches))

if not args.exp_suffix or len(args.exp_suffix) == 0:
    args.exp_suffix = [""]

def print_with_suffix(exp_suffix):
    if not args.quiet:
        print("bench", *[exp + exp_suffix for exp in args.exp])
    for bench in benches:
        if not os.path.isdir(bench):
            print(f"not a benchmark directory: {bench}", file=sys.stderr)
            exit(1)
        line = [bench]
        for exp in args.exp:
            exp += exp_suffix
            if args.group:
                exp = os.path.join(args.group, exp)
            results_json = os.path.join(bench, "exp", input, exp, "results.json")
            try:
                with open(results_json) as f:
                    j = json.load(f)
                metric = j["stats"][args.metric]
            except FileNotFoundError:
                metric = "-"
            line.append(metric)
        print(*line)

for exp_suffix in args.exp_suffix:
    print_with_suffix(exp_suffix)
