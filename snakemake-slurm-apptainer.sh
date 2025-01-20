#!/bin/sh

PATH="$PATH:$PWD/dummy" snakemake --jobs=10 --use-apptainer --apptainer-args="--home $PWD/.." --executor=slurm "$@"
