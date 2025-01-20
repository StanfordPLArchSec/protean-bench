#!/bin/bash

script_dir="$(dirname "${BASH_SOURCE[0]}")"
cd "${script_dir}"

docker save -o ptex.tar ptex:latest
apptainer build -F ptex.sif docker-archive://ptex.tar
