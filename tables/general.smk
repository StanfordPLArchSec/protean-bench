import benchsuites

general_bins = {
    "arch": "base",
    "cts": "cts",
    "ct": "ct",
    "unr": "nct",
}

general_defenses = {
    "arch": "stt",
    "cts": "spt",
    "ct": "spt",
    "unr": "sptsb",
}

general_defense_names = {
    "stt": "STT",
    "spt": "SPT",
    "sptsb": "SPT-SB",
}

def general_confs(bin):
    l = ["base/unsafe"]
    l += expand("base/{defense}.atret", defense = general_defenses[bin])
    l += expand("{bin}/prot{mech}.atret", bin = general_bins[bin], mech = ["track", "delay"])
    return l

rule general_suite_csv:
    input:
        # CPU2017
        spec = lambda w: expand(
            "{bench}/exp/0/main/{conf}.{core}/results.json",
            bench = benchsuites.benchsuites["cpu2017"],
            conf = general_confs(w.bin),
            core = ["pcore", "ecore"]),

        # PARSEC
        parsec = lambda w: expand(
            "parsec/pkgs/{bench}/run/exp/{conf}/stats.txt",
            bench = benchsuites.benchsuites["parsec"],
            conf = general_confs(w.bin)),

    output:
        csv = "tables/general-{bin}.csv",
        tex = "tables/general-{bin}.tex",
    run:
        base_conf, *defense_confs = general_confs(wildcards.bin)
        def spec_cycles_single(bench, conf, core):
            path = f"{bench}/exp/0/main/{conf}.{core}/results.json"
            assert path in input.spec
            with open(path) as f:
                j = json.load(f)
            return j["stats"]["cycles"]
        def parsec_cycles_single(bench, conf):
            path = f"parsec/pkgs/{bench}/run/exp/{conf}/stats.txt"
            assert path in input.parsec, path
            matches = []
            with open(path) as f:
                for line in f:
                    if re.match(r"simSeconds", line):
                        matches.append(float(line.split()[1]))
            assert len(matches) >= 1
            return matches[-1]
        def suite_geomean_cycles(suite, f, *args):
            l = []
            for bench in benchsuites.benchsuites[suite]:
                x = f(bench, *args)
                l.append(x)
            return math.prod(l) ** (1 / len(l))
        def spec_cycles(conf, core):
            return suite_geomean_cycles("cpu2017", spec_cycles_single, conf, core)
        def parsec_cycles(conf):
            return suite_geomean_cycles("parsec", parsec_cycles_single, conf)
        def spec_pcore_cycles(conf):
            return spec_cycles(conf, "pcore")
        def spec_ecore_cycles(conf):
            return spec_cycles(conf, "ecore")

        table = []
        for f in [spec_pcore_cycles, spec_ecore_cycles, parsec_cycles]:
            table.append([])
            base_x = f(base_conf)
            for defense_conf in defense_confs:
                defense_x = f(defense_conf)
                table[-1].append(defense_x / base_x)

        # Format the numbers nicely.
        for row in table:
            for i in range(len(row)):
                row[i] = f"{row[i]:.3f}"
                
        # Generate the CSV.
        prior_defense_name = general_defense_names[general_defenses[wildcards.bin]]
        with open(output.csv, "wt") as f:
            print(f"Suite,{prior_defense_name},Protean (ProtTrack),Protean (ProtDelay)",
                  file=f)
            for row, suite in zip(table, ["SPEC2017 (P-core)", "SPEC2017 (E-core)", "PARSEC"]):
                row = [suite] + row
                print(",".join(row), file=f)

        # Generate the TEX.
        with open(output.tex, "wt") as f:
            s = r"""
\begin{tabular}{!{\vrule width 1pt}c|c|c|c|c!{\vrule width 1pt}}\Xhline{1pt}
        \multicolumn{2}{!{\vrule width 1pt}c|}{\multirow{2}{*}{\bf """ + wildcards.bin.upper() + r"""}}
        & \multirow{2}{*}{\bf """ + prior_defense_name + r"""} & \multicolumn{2}{c!{\vrule width 1pt}}{\bf\ourdefense{}} \\\Xcline{4-5}{0.125pt}
        \multicolumn{2}{!{\vrule width 1pt}c|}{} && \bf Track & \bf Delay \\\hline
        \multicolumn{1}{!{\vrule width 1pt}c!{\vrule width 0.125pt}}{\multirow{2}{2.5em}{\textit{SPEC\allowbreak{}2017}}} & \it P-core & """ + "&".join(table[0]) + r"""\\\cline{2-5}
         \multicolumn{1}{!{\vrule width 1pt}c!{\vrule width 0.125pt}}{}                                          & \it E-core & """ + "&".join(table[1]) + r""" \\\hline
        \multicolumn{2}{!{\vrule width 1pt}c|}{\it PARSEC}                      & """ + "&".join(table[2]) + r""" \\\Xhline{1pt}
    \end{tabular}
            """
            print(s, file=f)
