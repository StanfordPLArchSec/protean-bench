#!/bin/sh

PATH="$PATH:$PWD/dummy" snakemake --jobs=32 --use-apptainer --apptainer-args="--home $PWD/.." --executor=slurm "$@"
