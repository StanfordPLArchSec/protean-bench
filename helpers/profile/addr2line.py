#!/usr/bin/env python3

import argparse
import subprocess
import sys
import json
import types
import os

parser = argparse.ArgumentParser()
parser.add_argument("--exe", required=True)
parser.add_argument("--addr2line", required=True)
parser.add_argument("--field", "-f", type=int, required=True)
parser.add_argument("--basename", action="store_true")
args = parser.parse_args()

process = subprocess.Popen([args.addr2line, "--exe", args.exe, "--output-style=JSON"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, bufsize=1)

def get_filename(filename):
    return os.path.basename(filename) if args.basename else filename

for line in sys.stdin:
    line = line.strip()
    tokens = line.split()
    key = tokens[args.field]
    print(key, file=process.stdin)
    process.stdin.flush()

    j = process.stdout.readline()
    j = types.SimpleNamespace(**json.loads(j))

    info = types.SimpleNamespace(**j.Symbol[0])
    print(line, f"{get_filename(info.FileName)}:{info.Line}:{info.Column}")
