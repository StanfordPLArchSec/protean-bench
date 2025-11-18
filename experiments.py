#!/usr/bin/env python3

import itertools
import collections
import argparse
import os

# Named experiments for HPCA'26 submission.

experiments = collections.defaultdict(list)

benches_spec_int = [
    "600.perlbench_s",
    "602.gcc_s",
    "605.mcf_s",
    "620.omnetpp_s",
    "623.xalancbmk_s",
    "625.x264_s",
    "631.deepsjeng_s",
    "641.leela_s",
    "648.exchange2_s",
    "657.xz_s",
]

benches_spec_fp = [
    "603.bwaves_s",
    "607.cactuBSSN_s",
    "619.lbm_s",
    "621.wrf_s",
    "627.cam4_s",
    "628.pop2_s",
    "638.imagick_s",
    "644.nab_s",
    "649.fotonik3d_s",
    "654.roms_s",
]

# Experiment 1: SPEC CPU2017 {INT,FP} on a {P,E}-core
for suite, bench in itertools.chain(
        zip(itertools.repeat("int"), benches_spec_int),
        zip(itertools.repeat("fp"), benches_spec_fp)):
    confs = ["base/unsafe"]
    for defense in ["stt", "spt", "sptsb"]:
        confs.append(f"base/{defense}.atret")
    for binary in ["base", "cts", "ct", "nct"]:
        for protmech in ["delay", "track"]:
            confs.append(f"{binary}/prot{protmech}.atret")
    for conf in confs:
        for core in ["p", "e"]:
            target = f"{bench}/exp/0/main/{conf}.{core}core/results.json"
            experiments[f"general.spec.{suite}"].append(target)

# Experiment: Access predictor sensitivity study,
# on SPEC CPU2017 INT, P-core, ProtTrack-only, base/ct
# binaries.
for bench in benches_spec_int:
    confs = ["base/unsafe"]
    for binary in ["base", "ct"]:
        hwmodes = ["unprot", "pred0"]
        for n in range(0, 13):
            hwmodes.append(f"pred{2 ** n}")
        for hwmode in hwmodes:
            confs.append(f"{binary}/prottrack.{hwmode}.atret")
    for conf in confs:
        target = f"{bench}/exp/0/main/{conf}.pcore/results.json"
        experiments[f"predictor"].append(target)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--exp", action="append", choices=experiments.keys())
    parser.add_argument("--dry-run", "-n", action="store_true")
    parser.add_argument("snakemake_command", nargs="+")
    args = parser.parse_args()

    # Collect the snakemake targets.
    targets = []
    for experiment in args.exp:
        targets.extend(experiments[experiment])

    # Run the snakemake command.
    cmd = args.snakemake_command + targets
    if args.dry_run:
        print(" ".join(cmd))
    else:
        os.execvp(cmd[0], cmd)

if __name__ == "__main__":
    main()
