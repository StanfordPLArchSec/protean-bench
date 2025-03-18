#!/usr/bin/env python3

import argparse
import os
import sys

parser = argparse.ArgumentParser()
parser.add_argument("--speculation-model", "-s", required=True)
parser.add_argument("name")
args = parser.parse_args()

def get_sim_seconds(path):
    t = None
    with open(path) as f:
        for line in f:
            if line.startswith("simSeconds"):
                t = float(line.split()[1])
    return t

defenses = [
    "base/unsafe",
    f"base/spt.{args.speculation_model}",
    f"base/stt.{args.speculation_model}",
    f"sni/tpt.{args.speculation_model}",
]

out = []
for defense in defenses:
    path = os.path.join("parsec", "pkgs", args.name, "run", "exp", defense, "stats.txt")
    t = get_sim_seconds(path)
    if t is None:
        print(f"simSeconds not found in {path}", file=sys.stderr)
        exit(1)
    out.append(f"{t:.6f}")

print(*out)
