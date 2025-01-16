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

# Parse binary specifications
bins = []
for bin in args.bin:
    bin = types.SimpleNamespace(**parse_subopts(bin))
    bin.cwd = os.path.abspath(bin.cwd)
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
def make_gem5_pincpu_run_cmd(config, script_args):
    return f"if [ -d $outdir ]; then rm -r $outdir; fi && mkdir -p $outdir && /usr/bin/time -vo $outdir/time.txt {args.gem5_exe} {shared_gem5_exe_args} -d $outdir {config} {shared_gem5_script_args} --chdir=$cwd {script_args} -- $bench_exe {args.args}"

ninja.rule(
    name = "bbhist",
    command = make_gem5_pincpu_run_cmd(config = os.path.join(args.gem5_configs, "pin-bbhist.py"), script_args = f"--bbhist=$bbhist"),
    description = "$outdir",
    restat = True,
)

ninja.rule(
    name = "command",
    command = "$cmd",
    description = "$id",
    restat = True
)

# Ninja Builds.

def fixup_cmd_path(bin) -> str:
    if os.path.isabs(args.cmd):
        return args.cmd
    else:
        cmd = os.path.join(bin.cwd, args.cmd)
        assert os.path.isfile(cmd)
        return cmd

# bbhist - all
def build_binary_bbhist(bin, dir: str, variables: dict):
    outdir = f"{dir}/bbhist"
    bbhist_txt = get_bbhist_txt(bin)
    bbhist_py = f"{args.gem5_configs}/pin-bbhist.py"
    ninja.build(
        outputs = [bbhist_txt],
        rule = "bbhist",
        inputs = [args.gem5_exe, bbhist_py, fixup_cmd_path(bin)],
        variables = {
            **variables,
            "outdir": outdir,
            "bbhist": bbhist_txt,
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
        inputs = [instlist_txt, fixup_cmd_path(bin)],
        variables = {
            "id": srclist_txt,
            "cmd": f"llvm-addr2line --exe {fixup_cmd_path(bin)} --output-style=JSON < {instlist_txt} > {srclist_txt}",
        },
    )

# srclocs - all
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

def build_binary(bin, dir: str):
    variables = {
        "cwd": os.path.join(dir, "run"),
        "bench_exe": fixup_cmd_path(bin),
    }

    # Phase 1: bbhist
    build_binary_bbhist(bin = bin, dir = dir, variables = variables)

    # instlist, srclist
    # TODO: These can be piped to each other.
    build_binary_instlist(bin)
    build_binary_srclist(bin)
    build_binary_srclocs(bin)
    build_binary_lehist(bin)

def build_all():
    for bin in bins:
        build_binary(bin = bin, dir = bin.name)

build_all()
