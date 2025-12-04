import benchsuites
import os
from pathlib import Path

webserv_confs = [
    "base/unsafe.se",
    "base/sptsb.se.atret",
    "nct.ossl-annot/prottrack.se.atret",
    "nct.ossl-annot/protdelay.se.atret",
]

rule webserv_table_tex:
    input:
        expand("webserv/exp/{inp}/{conf}/stamp.txt",
               inp = benchsuites.benchsuites["webserv"],
               conf = webserv_confs)
    output:
        csv = "tables/webserv.csv",
        tex = "tables/webserv.tex",
    run:
        table = []
        base_conf, *defense_confs = webserv_confs
        def seconds(inp, conf):
            path, = expand("webserv/exp/{inp}/{conf}/stats.txt",
                           inp = inp,
                           conf = conf)
            stamp = Path(path).with_name("stamp.txt")
            assert str(stamp) in input, f"{stamp=}\n{input=}"
            l = []
            for line in Path(path).read_text().splitlines():
                if m := re.match(r"simSeconds\s+([0-9.]+)", line):
                    l.append(m.group(1))
            assert len(l) >= 1
            return float(l[-1])
        for inp in benchsuites.benchsuites["webserv"]:
            table.append([f"nginx.{inp}"])
            base_seconds = seconds(inp, base_conf)
            for defense_conf in defense_confs:
                defense_seconds = seconds(inp, defense_conf)
                table[-1].append(defense_seconds / base_seconds)

        # Compute geomean.
        geomean_row = [r"geomean"]
        for i in range(1, len(table[0])):
            l = []
            for row in table:
                l.append(row[i])
            geomean_row.append(math.prod(l) ** (1 / len(l)))
        table.append(geomean_row)

        # Dump CSV.
        with open(output.csv, "wt") as f:
            print(f"Multi-Class Webserver,SPT-SB,Protean (ProtTrack),Protean (ProtDelay)", file=f)
            for row in table:
                print(",".join(map(str, row)), file=f)

        # Dump table.
        with open(output.tex, "wt") as f:
            # Header.
            print(r"\bf \multirow{2}{*}{\makecell{Multi-Class\\Webserver}} & "
                  r"\bf \multirow{2}{*}{\makecell{SPT-\\SB}} & "
                  r"\multicolumn{2}{c!{\vrule width 1pt}}{\bf\textsc{Protean}} "
                  r"\\\cline{3-4}",
                  file=f)
            print(r"&& \bf Track & \bf Delay \\\hline", file=f)
            for row in table:
                def fixup_cell(s):
                    if type(s) is not str:
                        s = f"{s:.3f}"
                    if row is table[-1]:
                        s = r"\it " + s
                    return s
                print(" & ".join(map(fixup_cell, row)), end="", file=f)
                if row is table[-1]:
                    print(r"\\\Xhline{1pt}", file=f)
                else:
                    print(r"\\\hline", file=f)
