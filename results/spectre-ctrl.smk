import pathlib
import json

spectre_ctrl_confs = [
    "base/unsafe",
    "ct/unsafe",
    *expand("base/{defense}.ctrl", defense = ["stt", "spt"]),
    *expand("{bin}/prottrack.ctrl", bin = ["base", "ct"]),
]

rule spectre_ctrl_tex:
    input:
        results = lambda w: expand("_cpu2017.int/exp/0/main/{conf}.pcore/results.json",
                                   conf = spectre_ctrl_confs),
        template = "results/spectre-ctrl.tex.in",
    output:
        "results/spectre-ctrl.tex"
    run:
        output, = output
        def cycles(conf):
            path, = expand("_cpu2017.int/exp/0/main/{conf}.pcore/results.json",
                           **wildcards,
                           conf = conf)
            assert path in input, f"path {path} is not in input list"
            with open(path) as f:
                j = json.load(f)
            return j["stats"]["cycles"]["geomean"]
        base_cycles = cycles("base/unsafe")
        def defense_overhead(conf):
            defense_cycles = cycles(conf)
            x = (defense_cycles / base_cycles - 1) * 100
            return f"{x:.1f}\\%"

        stt = defense_overhead("base/stt.ctrl")
        spt = defense_overhead("base/spt.ctrl")
        prottrack_arch = defense_overhead("base/prottrack.ctrl")
        prottrack_ct = defense_overhead("ct/prottrack.ctrl")
        unsafe_ct = defense_overhead("ct/unsafe")

        text = pathlib.Path(input.template).read_text()
        text = text.replace("@prottrack_arch@", prottrack_arch)
        text = text.replace("@prottrack_ct@", prottrack_ct)
        text = text.replace("@stt@", stt)
        text = text.replace("@spt@", spt)
        pathlib.Path(output).write_text(text)
