#!/usr/bin/env python3

import argparse
import sys

parser = argparse.ArgumentParser()
args = parser.parse_args()

total_insts = 0
for line in sys.stdin:
    if not line.startswith("T "):
        continue
    tokens = line.split()[1:]
    line_insts = 0
    for token in tokens:
        x = token.split(":")[2]
        line_insts += int(x)
    print(line_insts)
    total_insts += line_insts
print(total_insts)

                 
