#!/usr/bin/env python3

import argparse
import subprocess
import sys
import os

parser = argparse.ArgumentParser()
parser.add_argument("--wasm2c", required=True)
parser.add_argument("--wasm-linker", required=True)
parser.add_argument("--host-cc", required=True)
parser.add_argument("--wabt-src", required=True)
parser.add_argument("--wabt-bin", required=True)
parser.add_argument("exe")
parser.add_argument("command", nargs="*")
args = parser.parse_args()

# Find the output in the command.
objpath = None
wasmpath = None
linkcmd = [args.wasm_linker, *args.command]
for i, arg in enumerate(linkcmd):
    if arg == "-o":
        objpath = linkcmd[i + 1]
        wasmpath = objpath + ".wasm"
        linkcmd[i + 1] = wasmpath
        break
assert objpath

def runcmd(cmd):
    cmd = " ".join(cmd)
    result = subprocess.run(cmd, shell=True)
    if result.returncode != 0:
        print(f"failed ({result.returncode}): {cmd}", file=sys.stderr)
        exit(1)

# Run the wasmlink command.
runcmd(linkcmd)

# Run the wasm2c command.
def makepath(ext):
    path = wasmpath + ext
    dir, base = os.path.split(path)
    if base[0].isdigit():
        base = "_" + base
    return os.path.join(dir, base)
cpath = makepath(".c")
hpath = makepath(".h")
runcmd([args.wasm2c, wasmpath, "-o", cpath])

# Run the native compile+link command.
nativecmd = [
    args.host_cc, cpath, "-o", objpath,
]
wasm2c_src = os.path.join(args.wabt_src, "wasm2c")
for c in ["wasm-rt-impl.c", "uvwasi-rt.c", "wasm-rt-runner-static.c", "wasm-rt-os-unix.c"]:
    nativecmd.append(os.path.join(wasm2c_src, c))
nativecmd.append("-I" + os.path.join(args.wabt_src, "third_party", "uvwasi", "include"))
nativecmd.append("-I" + wasm2c_src)
nativecmd.append("-I" + os.getcwd())
nativecmd.append(os.path.join(args.wabt_bin, "lib", "libuvwasi_a.a"))
nativecmd.append(os.path.join(args.wabt_bin, "lib", "libuv_a.a"))
# TODO: Add a command-line switch to this script enable static compiling.
nativecmd.append("-lm")
runcmd(nativecmd)
