#!/usr/bin/env python3

import argparse
import json

parser = argparse.ArgumentParser()
parser.add_argument("--bench", "-b", required=True)
parser.add_argument("--group", "-g", required=True)
args = parser.parse_args()

path = f"{args.bench}/cpt/0/{args.group}/simpoints.json"
with open(path) as f:
    j = json.load(f)

m = max(j, key=lambda x: x["weight"])
print(m["name"])
