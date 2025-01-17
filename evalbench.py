import tomllib
import argparse
import types
import os
import sys

parser = argparse.ArgumentParser()
parser.add_argument("--config", required = True)
parser.add_argument("--bench", required = True)
parser.add_argument("--group", required = True)
parser.add_argument("--bin", required = True)
parser.add_argument("--input", required = True)
parser.add_argument("--exp", required = True)
args = parser.parse_args()

def make_namespace(x):
    if type(x) is list:
        for i, y in enumerate(x):
            x[i] = make_namespace(y)
        return x
    elif type(x) is dict:
        d = dict()
        for k, v in x.items():
            d[k] = make_namespace(v)
        return types.SimpleNamespace(**d)
    else:
        return x

with open(args.config, "rb") as f:
    config = tomllib.load(f)
config = make_namespace(config)


# Config helper functions.
def get_list_entry_by_name(l, name):
    matches = list(filter(lambda item: item.name == name, l))
    assert len(matches) == 1
    return matches[0]

def get_bingroup(name):
    return get_list_entry_by_name(config.bingroup, name)

# First, need to generate simpoints for this.

xsimpoint_py = os.path.join(os.path.dirname(__file__), "xsimpoint.py")

args.group = get_bingroup(args.group)

# Read input file.
with open(os.path.join(args.bench, "inputs", args.input)) as f:
    workload_args = f.read().strip().split()

xsimpoint_cmd = [
    xsimpoint_py,
    "--outdir", os.path.join(args.bench, "cpt", args.input, args.group.name),
    "--gem5-exe", os.path.join(config.gem5.pin, config.gem5.suffix),
    "--gem5-configs", os.path.join(config.gem5.pin, "configs"),
    "--simpoint", config.simpoint,    
]
for bin in args.group.bins:
    name = bin
    cwd = os.path.join(args.bench, "bin", name, "run")
    xsimpoint_cmd.append(f"--bin={name=},{cwd=}")
xsimpoint_cmd.extend([
    "--",
    os.path.abspath(os.path.join(args.bench, "bin", args.bin, "exe")),
    *workload_args,
])

exit_code = os.system(" ".join(xsimpoint_cmd))
print("TODO", file=sys.stderr)
exit(exit_code)
    
# xsimpoint_cmd.append(f"--outdir"
    
# ./crossbin-simpoint.py
# --bin name=base,cwd=../bench-ninja/sw/base/test-suite/External/SPEC/CINT2017speed/625.x264_s/run_ref
# --bin name=nst,cwd=../bench-ninja/sw/ptex-nst/test-suite/External/SPEC/CINT2017speed/625.x264_s/run_ref
# --outdir out --gem5-exe ../gem5/pincpu/build/X86/gem5.opt --gem5-configs ../gem5/pincpu/configs --simpoint ../simpoint/bin/simpoint --
# ../625.x264_s --pass 1 --stats x264_stats.log --bitrate 1000 --frames 1000 -o BuckBunny_New.264 BuckBunny.yuv 1280x720
