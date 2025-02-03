# TODO: Factor out common code with resume_from_checkpoint[_o3].
rule resume_from_checkpoint_kvm:
    input:
        cpt_data = get_checkpoint,
        gem5 = lambda wildcards: expand("../gem5/{sim}/build/X86_MESI_Three_Level/gem5.opt", sim=hwconf_to_sim(wildcards.hwconf)),
        exe = "{bench}/bin/{bin}/exe",
        run_script = lambda wildcards: expand("../gem5/{sim}/configs/AlderLake/se.py", sim=hwconf_to_sim(wildcards.hwconf)),
    output:
        stamp = "{bench}/exp/{input}/{bingroup}/{bin}/host/stamp.txt",
    params:
        **rules._pincpu.params, # TODO: Shouldn't inherit it from PinCPU!
        cptdir = "{bench}/cpt/{input}/{bingroup}/{bin}/cpt",
        outdir = "{bench}/exp/{input}/{bingroup}/{bin}/host/{cptid}",
        gem5_opts = lambda w: get_hwconf(w.hwconf)["gem5_opts"],
        script_opts = lambda w: get_hwconf(w.hwconf)["script_opts"],
    threads: 1
    resources:
        mem = rules._pincpu.rule.resources["mem"], # TOOD: Shouldn't inherit directly from PinCPU.
        runtime = "3h", # TODO: Consider making this dynamic.
    shell:
        "if [ -d {params.outdir} ]; then rm -r {params.outdir}; fi && "
        "{input.gem5} -re --silent-redirect -d {params.outdir} --debug-file=dbgout.txt.gz {params.gem5_opts} "
        "{input.run_script} --input=/dev/null --output=stdout.txt --errout=stderr.txt "
        "--cpu-type=X86KvmCPU "
        "--mem-size={params.mem} --max-stack-size={params.stack} --chdir={params.rundir} "
        "--checkpoint-dir={params.cptdir} "
        "--checkpoint-restore=$(({wildcards.cptid}+1)) "
        "--restore-simpoint-checkpoint "
        "--cmd={input.exe} "
        "--options=\"{params.workload_args}\" "
        "{params.script_opts} "
        " && touch {output.stamp} "
