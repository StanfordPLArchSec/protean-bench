localrules: predictor_mispredict_rate_csv predictor_runtime_csv predictor_figure

rule predictor_mispredict_rate_csv:
    input:
        expand("_cpu2017.int/exp/0/main/base/prottrack.{pred}.atret.pcore/results.json",
               pred = ["unprot", *map(lambda n: f"pred{2 ** n}", range(0, 13)), "pred0"])
    output:
        "figures/predictor-mispredict-rate.csv"
    run:
        values = []
        for path in input:
            with open(path) as f:
                j = json.load(f)
            values.append(j["stats"]["access-misp-rate"]["arithmean"])
        with open(output[0], "wt") as f:
            print("none,1,2,4,8,16,32,64,128,256,512,1024,2048,4096,infinite", file=f)
            print(",".join(map(str, values)), file=f)

rule predictor_runtime_csv:
    input:
        base = "_cpu2017.int/exp/0/main/base/unsafe.pcore/results.json",
        prottrack = expand(
            "_cpu2017.int/exp/0/main/base/prottrack.{pred}.atret.pcore/results.json",
            pred = ["unprot", *map(lambda n: f"pred{2 ** n}", range(0, 13)), "pred0"])
    output:
        "figures/predictor-runtime.csv"
    run:
        def get_cycles(path):
            with open(path) as f:
                j = json.load(f)
            return j["stats"]["cycles"]["geomean"]
        cycles_base = get_cycles(input.base)
        values = []
        for path in input.prottrack:
            values.append(get_cycles(path) / cycles_base)
        with open(output[0], "wt") as f:
            print("none,1,2,4,8,16,32,64,128,256,512,1024,2048,4096,infinite", file=f)
            print(",".join(map(str, values)), file=f)

rule predictor_figure:
    input:
        rate_csv = "figures/predictor-mispredict-rate.csv",
        runtime_csv = "figures/predictor-runtime.csv",
        script = "figures/predictor.py",
    output:
        "figures/predictor.pdf"
    localrule: True
    container: None
    shell:
        "{input.script} --rate-csv={input.rate_csv} --runtime-csv={input.runtime_csv} "
        "-o {output} --no-crop"
