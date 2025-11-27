import benchsuites

def tables_ctbench_get_results(bin, hwconf):
    return expand("{bench}/exp/0/ctbench/{bin}/{hwconf}.pcore/results.json",
           bench=benchsuites.benchsuites["ctbench"],
           bin=bin,
           hwconf=hwconf)

ctbench_confs = ["base/unsafe", "base/spt.atret",
                 "ct/prottrack.atret", "ct/protdelay.atret"]

rule ctbench_csv:
    input:
        expand("{bench}/exp/0/ctbench/{conf}.pcore/results.json",
               bench=benchsuites.benchsuites["ctbench"], conf=ctbench_confs)
    output:
        csv = "tables/ctbench.csv",
        # tex = "tables/ctbench.tex",
    run:
        table = []
        base_conf, *defense_confs = ctbench_confs
        def cycles(conf):
            path = f"{bench}/exp/0/ctbench/{conf}.pcore/results.json"
            assert path in input
            with open(path) as f:
                j = json.load(f)
            return j["stats"]["cycles"]
        for bench in benchsuites.benchsuites["ctbench"]:
            table.append([bench])
            base_cycles = cycles(base_conf)
            for conf in defense_confs:
                table[-1].append(cycles(conf) / base_cycles)
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
            print("CT-Crypto,SPT,Protean (ProtTrack),Protean (ProtDelay)", file=f)
            for row in table:
                print(",".join(map(str, row)), file=f)
                
                
                
            
