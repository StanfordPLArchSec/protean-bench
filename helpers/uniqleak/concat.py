#!/usr/bin/env python3

import argparse
import os
import gzip
import shutil
import sys
import glob
import re

parser = argparse.ArgumentParser()
parser.add_argument("dir")
args = parser.parse_args()

components = dict()
for subdir in glob.glob(os.path.join(args.dir, "*")):
    if os.path.isdir(subdir) and re.match(r"\d+", os.path.basename(subdir)):
        idx = int(os.path.basename(subdir))
        components[idx] = os.path.join(subdir, "stdout.txt.gz")

for idx in sorted(components.keys()):
    with gzip.open(components[idx], "rt") as f:
        try:
            for line in f:
                sys.stdout.write(line)
        except EOFError:
            pass
