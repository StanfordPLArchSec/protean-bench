import copy
import re

core_hwconfs = {
    "unsafe": {
        "sim": "base",
        "gem5_opts": [],
        "script_opts": ["--ruby", "--enable-prefetch"], # TODO: Bake this into the checkpoint resume rule.
    },
    "spt": {
        "sim": "spt",
        "gem5_opts": ["--debug-flag=TransmitterStalls"],
        "script_opts": ["--ruby", "--enable-prefetch", "--spt", "--fwdUntaint=1", "--bwdUntaint=1", "--enableShadowL1=1", "--spt-bugfix-pending",
                        "--moreTransmitInsts=3"],
    },
    "spt2": {
        "sim": "spt",
        "gem5_opts": ["--debug-flag=TransmitterStalls"],
        "script_opts": ["--ruby", "--enable-prefetch", "--spt", "--fwdUntaint=1", "--bwdUntaint=1", "--enableShadowL1=1", "--spt-bugfix-pending",
                        "--moreTransmitInsts=3", "--spt-bugfix-rename"],
    },
    "sptsb": {
        "sim": "spt",
        "gem5_opts": ["--debug-flag=SPTRetire,TransmitterStalls"],
        "script_opts": ["--ruby", "--enable-prefetch", "--spt", "--disableUntaint=1", "--spt-bugfix-pending", "--moreTransmitInsts=3"],
    },
    "prottrack": {
        "sim": "protean",
        "gem5_opts": ["--debug-flag=Protean,TransmitterStalls"],
        "script_opts": ["--ruby", "--enable-prefetch", "--protean=Track", "--protean-pred-mode=Predict", "--protean-pred-size=1024"],
    },
    "protdelay": {
        "sim": "protean",
        "gem5_opts": ["--debug-flag=Protean,ProteanRetire,TransmitterStalls"],
        "script_opts": ["--ruby", "--enable-prefetch", "--protean=Delay", "--protean-delay-flags-opt"],
    },
    "stt": {
        "sim": "stt",
        "gem5_opts": [],
        "script_opts": ["--ruby", "--enable-prefetch", "--stt", "--implicit-channel=Lazy", "--stt-bugfix-store", "--stt-bugfix-pending",
                        "--more-transmit-insts=3"],
    },

    # Buggy versions of prior defenses.
    "sttbug": {
        "sim": "stt",
        "gem5_opts": [],
        "script_opts": ["--ruby", "--enable-prefetch", "--stt", "--implicit-channel=Lazy"],
    },
    "sptbug": {
        "sim": "spt",
        "gem5_opts": ["--debug-flag=TransmitterStalls"],
        "script_opts": ["--ruby", "--enable-prefetch", "--spt", "--fwdUntaint=1", "--bwdUntaint=1", "--enableShadowL1=1"],
    },
    "sptbugfix": {
        "sim": "spt",
        "gem5_opts": ["--debug-flag=TransmitterStalls"],
        "script_opts": ["--ruby", "--enable-prefetch", "--spt", "--fwdUntaint=1", "--bwdUntaint=1", "--enableShadowL1=1", "--spt-bugfix-pending", "--moreTransmitInsts=3", "--spt-bugfix-rename"],
    },
    "sptsbbug": {
        "sim": "spt",
        "gem5_opts": ["--debug-flag=SPTRetire,TransmitterStalls"],
        "script_opts": ["--ruby", "--enable-prefetch", "--spt", "--disableUntaint=1"],
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
    if sim.startswith("tpt") or sim.startswith("protean"):
        hwconf["script_opts"] += ["--protean-mem=None"]
    elif sim.startswith("spt"):
        hwconf["script_opts"] += ["--enableShadowL1=0"]
    else:
        raise ValueError(f"simulator '{sim}' in hwconf not compatible with addon 'noshadow'")

def addon_shadowmem(hwconf):
    sim = hwconf["sim"]
    if sim.startswith("tpt") or sim.startswith("protean"):
        hwconf["script_opts"] += ["--protean-mem=ShadowMem"]
    elif sim.startswith("spt"):
        hwconf["script_opts"] += ["--bottomlessShadowL1=1"]
    else:
        raise ValueError(f"simulator '{sim}' in hwconf not compatible with addon 'shadowmem'")

def addon_rs(hwconf):
    hwconf["script_opts"] += ["--spt-bugfix-rs"]

def addon_predsize(hwconf, n):
    hwconf["script_opts"] += [f"--protean-pred-size={n}"]

def addon_delayopt(hwconf):
    hwconf["script_opts"] += [f"--protean-delay-opt"]

def addon_access(hwconf):
    if "--protean=Track" in hwconf["script_opts"]:
        hwconf["script_opts"] += ["--protean-pred-mode=Protected"]
    elif "--protean=Delay" in hwconf["script_opts"]:
        hwconf["script_opts"] += ["--protean-delay-all"]
    else:
        raise ValueError(f"simulator '{sim}' in hwconf not compatible with addon 'access'")

def addon_unprot(hwconf):
    if "--protean=Track" in hwconf["script_opts"]:
        hwconf["script_opts"] += ["--protean-pred-mode=Unprotected"]
    else:
        sim = hwconf["sim"]
        raise ValueError(f"simulator '{sim}' in hwconf not compatible with addon 'unprot'")

def addon_se(hwconf):
    hwconf["sim"] += "-se"
    
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
    r"pred(\d+)": addon_predsize,
    "delayopt": addon_delayopt,
    "access": addon_access,
    "unprot": addon_unprot,
    "se": addon_se,
}

# TODO: Factor out common code with compilers.get_compiler().
def get_hwconf(name):
    core, *addons = name.split(".")
    hwconf = copy.deepcopy(core_hwconfs[core])
    for addon in addons:
        ok = False
        for addon_re, addon_fn in g_addons.items():
            assert not ok
            if m := re.fullmatch(addon_re, addon):
                addon_fn(hwconf, *m.groups())
                ok = True
                break
        if not ok:
            raise ValueError(f"ERROR: unhandled addon '{addon}'")
    return hwconf
