#!/bin/bash

set -eu

find ctsbench.* bearssl ctaes djbsort nctbench.openssl.* wasm.4*.* -name results.json -exec cp --parents {} ./reference/ \;
find webserv -name stats.txt -exec cp --parents {} ./reference/ \;
find 6*.*_s -name results.json -exec cp --parents {} ./reference \;
cp --parents tables/{wasmbench,ctsbench,ctbench,nctbench,webserv}.tex ./reference
cp --parents results/{protcc-overhead,protl1-variants,spectre-ctrl,baseline-fixes,access}.tex ./reference
cp --parents figures/*.csv ./reference
cp --parents tables/survey.tex ./reference
