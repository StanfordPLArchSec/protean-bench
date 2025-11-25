#!/usr/bin/env python3

import argparse
import json
import sys

parser = argparse.ArgumentParser()
parser.add_argument("--simpoints-json", required=True)
parser.add_argument("--profile", required=True)
args = parser.parse_args()

with open(args.simpoints_json) as f:
    simpoints = json.load(f)

cycles = []
with open(args.profile) as f:
    for line in f:
        tokens = (int(token) for token in line.split())
        cycles.append(tokens)
assert len(cycles) % 2 == 0
cycles = list(zip(cycles[::2], cycles[1::2]))
assert len(cycles) == len(simpoints)

# Annotate simpoints with cycles.
total_cycles = 0
total_ipc = 0
for simpoint, result in zip(simpoints, cycles):
    (begin_inst, begin_cycle), (end_inst, end_cycle) = result
    cycle_count = end_cycle - begin_cycle
    inst_count = end_inst - begin_inst
    ipc = inst_count / cycle_count
    weight = simpoint["weight"]
    simpoint["results"] = {
        "instruction_range": (begin_inst, end_inst),
        "instruction_count": inst_count,
        "cycle_range": (begin_cycle, end_cycle),
        "cycle_count": cycle_count,
        "ipc": ipc,
    }
    total_cycles += cycle_count * weight
    total_ipc += ipc * weight
out = {
    "simpoints": simpoints,
    "results": {
        "cycle_count": total_cycles,
        "ipc": total_ipc,
    }
}

json.dump(out, sys.stdout, indent=4)
