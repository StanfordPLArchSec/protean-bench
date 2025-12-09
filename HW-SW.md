# Evaluating New Hardware-Software Codesigns

This repository's performance evaluation infrastructure is not specific to Spectre defenses;
in fact, it can be used to evaluate the performance of any hardware-only proposal implemented in gem5
or any hardware-software proposal implemented in gem5 and LLVM (like Protean).

You can adapt this repository to evaluate your own gem5-LLVM hardware-software codesign in the following steps.

1. **Add your compiler (e.g., "mycc") to [compilers.py](compilers.py)**, specifically by adding it to the `core_compilers` dictionary. For example, this might involve adding the line:
```python
core_compilers["mycc"] = {
    "src": "/path/to/mycc/source",
	"bin": "/path/to/mycc/builddir",
	"cflags": [... list of mycc C/C++ compile flags],
	"fflags": [... list of mycc Fortran compile flags],
}
```
2. **Add your gem5 model (e.g., "mycpu") to [hwconfs.py](hwconf.py)**, specifically by adding it to the `core_hwconfs` dictionary. For example, this might involve adding the line:
```python
core_hwconfs["mycpu"] = {
    "sim": "/path/to/mycpu/gem5/src",
	"gem5_opts": [],
	"script_opts": [... mycpu se.py script opts ...],
}
```
3. **Add the set of compilers you will be evaluating to [bingroups.py](bingroups.py)**, specifically by adding to the `bingroups` dictionary. For example, this might involve adding the line:
```python
bingroups["main"] = {"basecc", "mycc"}
```

To benchmark your mycpu/mycc hardware-software codesign on a benchmark `bench`, 
simply execute the following command:
```
snakemake --cores=all bench/exp/0/main/{basecc/basecpu,mycc/mycpu}/results.json
```
