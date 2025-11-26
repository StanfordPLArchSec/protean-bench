#!/usr/bin/env python3

import sys
import re

for line in sys.stdin:
    if 'ss' in line:
        continue
    if m := re.search(r'mov\s+(\w+),(\w+)', line):
        ra, rb = m.groups()
        if ra == rb:
            print(line.strip())
        
    
