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

main_confs = ["base/unsafe"]
for defense in ["stt", "spt", "sptsb"]:
    main_confs.append(f"base/{defense}.atret")
for protmech in ["track", "delay"]:
    for binary in ["base", "cts", "ct", "nct"]:
        main_confs.append(f"{binary}/prot{protmech}.atret")

# Experiment 1: SPEC CPU2017 {INT,FP} on a {P,E}-core
for suite, bench in itertools.chain(
        zip(itertools.repeat("int"), benches_spec_int),
        zip(itertools.repeat("fp"), benches_spec_fp)):
    for conf in main_confs:
        for core in "pe":
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

# Experiment: PARSEC.
benches_parsec = [
    "apps/blackscholes",
    "apps/facesim",
    "apps/ferret",
    "apps/fluidanimate",
    "apps/freqmine",
    "apps/raytrace",
    "apps/swaptions",
    "apps/vips",
    "apps/x264",
    "kernels/canneal",
    "kernels/dedup",
    "kernels/streamcluster",
]
for bench in benches_parsec:
    for conf in main_confs:
        experiments["general.parsec"].append(
            f"parsec/pkgs/{bench}/run/exp/{conf}/stamp.txt")

# Experiment: Ctrl speculation model
for bench in benches_spec_int:
    confs = ["base/unsafe"]
    for defense in ["stt", "spt"]:
        confs.append(f"base/{defense}.ctrl")
    for binary in ["base", "ct"]:
        confs.append(f"{binary}/prottrack.ctrl")
    for conf in confs:
        experiments[f"ctrl"].append(
            f"{bench}/exp/0/main/{conf}.pcore/results.json")

# Experiment: No bugfixes for STT, SPT, SPT-SB.
for bench in benches_spec_int:
    confs = ["unsafe"]
    for defense in ["stt", "spt"]:
        for suffix in ["", "bug"]:
            confs.append(f"{defense}{suffix}.atret")
    for conf in confs:
        experiments["buggy"].append(
            f"{bench}/exp/0/main/base/{conf}.pcore/results.json")

# Experiment: ProtCC overhead of ProtCC-CTS/-CT/-UNR
# binaries.
for bench in benches_spec_int:
    for binary in ["base", "cts", "ct", "nct"]:
        experiments["protcc"].append(
            f"{bench}/exp/0/main/{binary}/unsafe.pcore/results.json")

# Experiment: ProtL1 variants.
for bench in benches_spec_int:
    confs = ["base/unsafe"]
    for binary in ["base", "ct"]:
        for protmem in [".shadowmem", "", ".noshadow"]:
            confs.append(f"{binary}/prottrack{protmem}.atret")
    for conf in confs:
        experiments["protmem"].append(
            f"{bench}/exp/0/main/{conf}.pcore/results.json")

# Experiment: AccessDelay and AccessTrack.
for bench in benches_spec_int:
    confs = ["base/unsafe"]
    for binary in ["base", "ct"]:
        for mode in ["", ".access"]:
            confs.append(f"{binary}/prottrack{mode}.atret")
    for conf in confs:
        experiments["access"].append(
            f"{bench}/exp/0/main/{conf}.pcore/results.json")

def main():
    parser = argparse.ArgumentParser()
    subparser = parser.add_subparsers(dest="cmd", required=True)
    subparser_list = subparser.add_parser("list")
    subparser_run = subparser.add_parser("run")
    subparser_run.add_argument(
        "--exp", action="append", choices=experiments.keys())
    subparser_run.add_argument("--dry-run", "-n", action="store_true")
    subparser_run.add_argument("--list", "-l", action="store_true")
    subparser_run.add_argument("snakemake_command", nargs="+")
    args = parser.parse_args()

    if args.cmd == "list":
        for experiment in experiments.keys():
            print(experiment)
        return 0
    assert args.cmd == "run"

    # Collect all matching experiments.
    requested_experiments = []
    for pattern in args.exp:
        for exp in experiments.keys():
            pat = re.escape(pattern) + r"(\..*)?"
            if re.fullmatch(pat, exp):
                requested_experiments.append(exp)

    # Collect the snakemake targets.
    targets = []
    for experiment in requested_experiments:
        targets.extend(experiments[experiment])

    # Run the snakemake command.
    cmd = args.snakemake_command + targets
    if args.dry_run:
        print(" ".join(cmd))
    else:
        os.execvp(cmd[0], cmd)

if __name__ == "__main__":
    main()
