#!/usr/bin/env python3

import sys
import json
import argparse
from collections import defaultdict

parser = argparse.ArgumentParser()
parser.add_argument("--intervals", required=True)
parser.add_argument("--weights", required=True)
parser.add_argument("--bbvs", required=True)
args = parser.parse_args()

def parse_simpoint_file(path, name, type, d):
    with open(path) as f:
        for line in f:
            value, id = line.split()
            id = int(id)
            value = type(value)
            d[id][name] = value

simpoints = defaultdict(dict)
parse_simpoint_file(args.intervals, "interval", int, simpoints)
parse_simpoint_file(args.weights, "weight", float, simpoints)
simpoints = list(simpoints.values())
simpoints.sort(key=lambda simpoint: simpoint["interval"])
for i, simpoint in enumerate(simpoints):
    simpoint["name"] = str(i)

# Parse list of intervals, with their cumulative instruction counts.
bbvs = [0]
with open(args.bbvs) as f:
    for line in f:
        line = line.strip()
        if not line.startswith("T"):
            continue
        line = line.removeprefix("T")
        tokens = line.split()
        bbvs.append(bbvs[-1])
        for token in tokens:
            bbvs[-1] += int(token.split(":")[2])


# For each selected simpoint interval, assign the instruction range.
for simpoint in simpoints:
    i = simpoint["interval"]
    simpoint["instruction_range"] = bbvs[i:i+2]

json.dump(simpoints, sys.stdout, indent=4)
