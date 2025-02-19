import copy

core_compilers = {
    "base": {
        "src": "../llvm/base-17",
        "bin": "../llvm/base-17/build",
        "cflags": ["-mno-avx"],
        "fflags": ["-mno-avx"],
    },
    "slh": {
        "src": "../llvm/base-17",
        "bin": "../llvm/base-17/build",
        "cflags": ["-mno-avx", "-mllvm", "-x86-speculative-load-hardening"],
        "fflags": ["-mno-avx", "-mllvm", "-x86-speculative-load-hardening"],
    },
    "sni": {
        "src": "../llvm/ptex-17",
        "bin": "../llvm/ptex-17/build",
        "cflags": ["-mno-avx", "-mllvm", "-x86-ptex=sni"],
        "fflags": ["-mno-avx", "-mllvm", "-x86-ptex=sni"],
    },
}

g_addons = {
    "sni": {
        "b": ["-mllvm", "-x86-ptex-analyze-branches"],
        "c": ["-mllvm", "-x86-ptex-split"],
        "f": ["-mllvm", "-x86-ptex-flags"],
        "h": ["-mllvm", "-x86-ptex-hoist"],
        "p": ["-mllvm", "-x86-ptex-ptrs"],
        "s": ["-mllvm", "-x86-ptex-sink"],
        "bs": ["-mllvm", "-x86-ptex-analyze-branches", "-mllvm", "-x86-ptex-analyze-branches-split-critical"],
        "r": ["-mllvm", "-x86-ptex-rotate"],
    },
}

g_addons["sni"]["opt"] = []
for addon in ["b", "f", "s", "h"]:
    g_addons["sni"]["opt"].extend(g_addons["sni"][addon])

def is_compiler(name):
    core, *addons = name.split(".")
    if core not in core_compilers:
        return False
    for addon in addons:
        if addon not in g_addons[core]:
            return False
    return True

def get_compiler(name):
    core, *addons = name.split(".")
    compiler = copy.deepcopy(core_compilers[core])
    for addon in addons:
        extra_flags = g_addons[core][addon]
        for key in ["cflags", "fflags"]:
            compiler[key].extend(extra_flags)
    return compiler
