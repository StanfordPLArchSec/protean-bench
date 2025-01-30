import copy

core_compilers = {
    "base": {
        "src": "../llvm/base-17",
        "bin": "../llvm/base-17/build",
        "cflags": [],
        "fflags": [],
    },
    "slh": {
        "src": "../llvm/base-17",
        "bin": "../llvm/base-17/build",
        "cflags": ["-mllvm", "-x86-speculative-load-hardening"],
        "fflags": ["-mllvm", "-x86-speculative-load-hardening"],
    },
    "sni": {
        "src": "../llvm/ptex-17",
        "bin": "../llvm/ptex-17/build",
        "cflags": ["-mllvm", "-x86-ptex=sni"],
        "fflags": ["-mllvm", "-x86-ptex=sni"],
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
    },
}

def get_compiler(name):
    core, *addons = name.split(".")
    compiler = copy.deepcopy(core_compilers[core])
    for addon in addons:
        extra_flags = g_addons[core][addon]
        for key in ["cflags", "fflags"]:
            compiler[key].extend(extra_flags)
    return compiler
