#!/usr/bin/python3

import sys
import math

lines = sys.stdin.readlines()
# FIXME: Detect this programmatically.
print(lines[0].strip())
lines = lines[1:]

n = len(lines[0].split()) - 1

output = ['geomean']
for i in range(n):
    l = list()
    for line in lines:
        l.append(float(line.split()[i+1]))
    output.append(f'{pow(math.prod(l), 1 / len(l)):.4}')
for line in lines:
    print(line, end = '')
print(*output)
