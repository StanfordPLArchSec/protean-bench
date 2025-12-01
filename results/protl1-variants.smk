import pathlib

protl1_variants_confs = [
    "base/unsafe",
    *expand("{bin}/prottrack{mode}.atret",
            bin = ["base", "ct"],
            mode = ["", ".shadowmem", ".noshadow"])]

rule protl1_variants:
    input:
        results = lambda w: expand("_cpu2017.int/exp/0/main/{conf}.pcore/results.json",
                                   **w, conf = protl1_variants_confs),
        template = "results/protl1-variants.tex.in",
    output:
        "results/protl1-variants.tex"
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
        table = []
        for mode in ["", ".noshadow", ".shadowmem"]:
            table.append([])
            for bin in ["base", "ct"]:
                defense_cycles = cycles(f"{bin}/prottrack{mode}.atret")
                x = defense_cycles / base_cycles
                x = (x - 1) * 100
                s = f"{x:.1f}\\%"
                table[-1].append(s)

        protl1, noprotmem, shadowprotmem = map(
            lambda row: "/".join(row), table)
        text = pathlib.Path(input.template).read_text()
        text = text.replace("@protl1@", protl1)
        text = text.replace("@noprotmem@", noprotmem)
        text = text.replace("@shadowprotmem@", shadowprotmem)
        pathlib.Path(output).write_text(text)
