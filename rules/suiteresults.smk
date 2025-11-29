import benchsuites

rule suite_results_json:
    input:
        results = lambda w: expand("{bench}/exp/0/{bingroup}/{bin}/{hwconf}/results.json",
                                   bench=benchsuites.benchsuites[w.suite], **w),
        script = "helpers/generate-suite-results.py",
    output:
        "_{suite}/exp/0/{bingroup}/{bin}/{hwconf}/results.json"
    shell:
        "{input.script} {input.results} --output={output}"
