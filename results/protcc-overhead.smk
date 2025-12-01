import pathlib
import benchsuites
import math
import subprocess
import re

rule protcc_overhead:
    input:
        exes = expand("{bench}/bin/{bin}/exe",
                      bench = benchsuites.benchsuites["cpu2017.int"],
                      bin = ["base", "cts", "ct", "nct"]),
        results = expand("_cpu2017.int/exp/0/main/{bin}/unsafe.pcore/results.json",
                         bin = ["base", "cts", "ct", "nct"]),
        template = "results/protcc-overhead.tex.in",
    output:
        "results/protcc-overhead.tex"
    run:
        output, = output

        def codesize_single(bin, bench):
            exe, = expand("{bench}/bin/{bin}/exe",
                          bench = bench,
                          bin = bin)
            assert exe in input.exes, exe
            out = subprocess.check_output(["llvm-size", "--format=sysv", exe], text=True)
            for line in out.splitlines():
                line = line.strip()
                if m := re.fullmatch(r"\.text\s+(\d+)\s+(\d+)", line):
                    return int(m.group(1))
            assert False, "didn't find text in llvm-size output!"
        def codesize(bin):
            l = []
            for bench in benchsuites.benchsuites["cpu2017.int"]:
                l.append(codesize_single(bin, bench))
            return math.prod(l) ** (1 / len(l))
        def cycles(bin):
            path, = expand("_cpu2017.int/exp/0/main/{bin}/unsafe.pcore/results.json",
                           bin = bin)
            assert path in input.results, path
            return json.loads(pathlib.Path(path).read_text())["stats"]["cycles"]["geomean"]

        # Get absolute code sizes and runtimes.
        table = []
        for f in [codesize, cycles]:
            table.append([])
            for bin in ["base", "cts", "ct", "nct"]:
                table[-1].append(f(bin))

        # Compute the overheads.
        for row in table:
            z = row[0]
            for i in range(len(row)):
                x = row[i] / z
                x = (x - 1) * 100
                row[i] = f"{x:.1f}\\%"

        for i in range(len(table)):
            table[i] = "/".join(table[i][1:])

        codesize_overhead = table[0]
        runtime_overhead = table[1]

        text = pathlib.Path(input.template).read_text()
        text = text.replace("@codesize_overhead@", codesize_overhead)
        text = text.replace("@runtime_overhead@", runtime_overhead)
        pathlib.Path(output).write_text(text)
