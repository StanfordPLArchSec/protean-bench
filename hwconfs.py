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
        "script_opts": ["--ruby", "--enable-prefetch", "--spt", "--fwdUntaint=1", "--bwdUntaint=1", "--enableShadowL1=1", "--spt-bugfix"],
    },
    "secure": {
        "sim": "spt",
        "gem5_opts": [],
        "script_opts": ["--ruby", "--enable-prefetch", "--spt", "--disableUntaint=1"],
    },
    "tpt": {
        "sim": "tpt",
        "gem5_opts": ["--debug-flag=TPT,TransmitterStalls"],
        "script_opts": ["--ruby", "--enable-prefetch", "--tpt", "--implicit-channel=Lazy", "--tpt-reg", "--tpt-mem", "--tpt-xmit", "--tpt-mode=YRoT"],
    },
    "tpt-nopages": {
        "sim": "tpt",
        "gem5_opts": [],
        "script_opts": ["--ruby", "--enable-prefetch", "--tpt", "--implicit-channel=Lazy", "--tpt-reg", "--tpt-mem", "--tpt-xmit", "--tpt-mode=YRoT"],
    },
    "stt": {
        "sim": "stt",
        "gem5_opts": [],
        "script_opts": ["--ruby", "--enable-prefetch", "--stt", "--implicit-channel=Lazy"],
    },
    "tpe": {
        "sim": "tpe",
        "gem5_opts": ["--debug-flag=TransmitterStalls"],
        "script_opts": ["--ruby", "--enable-prefetch", "--tpe-reg", "--tpe-mem", "--tpe-xmit"],
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

def addon_noimp(hwconf):
    sim = hwconf["sim"]
    if sim.startswith("tpt") or sim.startswith("stt"):
        hwconf["script_opts"] += ["--implicit-channel=None"]
    elif sim.startswith("spt"):
        hwconf["script_opts"] += ["--configImpFlow=Ignore"]
    else:
        raise ValueError(f"simulator '{sim}' in hwconf not compatible with addon 'noimp'")

def addon_eager(hwconf):
    sim = hwconf["sim"]
    assert sim.startswith("tpt")
    hwconf["script_opts"] += ["--implicit-channel=Eager"]

def addon_noshadow(hwconf):
    sim = hwconf["sim"]
    if sim.startswith("tpt"):
        hwconf["script_opts"] += ["--ptex-mem=None"]
    elif sim.startswith("spt"):
        hwconf["script_opts"] += ["--enableShadowL1=0"]
    else:
        raise ValueError(f"simulator '{sim}' in hwconf not compatible with addon 'noshadow'")

def addon_shadowmem(hwconf):
    sim = hwconf["sim"]
    if sim.startswith("tpt"):
        hwconf["script_opts"] += ["--ptex-mem=ShadowMem"]
    elif sim.startswith("spt"):
        hwconf["script_opts"] += ["--bottomlessShadowL1=1"]
    else:
        raise ValueError(f"simulator '{sim}' in hwconf not compatible with addon 'shadowmem'")
    
def addon_naive(hwconf):
    sim = hwconf["sim"]
    if sim.startswith("tpt"):
        hwconf["script_opts"] += ["--tpt-mode=Naive"]
    else:
        raise ValueError(f"simulator '{sim}' in hwconf not compatible with addon 'naive'")

def addon_ideal(hwconf):
    sim = hwconf["sim"]
    if sim.startswith("tpt"):
        hwconf["script_opts"] += ["--tpt-mode=Ideal"]
    else:
        raise ValueError(f"simulator '{sim}' in hwconf not compatible with addon 'ideal'")

def addon_pages(hwconf):
    sim = hwconf["sim"]
    if sim.startswith("tpt") or sim.startswith("tpe"):
        hwconf["script_opts"] += ["--ptex-pages"]
    else:
        raise ValueError(f"simulator '{sim}' in hwconf not compatible with addon 'pages'")
    
g_addons = {
    "ctrl": lambda hwconf: addon_speculation_model(hwconf, "Ctrl"),
    "atret": lambda hwconf: addon_speculation_model(hwconf, "AtRet"),
    "ecore": lambda hwconf: addon_core_type(hwconf, "ecore"),
    "pcore": lambda hwconf: addon_core_type(hwconf, "pcore"),
    "recon": addon_recon,
    "ptex": addon_ptex,
    "noimp": addon_noimp,
    "eager": addon_eager,
    "noshadow": addon_noshadow,
    "shadowmem": addon_shadowmem,
    "naive": addon_naive,
    "pages": addon_pages,
    "ideal": addon_ideal,
}

# TODO: Factor out common code with compilers.get_compiler().
def get_hwconf(name):
    core, *addons = name.split(".")
    hwconf = copy.deepcopy(core_hwconfs[core])
    for addon in addons:
        g_addons[addon](hwconf)
    return hwconf
