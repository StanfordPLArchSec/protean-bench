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
        output = output,

        def cycles(conf):
            path, = expand("_cpu2017.int/exp/0/main/{conf}.pcore/results.json")
            assert path in input.results, path
            return json.loads(pathlib.Path(path).read_text())["stats"]["cycles"]["geomean"]

        def cycles_defense(hwconf):
            a = cycles(f"base/{hwconf}")
            b = cycles(f"ct/{hwconf}")
            return math.sqrt(a * b)

        base_cycles = cycles("base/unsafe")
        table = []
        for mech in ["delay", "track"]:
            x = cycles_defense(f"prot{mech}.atret")
            y = cycles_defense(f"prot{mech}.access.atret")
            diff = ((y - x) / base_cycles - 1) * 100
            table.append(f"{diff:.1f}\\%")
        
        access_overhead = "/".join(table)

        text = pathlib.Path(input.template).read_text()
        text = text.replace("@access_overhead@", access_overhead)
        pathlib.Path(output).write_text(text)
