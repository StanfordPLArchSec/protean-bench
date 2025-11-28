import benchsuites

class_specific_confs = {
    "ctsbench": ["base/unsafe", "base/spt.atret", "cts/prottrack.atret", "cts/protdelay.atret"],
    "ctbench": ["base/unsafe", "base/spt.atret", "ct/prottrack.atret", "ct/protdelay.atret"],
    "nctbench": ["base/unsafe", "base/sptsb.atret", "nct/prottrack.atret", "nct/protdelay.atret"],
}

class_specific_names = {
    "ctsbench": ["CTS-Crypto", "SPT"],
    "ctbench": ["CT-Crypto", "SPT"],
    "nctbench": ["UNR-Crypto", "SPT-SB"],
}

rule class_specific_suite_csv:
    input:
        lambda w: expand(
            "{bench}/exp/0/{suite}/{conf}.pcore/results.json",
            bench=benchsuites.benchsuites[w.suite],
            suite=w.suite,
            conf=class_specific_confs[w.suite])
    output:
        csv = "tables/{suite}.csv",
    run:
        table = []
        base_conf, *defense_confs = class_specific_confs[wildcards.suite]
        def cycles(bench, conf):
            path = f"{bench}/exp/0/{wildcards.suite}/{conf}.pcore/results.json"
            assert path in input
            with open(path) as f:
                j = json.load(f)
            return j["stats"]["cycles"]
        for bench in benchsuites.benchsuites[wildcards.suite]:
            table.append([bench])
            base_cycles = cycles(bench, base_conf)
            for conf in defense_confs:
                table[-1].append(cycles(bench, conf) / base_cycles)
        # Compute geomean.
        geomean_row = ["geomean"]
        for i in range(1, len(table[0])):
            l = []
            for row in table:
                l.append(row[i])
            geomean_row.append(math.prod(l) ** (1 / len(l)))
        table.append(geomean_row)
        # Dump table as CSV.
        with open(output.csv, "wt") as f:
            suite_name, baseline_name = class_specific_names[wildcards.suite]
            print(f"{suite_name},{baseline_name},Protean (ProtTrack),Protean (ProtDelay)", file=f)
            for row in table:
                print(",".join(map(str, row)), file=f)

                
                
            
