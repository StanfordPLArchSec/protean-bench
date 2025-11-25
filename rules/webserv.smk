rule webserv_run:
    input:
        nginx = "applications/{bin}/nginx/sbin/nginx",
        siege = "../siege/bin/siege",
        gem5 = lambda w: expand("../gem5/{sim}/build/X86_MESI_Three_Level/gem5.opt",
                                sim=hwconf_to_sim(w.hwconf)),
        script = lambda w: expand("../gem5/{sim}/configs/AlderLake/run.py",
                                  sim=hwconf_to_sim(w.hwconf)),
    output:
        "webserv/exp/c{clients}r{reqs}/{bin}/{hwconf}/stamp.txt"
    params:
        port = 8443,
        outdir = lambda w: expand("webserv/exp/c{clients}r{reqs}/{bin}/{hwconf}", **w),
        gem5_opts = lambda w: get_hwconf(w.hwconf)["gem5_opts"],
        script_opts = lambda w: get_hwconf(w.hwconf)["script_opts"],
    shell:
        "../webservbench/run.py "
        "  --nginx '{input.gem5} --outdir={params.outdir} -re {params.gem5_opts} --debug-file=dbgout.txt.gz "
        "           {input.script} {params.script_opts} --cmd {input.nginx}' "
        "  --siege '{input.siege} -c{wildcards.clients} -r{wildcards.reqs} https://127.0.0.1:8443/' && "
        "touch {output}"
