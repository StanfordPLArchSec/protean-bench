# Adding New Benchmarks

Our performance evaluation infrastructure allows you to easily add new benchmarks to evaluate Protean or [another hardware-software codesign](/HW-SW.md) on.
This document shows how to add a simple benchmark called "example" and evaluate a gem5 model on it.

In these instructions, we assume that you are looking to evaluate a hardware-software codesign consisting of the "mycpu" gem5 model and "mycc" compiler.

First, compile the benchmark, once per compiler, and place the executable at `example/bin/{compiler}/exe`.
For example, this means compiling a unmodified baseline binary in `example/bin/base/exe` 
and compiling your codesign's binary at `example/bin/mycc/exe`.

Then, register the benchmark in the main [Snakefile](/Snakefile):
```
make_bench("example").add_input("30")
```
This says that the command line for input 0 of the example benchmark is "30".

Finally, benchmark your hardware-software codesign on the example benchmark:
```
snakemake --cores=all example/exp/0/{base/basecpu,mycc/mycpu}/results.json
```
