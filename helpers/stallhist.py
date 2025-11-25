#!/usr/bin/env python3

import sys
import collections
import argparse
import re

parser = argparse.ArgumentParser()
parser.add_argument("--regex", type=re.compile)
args = parser.parse_args()

hist = collections.defaultdict(int)

def handle_line(line):
    tokens = line.strip().split()
    if len(tokens) == 0:
        return
    if tokens[0] != 'STALL:':
        return
    if args.regex and not args.regex.search(line):
        return
    if len(tokens) < 4:
        return
    stall, uop, pc, n, *rest = tokens
    hist[pc] += int(n)

# STALL: 0x6eafb0 500 ::   MOVQ_XMM_M : ldfp   %xmm1_low, DS:[rdi]
for line in sys.stdin:
    handle_line(line)

l = list(hist.items())
l.sort(key = lambda x: -x[1])

for pc, n in l:
    print(n, pc)

