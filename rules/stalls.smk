# Compute stalls.txt for a single checkpoint.
rule stalls_checkpoint:
    input:
        dbgout_txt_gz = "{bench}/exp/{input}/{bingroup}/{bin}/{hwconf}/{cptid}/dbgout.txt.gz",
        script = "helpers/stallhist.py",
        cptdir = "{bench}/cpt/{input}/{bingroup}/{bin}/cpt" # Just so Snakemake doesn't complain about missing checkpoint input dependency.
    output:
        stalls_txt = "{bench}/exp/{input}/{bingroup}/{bin}/{hwconf}/{cptid}/stalls.txt"
    params:
        weight = get_simpoint_weight
    shell:
        "gunzip < {input.dbgout_txt_gz} | {input.script} | awk '{{ printf \"%d %s\\n\", $1 * {params.weight}, $2 }}' > {output.stalls_txt}"

rule stalls_bench:
    input:
        stalls_txts = lambda wildcards: get_exp_checkpoints(wildcards, "stalls.txt")
    output:
        stalls_txt = "{bench}/exp/{input}/{bingroup}/{bin}/{hwconf}/stalls.txt"
    shell:
        "awk '{{ hist[$2] += $1 }} END {{ for (pc in hist) print hist[pc], pc}}' {input.stalls_txts} | sort -n -r > {output.stalls_txt}"
