import copy

core_hwconfs = {
    "unsafe": {
        "sim": "base",
        "gem5_opts": [],
        "script_opts": ["--ruby", "--enable-prefetch"], # TODO: Bake this into the checkpoint resume rule.
    },
    "spt": {
        "sim": "spt",
        "gem5_opts": ["--debug-flag=TransmitterStalls"],
        "script_opts": ["--ruby", "--enable-prefetch", "--spt", "--fwdUntaint=1", "--bwdUntaint=1", "--enableShadowL1=1"],
    },
    "tpt": {
        "sim": "tpt",
        "gem5_opts": ["--debug-flag=TPT,TransmitterStalls"],
        "script_opts": ["--ruby", "--enable-prefetch", "--tpt", "--implicit-channel=Lazy", "--tpt-reg", "--tpt-mem", "--tpt-xmit", "--tpt-mode=YRoT"],
    },
    "utrace": {
        "sim": "utrace",
        "gem5_opts": ["--debug-flag=uTrace"],
        "script_opts": ["--ruby", "--enable-prefetch"],
    },
}

def addon_speculation_model(hwconf, speculation_model):
    hwconf["script_opts"] += [f"--speculation-model={speculation_model}"]

def addon_core_type(hwconf, core_type):
    hwconf["script_opts"] += [f"--{core_type}"]

def addon_recon(hwconf):
    hwconf["sim"] += "-recon"
    hwconf["script_opts"] += ["--recon"]

def addon_ptex(hwconf):
    hwconf["sim"] += "-ptex"

g_addons = {
    "ctrl": lambda hwconf: addon_speculation_model(hwconf, "Ctrl"),
    "atret": lambda hwconf: addon_speculation_model(hwconf, "AtRet"),
    "ecore": lambda hwconf: addon_core_type(hwconf, "ecore"),
    "pcore": lambda hwconf: addon_core_type(hwconf, "pcore"),
    "recon": addon_recon,
    "ptex": addon_ptex,
}

# TODO: Factor out common code with compilers.get_compiler().
def get_hwconf(name):
    core, *addons = name.split(".")
    hwconf = copy.deepcopy(core_hwconfs[core])
    for addon in addons:
        g_addons[addon](hwconf)
    return hwconf
