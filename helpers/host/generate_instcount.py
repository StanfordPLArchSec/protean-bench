#!/usr/bin/env python3

import json
import sys

simpoints = json.load(sys.stdin)
for simpoint in simpoints:
    insts = simpoint["instruction_range"]
    for inst in insts:
        print(inst)

