#!/usr/bin/env python3

import argparse
import json

def read_input(path):
    with open(path) as f:
        return json.load(f)

parser = argparse.ArgumentParser()
parser.add_argument("--output", "-o", required=True, help="Path to output JSON")
parser.add_argument("--strict", action="store_true")
parser.add_argument("inputs", nargs="+", help="Paths to individual benchmark input JSONs",
                    type=read_input)
args = parser.parse_args()

inputs = args.inputs

# Get keys.
assert len(inputs) > 0
keys = set(inputs[0]['stats'].keys())
for i, input in enumerate(inputs):
    if input['stats'].keys() != keys:
        print(f'found mismatch in results keys at index {i}!', file = sys.stderr)
        a = set(keys)
        b = set(input['stats'].keys())
        for key in a - b:
            print(f'only in 0: {key}', file = sys.stderr)
        for key in b - a:
            print(f'only in {i}: {key}', file = sys.stderr)
        if args.strict:
            exit(1)
        keys &= set(input['stats'].keys())

total_stats = collections.defaultdict(lambda: [])
for input in inputs:
    for key in keys:
        value = input["stats"][key]
        if math.isnan(value):
            continue
        total_stats[key].append(value)

for key, l in total_stats.items():
    total_stats[key] = {
        "arithmean": sum(l) / len(l),
        "geomean": math.prod(l) ** (1 / len(l)),
    }
results = {
    "stats": total_stats
}

with open(args.output, "wt") as f:
    json.dump(results, f, indent=4)
