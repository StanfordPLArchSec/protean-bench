#!/usr/bin/python3

import argparse
import types
import ninja_syntax
import os

parser = argparse.ArgumentParser()
parser.add_argument("cmd")
parser.add_argument("args", nargs = "*")
parser.add_argument("--bin", "-b", action = "append", default = [])
parser.add_argument("--mem-size", default = "512MiB")
parser.add_argument("--stack-size", default = "8MiB")
parser.add_argument("--stdin", default = "/dev/null")
parser.add_argument("--outdir", "-o", required = True)
parser.add_argument("--gem5-exe", required = True, type = os.path.abspath)
parser.add_argument("--gem5-configs", required = True, type = os.path.abspath)
parser.add_argument("--warmup", type = int, default = 10000000)
parser.add_argument("--interval", type = int, default = 50000000)
parser.add_argument("--simpoint", required = True, type = os.path.abspath)
parser.add_argument("--num-simpoints", "-k", type = int, default = 10)
args = parser.parse_args()
args.args = " ".join(args.args)

def parse_subopts(s):
    d = dict()
    for subopt in s.split(","):
        kvs = subopt.split("=", maxsplit=1)
        if len(kvs) == 1:
            kvs.append(None)
        key, value = kvs
        d[key] = value
    return d

def get_helper_dir():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), "helpers"))

def get_helper(name):
    return os.path.join(get_helper_dir(), name)

# TODO: Replace these with members of bin's.
def get_bbhist_txt(bin) -> str:
    return os.path.join(bin.name, "bbhist.txt")

def get_instlist_txt(bin) -> str:
    return os.path.join(bin.name, "instlist.txt")

def get_srclist_txt(bin) -> str:
    return os.path.join(bin.name, "srclist.txt")

def get_srclocs_txt(bin) -> str:
    return os.path.join(bin.name, "srclocs.txt")

def get_lehist_txt(bin) -> str:
    return os.path.join(bin.name, "lehist.txt")

def get_shlocedges_txt() -> str:
    return "shlocedges.txt"

def get_waypoints_txt(bin) -> str:
    return os.path.join(bin.name, "waypoints.txt")

def get_bbv_txt(bin) -> str:
    return os.path.join(bin.name, "bbv.txt")

def get_bbvinfo_txt(bin) -> str:
    return os.path.join(bin.name, "bbvinfo.txt")

def get_intervals_txt(bin) -> str:
    return os.path.join(bin.name, "intervals.txt")

def get_weights_txt(bin) -> str:
    return os.path.join(bin.name, "weights.txt")

def get_simpoints_json() -> str:
    return "simpoints.json"

# Parse binary specifications
bins = []
for bin in args.bin:
    bin = types.SimpleNamespace(**parse_subopts(bin))
    bin.cwd = os.path.abspath(bin.cwd)
    if os.path.isabs(args.cmd):
        bin.exe = args.cmd
    else:
        bin.exe = os.path.join(bin.cwd, args.cmd)
    bins.append(bin)

# Gather (shared) gem5 exe args.
shared_gem5_exe_args = "-re --silent-redirect"

# Gather (shared) gem5 script args.
shared_gem5_script_args = f"--stdin={args.stdin} --stdout=stdout.txt --stderr=stderr.txt --mem-size={args.mem_size} --max-stack-size={args.stack_size}"

# Create the main outdir and start a build.ninja file in it.
# Then change directories into there.
os.makedirs(args.outdir, exist_ok=True)
f = open(os.path.join(args.outdir, "build.ninja"), "wt")
ninja = ninja_syntax.Writer(f)
os.chdir(args.outdir)

# Create subdirectories for each binary, and symlink 'run' to their rundirs.
for bin in bins:
    dir = bin.name
    os.makedirs(dir, exist_ok=True)
    rundir = os.path.join(dir, "run")
    # TODO: Make paths relative, if possible?
    if os.path.exists(rundir):
        assert os.path.islink(rundir)
        os.unlink(rundir)
    os.symlink(os.path.abspath(bin.cwd), rundir)
    
# Ninja Rules
# TODO: Remove in favor of 'command'.
def make_gem5_pincpu_run_cmd(bin, outdir, gem5_config, gem5_script_args):
    return f"if [ -d {outdir} ]; then rm -r {outdir}; fi && mkdir -p {outdir} && /usr/bin/time -vo {outdir}/time.txt {args.gem5_exe} {shared_gem5_exe_args} -d {outdir} {gem5_config} {shared_gem5_script_args} --chdir={bin.name}/run {gem5_script_args} -- {bin.exe} {args.args}"

ninja.rule(
    name = "command",
    command = "$cmd",
    description = "$id",
    restat = True
)

# Ninja Builds.

# bbhist - all
def build_binary_bbhist(bin):
    outdir = f"{bin.name}/bbhist"
    # TODO: Make function.
    bbhist_py = os.path.join(args.gem5_configs, "pin-bbhist.py")
    bbhist_txt = get_bbhist_txt(bin)
    ninja.build(
        outputs = [bbhist_txt],
        rule = "command",
        inputs = [args.gem5_exe, bbhist_py, bin.exe],
        variables = {
            "id": bbhist_txt,
            "cmd": make_gem5_pincpu_run_cmd(bin = bin, outdir = outdir, gem5_config = bbhist_py, gem5_script_args = f"--bbhist={bbhist_txt}"),
        },
    )

# instlist - all
def build_binary_instlist(bin):
    instlist_txt = get_instlist_txt(bin)
    bbhist_txt = get_bbhist_txt(bin)
    instlist_py = get_helper("instlist.py")
    ninja.build(
        outputs = [instlist_txt],
        rule = "command",
        inputs = [bbhist_txt, instlist_py],
        variables = {
            "id": instlist_txt,
            "cmd": f"{instlist_py} < {bbhist_txt} > {instlist_txt}",
        },
    )

# srclist - all
def build_binary_srclist(bin):
    instlist_txt = get_instlist_txt(bin)
    srclist_txt = get_srclist_txt(bin)
    ninja.build(
        outputs = [srclist_txt],
        rule = "command",
        inputs = [instlist_txt, bin.exe],
        variables = {
            "id": srclist_txt,
            "cmd": f"llvm-addr2line --exe {bin.exe} --output-style=JSON < {instlist_txt} > {srclist_txt}",
        },
    )

# srclocs - all
# TODO: Rename to locmap.txt?
def build_binary_srclocs(bin):
    srclocs_txt = get_srclocs_txt(bin)
    srclist_txt = get_srclist_txt(bin)
    srclocs_py = get_helper("srclocs.py")
    ninja.build(
        outputs = [srclocs_txt],
        rule = "command",
        inputs = [srclist_txt, srclocs_py],
        variables = {
            "id": srclocs_txt,
            "cmd": f"{srclocs_py} < {srclist_txt} > {srclocs_txt}",
        },
    )

# lehist - all
def build_binary_lehist(bin):
    lehist_txt = get_lehist_txt(bin)
    bbhist_txt = get_bbhist_txt(bin)
    srclocs_txt = get_srclocs_txt(bin)
    lehist_py = get_helper("lehist.py")
    ninja.build(
        outputs = [lehist_txt],
        rule = "command",
        inputs = [lehist_py, bbhist_txt, srclocs_txt],
        variables = {
            "id": lehist_txt,
            "cmd": f"{lehist_py} --bbhist {bbhist_txt} --srclocs {srclocs_txt} > {lehist_txt}",
        },
    )

def build_shlocedges(lehist_txts: list):
    shlocedges_txt = get_shlocedges_txt()
    shlocedges_py = get_helper("shlocedges.py")
    ninja.build(
        outputs = [shlocedges_txt],
        rule = "command",
        inputs = [shlocedges_py, *lehist_txts],
        variables = {
            "id": shlocedges_txt,
            "cmd": "{} {} > {}".format(shlocedges_py, " ".join(lehist_txts), shlocedges_txt),
        },
    )

def build_binary_waypoints(bin):
    waypoints_txt = get_waypoints_txt(bin)
    bbhist_txt = get_bbhist_txt(bin)
    shlocedges_txt = get_shlocedges_txt()
    srclocs_txt = get_srclocs_txt(bin)
    waypoints_py = get_helper("waypoints.py")
    ninja.build(
        outputs = [waypoints_txt],
        rule = "command",
        inputs = [waypoints_py, bbhist_txt, shlocedges_txt, srclocs_txt],
        variables = {
            "id": waypoints_txt,
            "cmd": f"{waypoints_py} --bbhist={bbhist_txt} --shlocedges={shlocedges_txt} --srclocs={srclocs_txt} > {waypoints_txt}",
        },
    )

def build_binary_bbv(bin):
    bbv_txt = get_bbv_txt(bin)
    bbvinfo_txt = get_bbvinfo_txt(bin)
    waypoints_txt = get_waypoints_txt(bin)
    # TODO: Make function.
    bbv_py = os.path.join(args.gem5_configs, "pin-bbv.py")
    ninja.build(
        outputs = [bbv_txt, bbvinfo_txt],
        rule = "command",
        inputs = [args.gem5_exe, bbv_py, waypoints_txt],
        variables = {
            "id": bbv_txt,
            "cmd": make_gem5_pincpu_run_cmd(bin = bin, outdir = os.path.join(bin.name, "bbv"), gem5_config = bbv_py, gem5_script_args = f"--bbv={bbv_txt} --bbvinfo={bbvinfo_txt} --warmup={args.warmup} --interval={args.interval} --waypoints={waypoints_txt}"),
        },
    )

def build_binary_intervals(bin):
    outdir = os.path.join(bin.name, "intervals")
    intervals_txt = get_intervals_txt(bin)
    weights_txt = get_weights_txt(bin)
    bbv_txt = get_bbv_txt(bin)
    ninja.build(
        outputs = [intervals_txt, weights_txt],
        rule = "command",
        inputs = [bbv_txt],
        variables = {
            "id": intervals_txt,
            "cmd": f"if [ -d {outdir} ]; then rm -r {outdir}; fi && mkdir {outdir} && {args.simpoint} -loadFVFile {bbv_txt} -maxK {args.num_simpoints} -saveSimpoints {intervals_txt} -saveSimpointWeights {weights_txt} -fixedLength off > {outdir}/stdout 2> {outdir}/stderr",
        },
    )

def build_simpoints_json(bin):
    simpoints_py = get_helper("simpoints.py")
    simpoints_json = get_simpoints_json()
    intervals_txt = get_intervals_txt(bin)
    weights_txt = get_weights_txt(bin)
    bbvinfo_txt = get_bbvinfo_txt(bin)
    ninja.build(
        outputs = [simpoints_json],
        rule = "command",
        inputs = [simpoints_py, intervals_txt, weights_txt],
        variables = {
            "id": simpoints_json,
            "cmd": f"{simpoints_py} --intervals={intervals_txt} --weights={weights_txt} --bbvinfo={bbvinfo_txt} > {simpoints_json}",
        },
    )

def build_all(bins):
    for bin in bins:
        build_binary_bbhist(bin)
        build_binary_instlist(bin)
        build_binary_srclist(bin)
        build_binary_srclocs(bin)
        build_binary_lehist(bin)

    # Compute shared srcloc edges.
    build_shlocedges([get_lehist_txt(bin) for bin in bins])

    for bin in bins:
        build_binary_waypoints(bin)

    build_binary_bbv(bins[0])
    build_binary_intervals(bins[0])
    build_simpoints_json(bins[0])

build_all(bins)
