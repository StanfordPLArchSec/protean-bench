#!/usr/bin/python3

import argparse
import helpers.ninja_syntax as ninja_syntax
import os
import glob
import json

parser = argparse.ArgumentParser()
parser.add_argument("--outdir", "-o", required=True)
parser.add_argument("--indir", "-i", required=True, type=os.path.abspath)
parser.add_argument("gem5_cmd", nargs = "+")
args = parser.parse_args()
args.cptdir = os.path.join(args.indir, "cpt")
args.rundir = os.path.join(args.indir, "run")

# Get gem5 exe and gem5 python script, so we can rebuild if they change.
# Sort the arguments so that we don't end up rerunning things only if the ordering changed.
gem5_exe = os.path.abspath(args.gem5_cmd[0])
gem5_py = list(filter(lambda s: s.endswith(".py"), args.gem5_cmd))
assert len(gem5_py) == 1
gem5_py = os.path.abspath(gem5_py[0])
gem5_py_idx = args.gem5_cmd.index(gem5_py)
gem5_exe_args = args.gem5_cmd[1:gem5_py_idx]
gem5_py_args = args.gem5_cmd[gem5_py_idx+1:]
gem5_exe_args.sort()
gem5_py_args.sort()
args.gem5_cmd = [gem5_exe, *gem5_exe_args, gem5_py, *gem5_py_args]

def get_helper(name):
    return os.path.join(os.path.dirname(__file__), "helpers", name)

# Make the output directory and make the ninja file.
os.makedirs(args.outdir, exist_ok=True)
f = open(os.path.join(args.outdir, "build.ninja"), "wt")
ninja = ninja_syntax.Writer(f)
os.chdir(args.outdir)

# Ninja rules.
ninja.rule(
    name = "command",
    command = "$cmd",
    description = "$id",
    restat = True
)

# Enumerate all the checkpoints.
checkpoints = dict()
for checkpoint_dir in glob.glob(os.path.join(args.cptdir, "cpt.simpoint_*")):
    real_dir = os.path.realpath(checkpoint_dir)
    checkpoint_num = int(real_dir.split(".")[-1])
    checkpoints[checkpoint_num] = [
        os.path.join(real_dir, "m5.cpt"),
        os.path.join(real_dir, "system.physmem.store0.pmem"),
    ]

# Resume from each checkpoint.
for checkpoint, deps in checkpoints.items():
    outdir = f"{checkpoint}"
    stats_txt = f"{outdir}/stats.txt"
    cmd = [
        gem5_exe,
        *gem5_exe_args,
        "-re", "--silent-redirect",
        f"-d{outdir}",
        gem5_py,
        *gem5_py_args,
        f"--cmd=/usr/bin/true",
        f"--checkpoint-dir={args.cptdir}",
        f"--checkpoint-restore={checkpoint+1}",
        "--restore-simpoint-checkpoint",
        f"--chdir={args.rundir}",
        "--output=stdout.txt",
        "--errout=stderr.txt",
        "--input=/dev/null",
    ]
    cmd = " ".join(cmd)
    ninja.build(
        outputs = [stats_txt],
        rule = "command",
        inputs = [gem5_exe, gem5_py, *deps],
        variables = {
            "id": stats_txt,
            "cmd": f"if [ -d {outdir} ]; then rm -r {outdir}; fi && {cmd}",
        },
    )

    # Compute weighted average stats.
    stats = {
        "system.switch_cpus.numCycles": "cycles",
        "system.switch_cpus.ipc": "ipc",
    }
    generate_leaf_results_py = get_helper("generate-leaf-results.py")
    results_json = f"{outdir}/results.json"
    simpoints_json = os.path.join(os.path.dirname(args.indir), "simpoints.json")
    ninja.build(
        outputs = [results_json],
        rule = "command",
        inputs = [generate_leaf_results_py, simpoints_json, stats_txt],
        variables = {
            "id": results_json,
            "cmd": f"{generate_leaf_results_py} --stats={stats_txt} --simpoints-json={simpoints_json} --simpoint-idx={checkpoint} --output={results_json}",
        },
    )

# Generate summarized results.
results_json = "results.json"
subresults_json = [f"{checkpoint}/results.json" for checkpoint in checkpoints]
generate_bench_results_py = get_helper("generate-bench-results.py")
ninja.build(
    outputs = [results_json],
    rule = "command",
    inputs = [*subresults_json, generate_bench_results_py],
    variables = {
        "id": results_json,
        "cmd": " ".join([generate_bench_results_py, *subresults_json, "--output", results_json]),
    },
)
    

f.close()

# Run ninja.
exit_code = os.system("ninja")
if exit_code != 0:
    exit(exit_code)

# Print out cycles.
with open(results_json) as f:
    j = json.load(f)
print(j["stats"]["cycles"])
