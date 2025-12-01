def predictor_prottrack_inputs(bin):
    return expand("_cpu2017.int/exp/0/main/{bin}/prottrack.{pred}.atret.pcore/results.json",
                  pred = ["unprot", *map(lambda n: f"pred{2 ** n}", range(0, 13)), "pred0"],
                  bin = bin)

rule predictor_mispredict_rate_csv:
    input:
        base_prottrack = predictor_prottrack_inputs("base"),
        ct_prottrack = predictor_prottrack_inputs("ct"),
    output:
        "figures/predictor-mispredict-rate.csv"
    run:
        values = []
        def get_misprate(path):
            with open(path) as f:
                j = json.load(f)
            return j["stats"]["access-misp-rate"]["arithmean"]
        for base_path, ct_path in zip(input.base_prottrack, input.ct_prottrack):
            value = (get_misprate(base_path) + get_misprate(ct_path)) / 2
            values.append(value)
        with open(output[0], "wt") as f:
            print("none,1,2,4,8,16,32,64,128,256,512,1024,2048,4096,infinite", file=f)
            print(",".join(map(str, values)), file=f)

rule predictor_runtime_csv:
    input:
        base_unsafe = "_cpu2017.int/exp/0/main/base/unsafe.pcore/results.json",
        base_prottrack = predictor_prottrack_inputs("base"),
        ct_prottrack = predictor_prottrack_inputs("ct"),
    output:
        "figures/predictor-runtime.csv"
    run:
        def get_cycles(path):
            with open(path) as f:
                j = json.load(f)
            return j["stats"]["cycles"]["geomean"]
        cycles_unsafe = get_cycles(input.base_unsafe)
        values = []
        for l in zip(input.base_prottrack, input.ct_prottrack):
            value = math.prod(map(get_cycles, l)) ** (1 / len(l)) / cycles_unsafe
            values.append(value)
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
