#!/usr/bin/python3

import argparse
import json
import types
import sys
import os
import gzip

parser = argparse.ArgumentParser()
parser.add_argument('--stats', required = True, help = '(Input) Path to m5out/stats.txt')
parser.add_argument('--simpoints-json', required = True, help = '(Input) Path to cpt/simpoints.json')
parser.add_argument('--simpoint-idx', required = True, type = int, help = '(Input) Simpoint index')
parser.add_argument('--output', required = True, help = '(Output) Path to out JSON')
args = parser.parse_args()

simpoints = None
with open(args.simpoints_json) as f:
    simpoints = json.load(f)
    simpoints = [types.SimpleNamespace(**simpoint) for simpoint in simpoints]

def find_simpoint():
    for simpoint in simpoints:
        if int(simpoint.name) == args.simpoint_idx:
            return simpoint
    # print('error: failed to find requested simpoint', file = sys.stderr)
    # exit(1)
    with open(args.output, 'wt') as f:
        print('{}', file = f)
    exit(0)

simpoint = find_simpoint()

class Stat:
    def __init__(self, name: str, required: bool = False, minimum: int = None):
        self.name = name
        self.required = required
        self.value = None
        self.count = 0
        self.minimum = minimum

key_insts = 'system.switch_cpus.commitStats0.numInsts'
stats = {
    key_insts: Stat('insts', required = True, minimum = 2),
    'system.switch_cpus.ipc': Stat('ipc', required = True),
    'system.switch_cpus.numCycles': Stat('cycles', required = True),
    'system.switch_cpus.commit.committedAnnotatedUnprotectedRegisterRate': Stat('pub-annot-reg-rate'),
    'system.switch_cpus.commit.committedAnnotatedUnprotectedLoadRate': Stat('pub-annot-load-rate'),
    'system.switch_cpus.commit.committedAnnotatedUnprotectedLoadCount': Stat('pub-annot-load-count'),
    'system.switch_cpus.commit.committedAnnotatedLoadCount': Stat('annot-load-count'),
    'system.switch_cpus.commit.regTaints': Stat('reg-taints'),
    'system.switch_cpus.commit.memTaints': Stat('mem-taints'),
    'system.switch_cpus.commit.xmitTaints': Stat('xmit-taints'),
    'system.switch_cpus.commit.protRegs': Stat('prot-regs'),
    'system.switch_cpus.commit.unprotRegs': Stat('unprot-regs'),
}
# stats = dict(map(lambda x: (x.name(), None), keys.values()))
with open(args.stats) as f:
    for line in f:
        tokens = line.split()
        if len(tokens) < 2:
            continue
        key = tokens[0]
        if key in stats:
            stat = stats[key]
            stat.value = float(tokens[1])
            stat.count += 1

for stat in stats.values():
    if stat.required and stat.value is None:
        print(f"Didn't find stat {stat.name} in {args.stats}!", file=sys.stderr)
        exit(1)
    if stat.minimum and stat.count < stat.minimum:
        print(f"Found only {stat.count} < {stat.minimum} instances of stat {stat.name}!", file=sys.stderr)
        exit(1)

def get_stats_dict(stats) -> dict:
    d = dict()
    for stat in stats.values():
        if stat.value is not None:
            d[stat.name] = stat.value
    return d
        
results = {
    'simpoint': simpoint.__dict__,
    'stats': get_stats_dict(stats),
}

# HACK: Compute transmitter stalls.
dbgout_path = os.path.join(os.path.dirname(args.stats), "dbgout.txt.gz")
if os.path.isfile(dbgout_path):
    stalls = 0
    access_preds = 0
    access_misps = 0
    with gzip.open(dbgout_path, "rt") as f:
        for line in f:
            if line.startswith("STALL:"):
                stalls += int(line.split()[3])
            if line.startswith("TPT pred-"):
                pred, real, prot = line.split()[1].split("-")[1]
                if prot == "u":
                    access_preds += 1
                    if pred != real:
                        access_misps += 1
    results["stats"]["stalls"] = stalls
    results["stats"]["access-preds"] = access_preds
    results["stats"]["access-misps"] = access_misps
    results["stats"]["access-misp-rate"] = access_misps / access_preds if access_preds != 0 else 0

if "unprot-regs" in results["stats"]:
    results["stats"]["unprot-regs-inst"] = results["stats"]["unprot-regs"] / results["stats"]["insts"]

if "unprot-regs" in results["stats"]:
    unprot = results["stats"]["unprot-regs"]
    prot = results["stats"]["prot-regs"]
    results["stats"]["unprot-regs-rate"] = unprot / (unprot + prot)

with open(args.output, 'wt') as f:
    json.dump(results, f, indent = 4)
