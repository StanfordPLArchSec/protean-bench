#!/bin/sh

PATH="$PATH:$PWD/dummy" snakemake --jobs=64 --use-apptainer --apptainer-args="--home $PWD/.." --executor=slurm --latency-wait=10 "$@"
