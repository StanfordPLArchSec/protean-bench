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
parser.add_argument("--bingroup", "-g", required=True)
parser.add_argument("--metric", "-m", default="cycles")
parser.add_argument("--suite", "-s", action="extend", type=commalist, default=[])
parser.add_argument("--exp-suffix")
parser.add_argument("--exclude-bench", "-x", action="extend", type=commalist, default=[])
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
        results_json = os.path.join(bench, "exp", input, args.bingroup, exp, "results.json")
        if not os.path.isfile(results_json):
            print(f"file does not exist: {results_json}", file=sys.stderr)
        with open(results_json) as f:
            j = json.load(f)
        metric = j["stats"][args.metric]
        line.append(metric)
    print(*line)
