#!/usr/bin/env python3

import os
import argparse
import gzip
import sys
import itertools

def open_file(path, mode):
    if path.endswith(".gz"):
        return gzip.open(path, mode)
    else:
        return open(path, mode)

parser = argparse.ArgumentParser()
parser.add_argument("--window", "-n", type=int, required=True)
parser.add_argument("input", nargs="?", type=lambda path: open_file(path, "rt"), default=sys.stdin)
parser.add_argument("--outdir", required=True)
args = parser.parse_args()

num_intervals = 0
interval_end = -1

os.makedirs(args.outdir, exist_ok=True)

for i, window in enumerate(itertools.batched(args.input, args.window)):
    subdir = os.path.join(args.outdir, str(i))
    os.mkdir(subdir)
    subutrace = os.path.join(subdir, "utrace.txt.gz")
    with gzip.open(subutrace, "wt", compresslevel=5) as out:
        out.writelines(window)
    print(f"Wrote interval {i}", file=sys.stderr)

print(i)
