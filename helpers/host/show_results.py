#!/usr/bin/env python3

import argparse
import sys
import os
import json
import re
sys.path.append(os.path.abspath("."))
from benchsuites import benchsuites as suites

parser = argparse.ArgumentParser()
parser.add_argument("--suite", required=True)
parser.add_argument("--bin", required=True, action="append")
args = parser.parse_args()

def to_int(s):
    return int("".join(s.split(",")))

out = ["bench"]
for bin in args.bin:
    out.append(bin + ".perf")
    out.append(bin + ".simpoint")
print(*out)

benches = suites[args.suite]
for bench in benches:
    out = [bench]
    for bin in args.bin:
        dir = os.path.join(bench, "host", "0", bin)

        # Process perf.txt.
        with open(os.path.join(dir, "perf.txt")) as f:
            for line in f:
                m = re.search(r"\s*([0-9,]+)\s+cpu.*instructions", line)
                if m:
                    perf_insts = to_int(m.group(1))
                m = re.search(r"\s*([0-9,]+)\s+cpu.*ref-cycles", line)
                if m:
                    perf_cycles = to_int(m.group(1))
        perf_ipc = perf_insts / perf_cycles

        # Process results.json
        with open(os.path.join(dir, "results.json")) as f:
            j = json.load(f)
        simpoint_ipc = j["results"]["ipc"]

        out.extend([perf_ipc, simpoint_ipc])

    print(*out)


        
