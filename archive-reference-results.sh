#!/bin/bash

set -eu

find ctsbench.* bearssl ctaes djbsort nctbench.openssl.* wasm.4*.* -name results.json -exec cp --parents {} ./reference/ \;
find webserv/exp/c1r1 -name stats.txt -exec cp --parents {} ./reference/ \;
