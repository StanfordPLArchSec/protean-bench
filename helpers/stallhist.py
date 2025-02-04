#!/usr/bin/env python3

import sys
import collections

hist = collections.defaultdict(int)

def handle_line(line):
    tokens = line.strip().split()
    if tokens[0] != 'STALL:':
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

