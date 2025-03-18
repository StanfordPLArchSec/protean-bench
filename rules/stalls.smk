# Compute stalls.txt for a single checkpoint.
rule stalls_checkpoint:
    input:
        dbgout_txt_gz = "{bench}/exp/{input}/{bingroup}/{bin}/{hwconf}/{cptid}/dbgout.txt.gz",
        stallhist_script = "helpers/stallhist.py",
        addr2line_script = "helpers/profile/addr2line.py",
        exe = "{bench}/bin/{bin}/exe",
        cptdir = "{bench}/cpt/{input}/{bingroup}/{bin}/cpt" # Just so Snakemake doesn't complain about missing checkpoint input dependency.
    output:
        stalls_txt = "{bench}/exp/{input}/{bingroup}/{bin}/{hwconf}/{cptid}/stalls.txt"
    params:
        weight = get_simpoint_weight,
        addr2line = addr2line,
    shell:
        "gunzip < {input.dbgout_txt_gz} | {input.stallhist_script} | {input.addr2line_script} --exe={input.exe} --addr2line={params.addr2line} --field=1 --basename | awk '{{ printf \"%d %s\\n\", $1 * {params.weight}, $2 }}' > {output.stalls_txt}"

rule stalls_bench:
    input:
        stalls_txts = lambda wildcards: get_exp_checkpoints(wildcards, "stalls.txt")
    output:
        stalls_txt = "{bench}/exp/{input}/{bingroup}/{bin}/{hwconf}/stalls.txt"
    shell:
        "awk '{{ hist[$2] += $1 }} END {{ for (pc in hist) print hist[pc], pc}}' {input.stalls_txts} | sort -n -r > {output.stalls_txt}"



rule stalls_ctrl_checkpoint:
    input:
        dbgout_txt_gz = "{bench}/exp/{input}/{bingroup}/{bin}/{hwconf}/{cptid}/dbgout.txt.gz",
        script = "helpers/stallhist.py",
        cptdir = "{bench}/cpt/{input}/{bingroup}/{bin}/cpt" # Just so Snakemake doesn't complain about missing checkpoint input dependency.
    output:
        stalls_txt = "{bench}/exp/{input}/{bingroup}/{bin}/{hwconf}/{cptid}/stalls-ctrl.txt"
    params:
        weight = get_simpoint_weight,
        regex = r" wrip ",
    shell:
        "gunzip < {input.dbgout_txt_gz} | {input.script} --regex='{params.regex}' | awk '{{ printf \"%d %s\\n\", $1 * {params.weight}, $2 }}' > {output.stalls_txt}"

rule stalls_ctrl_bench:
    input:
        stalls_txts = lambda wildcards: get_exp_checkpoints(wildcards, "stalls-ctrl.txt")
    output:
        stalls_txt = "{bench}/exp/{input}/{bingroup}/{bin}/{hwconf}/stalls-ctrl.txt"
    shell:
        "awk '{{ hist[$2] += $1 }} END {{ for (pc in hist) print hist[pc], pc}}' {input.stalls_txts} | sort -n -r > {output.stalls_txt}"

        
