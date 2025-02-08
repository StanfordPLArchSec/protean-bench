#!/usr/bin/env python3

import argparse
import gzip
import enum
import re
import collections
import sys

parser = argparse.ArgumentParser()
parser.add_argument("--stalls", required=True)
parser.add_argument("--leaks", required=True)
parser.add_argument("--verbose", action="store_true")
args = parser.parse_args()

def open_file(path):
    if path.endswith(".gz"):
        return gzip.open(path, "rt")
    else:
        return open(path, "rt")

class Leak(enum.Enum):
    NO = "unsat"
    MAY = "unknown"
    YES = "sat"

# Map from uop number to leak.
leaks = dict()
leak_matcher = re.compile(r"(unsat|unknown|sat)")
try:
    with open_file(args.leaks) as f:
        for line in f:
            # [0.0s] YESLEAK: 3 JNZ_I : wrip   t1, t2
            result, uop = line.split()
            leak = Leak(result)
            uop = int(uop)
            leaks[uop] = leak
except EOFError:
    pass

# Now, parse the stalls.
stalls = dict()
try:
    with open_file(args.stalls) as f:
        for line in f:
            # STALL: 136 0xa8adee 1000 ::   CALL_NEAR_M : ld   t1, DS:[r9 + 0x50]
            tokens = line.split()
            if tokens[0] == "STALL:":
                uop = int(tokens[1])
                stall = int(tokens[3])
                stalls[uop] = stall
except EOFError:
    pass

# Compute full stats.
counts = collections.defaultdict(int)
missing = 0
for stall_uop, stall_cycles in stalls.items():
    if stall_uop not in leaks:
        missing += 1
        if args.verbose:
            print(f"warning: missing leak info for stalled uop {stall_uop}", file=sys.stderr)
        continue
    counts[leaks[stall_uop]] += stall_cycles

for leak, count in counts.items():
    print(leak, count)
print("missing", missing)
