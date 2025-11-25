import copy
import os

ptex = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))

base_cflags = ["-mno-avx"]

def make_compiler(name, flags):
    src = f"../llvm/{name}-17"
    bin = f"{src}/build"
    return {
        # ../llvm/name-17/build
        "src": src,
        "bin": bin,
        "cflags": ["-mno-avx"] + flags,
        "fflags": ["-mno-avx"] + flags,
    }
                  

core_compilers = {
    "base": make_compiler("base", []),
    "ct": make_compiler("ptex", ["-mllvm", "-x86-ptex=ct"]),
    "cts": make_compiler("ptex", ["-mllvm", "-x86-ptex=cts"]),
    "nct": make_compiler("ptex", ["-mllvm", "-x86-ptex=nct"]),
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
        "nofwd": ["-mllvm", "-x86-ptex-fwd=0"],
        "simple": ["-mllvm", "-x86-ptex-simple"],
        "fold": ["-mllvm", "-x86-ptex-bugfix-fold"],
        "lower": ["-mllvm", "-x86-ptex-bugfix-lower"],
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

def get_cflags(w):
    return get_compiler(w.bin)["cflags"] + ["-O2", "-g"]

def get_clang(w):
    return get_compiler(w.bin)["bin"] + "/bin/clang" 
