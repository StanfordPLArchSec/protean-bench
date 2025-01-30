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

g_addons = {
    "ctrl": {"script_opts": ["--speculation-model=Ctrl"]},
    "atret": {"script_opts": ["--speculation-model=AtRet"]},
    "ecore": {"script_opts": ["--ecore"]},
    "pcore": {"script_opts": ["--pcore"]},
}

# TODO: Factor out common code with compilers.get_compiler().
def get_hwconf(name):
    core, *addons = name.split(".")
    hwconf = copy.deepcopy(core_hwconfs[core])
    for addon in addons:
        extra = g_addons[addon]
        for key, value in extra.items():
            hwconf[key].extend(value)
    return hwconf
            
        
