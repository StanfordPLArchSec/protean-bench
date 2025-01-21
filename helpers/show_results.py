#!/usr/bin/env python3

import sys
import os
import argparse
import json

parser = argparse.ArgumentParser()
parser.add_argument("--bench", "-b", action="append", required=True)
parser.add_argument("--exp", "-e", action="append", required=True)
parser.add_argument("--quiet", "-q", action="store_true")
args = parser.parse_args()
input = "0" # TODO: Don't hard-code this.
bingroup = "main" # TODO: Don't hard-code this.

if not args.quiet:
    print("bench", *args.exp)

for bench in args.bench:
    if not os.path.isdir(bench):
        print(f"not a benchmark directory: {bench}", file=sys.stderr)
        exit(1)
    line = [bench]
    for exp in args.exp:
        results_json = os.path.join(bench, "exp", input, bingroup, exp, "results.json")
        if not os.path.isfile(results_json):
            print(f"file does not exist: {results_json}", file=sys.stderr)
        with open(results_json) as f:
            j = json.load(f)
        cycles = j["stats"]["cycles"]
        line.append(cycles)
    print(*line)
