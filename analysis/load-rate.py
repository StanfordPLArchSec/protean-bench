#!/usr/bin/env python3

import argparse
import json
import sys

parser = argparse.ArgumentParser()
parser.add_argument("bench", nargs="+")
args = parser.parse_args()

data = []
for bench in args.bench:
    try:
        with open(f"{bench}/exp/0/main/base/unsafe.pcore/results.json") as f:
            j = json.load(f)
    except FileNotFoundError as e:
        print(f'WARN: {bench} missing file', file=sys.stderr)
        continue
    try:
        x = j["stats"]["load-rate"]
    except KeyError as e:
        print(f'WARN: {bench} missing key', file=sys.stderr)
        continue

    data.append(x)
    print(bench, x)

def avg(*v):
    return sum(v) / len(v)

print("mean", avg(*data))
    
