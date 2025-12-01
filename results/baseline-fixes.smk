import pathlib
import json

baseline_fixes_hwconfs = [
    "unsafe", "stt.atret", "sttbug.atret", "spt.atret",
    "sptbug.atret", "sptbugfix.atret", "sptsb.atret", "sptsbbug.atret",
]

rule baseline_fixes_tex:
    input:
        results = lambda w: expand("_cpu2017.int/exp/0/main/base/{conf}.pcore/results.json",
                                   conf = baseline_fixes_hwconfs),
        template = "results/baseline-fixes.tex.in",
    output:
        "results/baseline-fixes.tex"
    run:
        output, = output
        def cycles(hwconf):
            path, = expand("_cpu2017.int/exp/0/main/base/{hwconf}.pcore/results.json",
                           hwconf = hwconf)
            assert path in input, path
            with open(path) as f:
                j = json.load(f)
            return j["stats"]["cycles"]["geomean"]
        base_cycles = cycles("unsafe")
        def defense_overhead(hwconf):
            defense_cycles = cycles(f"{hwconf}.atret")
            x = (defense_cycles / base_cycles - 1) * 100
            return x
        def defense_overhead_diff(a, b):
            diff = defense_overhead(b) - defense_overhead(a)
            return f"{diff:.1f}"

        text = pathlib.Path(input.template).read_text()
        text = text.replace("@stt@", defense_overhead_diff("sttbug", "stt"))
        text = text.replace("@sptslow@", defense_overhead_diff("sptbug", "sptbugfix"))
        text = text.replace("@sptfast@", defense_overhead_diff("spt", "sptbugfix"))
        text = text.replace("@sptsb@", defense_overhead_diff("sptsbbug", "sptsb"))
        pathlib.Path(output).write_text(text)

