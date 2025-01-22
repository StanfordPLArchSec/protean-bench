#!/usr/bin/env python3

import sys
import collections

hist = collections.defaultdict(int)

def handle_line(line):
    tokens = line.strip().split()[2:]
    if tokens[0] != 'stall':
        return
    pc = tokens[1]
    n = int(tokens[2])
    hist[pc] += n

# 5028000: system.switch_cpus.commit: stall 0xb492f0 174500 ::   MOV_R_M : ld   rax, DS:[r13 + 0x18]
for line in sys.stdin:
    handle_line(line)

l = list(hist.items())
l.sort(key = lambda x: -x[1])

for pc, n in l:
    print(n, pc)

