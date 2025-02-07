#!/usr/bin/env python3

import argparse
import sys

parser = argparse.ArgumentParser()
args = parser.parse_args()

n = 0
for line in sys.stdin:
    if not line.startswith("T "):
        continue
    tokens = line.split()[1:]
    for token in tokens:
        x = token.split(":")[2]
        n += int(x)

print(n)

                 
