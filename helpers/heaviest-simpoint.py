#!/usr/bin/env python3

import json
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("simpoints_json", nargs="+")
parser.add_argument("--verbose", "-v", action="store_true")
args = parser.parse_args()

for path in args.simpoints_json:
    with open(path) as f:
        j = json.load(f)
    x = max(j, key=lambda x: x["weight"])
    name = x["name"]
    if args.verbose:
        print(path, name)
    else:
        print(name)
