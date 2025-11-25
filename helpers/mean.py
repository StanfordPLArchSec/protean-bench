#!/usr/bin/env python3

import sys
import math
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--kind", "-k", choices=["geo", "arith"], default="geo")
parser.add_argument("--skip", "-s", type=int, default=1)
args = parser.parse_args()

lines = sys.stdin.readlines()

for line in lines[:args.skip]:
    print(line.strip())
lines = lines[args.skip:]

def arithmean(*vals):
    return sum(vals) / len(vals)

def geomean(*vals):
    return pow(math.prod(vals), 1/len(vals))

def mean(*vals):
    if args.kind == "geo":
        return geomean(*vals)
    elif args.kind == "arith":
        return arithmean(*vals)
    else:
        assert False, "impossible!"

n = len(lines[0].split()) - 1
output = [args.kind + "mean"]
for i in range(n):
    l = list()
    for line in lines:
        l.append(float(line.split()[i+1]))
    m = mean(*l)
    output.append(f"{m:.4f}")
for line in lines:
    print(line, end="")
print(*output)
