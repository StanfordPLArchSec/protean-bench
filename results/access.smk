from pathlib import Path
import pathlib
import json

access_confs = ["base/unsafe", *expand("{bin}/prot{mech}{mode}.atret",
                                       bin = ["base", "ct"],
                                       mech = ["delay", "track"],
                                       mode = ["", ".access"])]
rule accessdelay_accesstrack_overhead:
    input:
        results = expand("_cpu2017.int/exp/0/main/{conf}.pcore/results.json",
                         conf = access_confs),
        template = "results/access.tex.in",
    output:
        "results/access.tex"
    run:
        output, = output

        def cycles(conf):
            path, = expand("_cpu2017.int/exp/0/main/{conf}.pcore/results.json", conf = conf)
            assert path in input.results, path
            return json.loads(Path(path).read_text())["stats"]["cycles"]["geomean"]

        def cycles_defense(hwconf):
            a = cycles(f"base/{hwconf}")
            b = cycles(f"ct/{hwconf}")
            return math.sqrt(a * b)

        base_cycles = cycles("base/unsafe")
        def cycles_defense_overhead(hwconf):
            return (cycles_defense(hwconf) / base_cycles - 1) * 100

        table = []
        for mech in ["delay", "track"]:
            x = cycles_defense_overhead(f"prot{mech}.atret")
            y = cycles_defense_overhead(f"prot{mech}.access.atret")
            diff = y - x
            table.append(f"{diff:.1f}\\%")
        
        access_overhead = "/".join(table)

        text = Path(input.template).read_text()
        text = text.replace("@access_overhead@", access_overhead)
        Path(output).write_text(text)
