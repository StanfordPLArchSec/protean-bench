protl1_variants_confs = [
    "base/unsafe",
    *expand("{bin}/prottrack{mode}.atret",
            bin = ["base", "ct"],
            mode = ["", ".shadowmem", ".noshadow"])]

rule protl1_variants:
    input:
        lambda w: expand("_cpu2017/exp/0/main/{conf}.pcore/results.json",
                         **w, conf = protl1_variants_confs)
    output:
        "results/protl1-variants.tex"
    run:
        def cycles(conf):
            path, = expand("_cpu2017/exp/0/main/{conf}.pcore/results.json",
                           **wildcards,
                           conf = conf)
            assert path in input
            with open(path) as f:
                j = json.load(f)
            return j["stats"]["cycles"]
        base_cycles = cycles("base/unsafe")
        table = []
        for mode in ["", ".noshadow", ".shadowmem"]:
            table.append([])
            for bin in ["base", "ct"]:
                defense_cycles = cycles(f"{bin}/prottrack{mode}")
                x = defense_cycles / base_cycles
                x = (x - 1) * 100
                s = f"{x:.1f}%"
                table[-1].append(s)
        with open(output, "wt") as f:
            print(""
            
        
