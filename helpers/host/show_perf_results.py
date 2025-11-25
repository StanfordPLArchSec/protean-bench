#!/usr/bin/env python3

import argparse
import sys
import os
import re
sys.path.append(os.path.abspath("."))
from benchsuites import benchsuites as suites

parser = argparse.ArgumentParser()
parser.add_argument("--suite", action="append", required=True)
parser.add_argument("--bin", action="append", required=True)
parser.add_argument("--core-type", "-c", choices=["pcore", "ecore"], required=True)
args = parser.parse_args()

benches = set()
for suite in args.suite:
    benches.update(suites[suite])
benches = sorted(benches)

# Print main line.
print("bench", *args.bin)

def get_metric(path, name):
    with open(path) as f:
        for line in f:
            m = re.search(r"([0-9,.]+)\s+cpu_\w+/%s/" % name, line)
            if m:
                val = m.group(1).replace(",", "")
                return float(val)

for bench in benches:
    out = [bench]
    for bin in args.bin:
        perf_txt = os.path.join(bench, "host", "0", bin, f"perf.{args.core_type}.txt")
        metric = get_metric(perf_txt, "ref-cycles")
        out.append(metric)
    print(*out)
