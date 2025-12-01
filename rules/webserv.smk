import json

include: "siege.smk"

def webserv_port(w):
    bins = ["base", "nct.ossl-annot"]
    hwconfs = ["unsafe.se", "sptsb.se.atret", "prottrack.se.atret", "protdelay.se.atret"]
    clients = [1, 2, 4]
    reqs = [1, 2, 4]

    i = 0
    i += bins.index(w.bin)
    i *= len(bins)
    i += hwconfs.index(w.hwconf)
    i *= len(hwconfs)
    i += clients.index(int(w.clients))
    i *= len(clients)
    i += reqs.index(int(w.reqs))

    return 8443 + i

rule webserv_conf:
    input: "applications/{bin}/nginx/conf/nginx.conf"
    output: "applications/{bin}/nginx/conf/nginx.conf.{port}"
    shell:
        "sed 's/listen 8443 ssl/listen {wildcards.port} ssl/' {input} > {output}"

rule webserv_run:
    input:
        nginx = "applications/{bin}/nginx/sbin/nginx",
        siege = "../siege/bin/siege",
        gem5 = lambda w: expand("../gem5/{sim}/build/X86_MESI_Three_Level/gem5.opt",
                                sim=hwconf_to_sim(w.hwconf)),
        script = lambda w: expand("../gem5/{sim}/configs/AlderLake/run.py",
                                  sim=hwconf_to_sim(w.hwconf)),
        runner = "../webservbench/run.py",
        nginx_conf = lambda w: expand(
            "applications/{bin}/nginx/conf/nginx.conf.{port}",
            bin = w.bin, port = webserv_port(w)),
    output:
        "webserv/exp/c{clients}r{reqs}/{bin}/{hwconf}/stamp.txt"
    params:
        port = webserv_port,
        outdir = "webserv/exp/c{clients}r{reqs}/{bin}/{hwconf}",
        gem5_opts = lambda w: get_hwconf(w.hwconf)["gem5_opts"],
        script_opts = lambda w: get_hwconf(w.hwconf)["script_opts"],
        stdout = "webserv/exp/c{clients}r{reqs}/{bin}/{hwconf}/stdout.txt",
        stderr = "webserv/exp/c{clients}r{reqs}/{bin}/{hwconf}/stderr.txt",
    resources:
        runtime = "8h"
    shell:
        "{input.runner} --port={params.port} "
        "  --nginx \"{input.gem5} --outdir={params.outdir} -re {params.gem5_opts} --debug-file=dbgout.txt.gz "
        "           {input.script} --input=/dev/null {params.script_opts} --cmd {input.nginx} --options=-c$(realpath {input.nginx_conf}) \" "
        "  --siege '{input.siege} -c{wildcards.clients} -r{wildcards.reqs} https://127.0.0.1:{params.port}/' >{params.stdout} 2>{params.stderr}  && "
        "touch {output}"
