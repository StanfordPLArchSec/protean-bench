#!/usr/bin/env python3

import sys

def parsenum(s: str):
    try:
        return float(s)
    except ValueError:
        return s

for line in sys.stdin:
    tokens = line.split()

    # Skip empty lines.
    if len(tokens) == 0:
        continue

    # If the leader is not an integer,
    # then just fill the rest of the line
    # with -'s.
    leader = parsenum(tokens[1])
    outl = [tokens[0]]
    for token in tokens[1:]:
        value = parsenum(token)
        if isinstance(value, str):
            outl.append(value)
        elif isinstance(leader, str):
            outl.append("-")
        else:
            outl.append(f"{value/leader:.4f}")
    print(*outl)
