import json
import pathlib

survey_defenses = {
    "stt": ["arch"],
    "spt": ["cts", "ct"],
    "sptsb": ["unr", "multi"],
    "prottrack": ["arch", "cts", "ct", "unr", "multi"],
    "protdelay": ["arch", "cts", "ct", "unr", "multi"],
}

survey_suites = {
    "arch": "wasmbench",
    "cts": "ctsbench",
    "ct": "ctbench",
    "unr": "nctbench",
    "multi": "webserver",
}

survey_single_class_results = []

for suite, group in [
        ("wasmbench", "base"),
        ("ctsbench", "ctsbench"),
        ("ctbench", "ctbench"),
        ("nctbench", "nctbench"),
]:
    survey_single_class_results.append(
        f"_{suite}/exp/0/{group}/base/unsafe.pcore/results.json")

for suite, group, defense in [
    ("wasmbench", "base", "stt"),
    ("ctsbench", "ctsbench", "spt"),
    ("ctbench", "ctbench", "spt"),
    ("nctbench", "nctbench", "sptsb"),
]:
    survey_single_class_results.append(
        f"_{suite}/exp/0/{group}/base/{defense}.atret.pcore/results.json")

for suite, group, bin in [
        ("wasmbench", "base", "base"),
        ("ctsbench", "ctsbench", "cts"),
        ("ctbench", "ctbench", "ct"),
        ("nctbench", "nctbench", "nct"),
]:
    for mech in ["delay", "track"]:
    survey_single_class_results.append(
        f"_{suite}/exp/0/{group}/prot{mech}.atret.pcore/results.json")

survey_multi_class_stamps = expand(
    "webserv/exp/{input}/{conf}.se/stamp.txt",
    input = benchsuites.benchsuites["webserv"],
    conf = ["base/unsafe", "base/spt.atret",
            "nct.ossl-annot/prottrack.atret",
            "nct.ossl-annot/protdelay.atret"])

rule survey_table:
    output:
        "tables/survey.tex"
    input:
        template = "tables/survey.tex.in",
        single_class_results = survey_single_class_results,
        multi_class_stamps = survey_multi_class_stamps,
    run:
        output, = output

        # Single-class results.
        def cycles(suite, conf):
            path, = expand("_{suite}/exp/0/main/{conf}.pcore/results.json",
                   suite = suite, conf = conf)
            assert path in input.single_class_results
            return json.loads(pathlib.Path(path).read_text())["stats"]["cycles"]["geomean"]

        def defense_overhead(suite, conf):
            base_cycles = cycles(suite, "base/unsafe")
            defense_cycles = cycles(suite, f"{conf}.atret")
            x = (defense_cycles / base_cycles - 1) * 100
            return f"{x:.0f}"

        d = {}
        d["stt_arch"] = defense_overhead("wasmbench", "base/stt")
        d["spt_cts"] = defense_overhead("ctsbench", "base/spt")
        d["spt_ct"] = defense_overhead("ctbench", "base/spt")
        d["sptsb_unr"] = defense_overhead("nctbench", "base/sptsb")
        for mech in ["track", "delay"]:
            for name, bin, suite in [("arch", "base", "wasmbench"),
                                     ("cts", "cts", "ctsbench"),
                                     ("ct", "ct", "ctbench"),
                                     ("nct", "nct", "nctbench")]:
                d[f"prot{mech}_{name}"] = defense_overhead(suite, f"{bin}/prot{mech}")

        # Multi-class results.
        def seconds_single(conf, input):
            path = f"webserv/exp/{input}/{conf}.se/stats.txt"
            stamp = os.path.join(os.path.dirname(path), "stamp.txt")
            assert stamp in input.multi_class_stamps
            l = []
            with open(path) as f:
                for line in f:
                    if m := re.match(r"simSeconds\s+([0-9.]+)", line):
                        l.append(m.group(1))
            assert len(l) >= 1
            return float(l[-1])

        def seconds(conf):
            l = []
            for input in benchsuites.benchsuites["webserv"]:
                l.append(seconds_single(conf, input))
            return math.mult(l) ** (1 / len(l))

        def defense_multi_overhead(conf):
            base_seconds = seconds("base/unsafe")
            defense_seconds = seconds(f"{conf}.atret")
            x = (defense_seconds / base_seconds - 1) * 100
            return f"{x:.0f}"

        d["sptsb_multi"] = defense_multi_overhead("base/sptsb")
        for mech in ["track", "delay"]:
            d[f"prot{mech}_multi"] = defense_multi_overhead(f"nct.ossl-annot/prot{mech}")

        # Generate .tex.
        text = pathlib.Path(input.template).read_text()
        for k, v in d.items():
            text = text.replace(f"@{k}@", v)
        pathlib.Path(output).write_text(text)
