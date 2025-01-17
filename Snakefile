# TODO: Move these to config file?
gem5_pin_src = "../gem5/pincpu"
gem5_pin_exe = gem5_pin_src + "/build/X86/gem5.opt"
gem5_pin_configs = gem5_pin_src + "/configs"
addr2line = "../llvm/base-17/build/bin/llvm-addr2line"

bingroups = {
    "main": ["base", "nst"],
}

rule bbhist:
    input:
        gem5 = gem5_pin_exe,
        bbhist_py = gem5_pin_configs + "/pin-bbhist.py",
        exe = "{bench}/bin/{bin}/exe",
        argfile = "{bench}/inputs/{input}",
    output:
        bbhist_txt = "{bench}/cpt/{input}/{bingroup}/{bin}/bbhist.txt",
    params:
        bindir = "{bench}/bin/{bin}",
        exe = "{bench}/bin/{bin}/exe",
        rundir = "{bench}/bin/{bin}/run",
        outdir = "{bench}/cpt/{input}/{bingroup}/{bin}/bbhist",
    shell:
        "if [ -d {params.outdir} ]; then rm -r {params.outdir}; fi && " \
        "{input.gem5} -re --silent-redirect -d {params.outdir} " \
        "{input.bbhist_py} --stdin=/dev/null --stdout=stdout.txt --stderr=stderr.txt " \
        "--mem-size=512MiB --max-stack-size=8MiB --chdir={params.rundir} " \
        "--bbhist={output.bbhist_txt} " \
        "-- {input.exe} $(cat {input.argfile})"

rule instlist:
    input:
        bbhist_txt = "{dir,.*}/bbhist.txt",
        instlist_py = "helpers/instlist.py",
    output:
        instlist_txt = "{dir,.*}/instlist.txt",
    shell:
        "{input.instlist_py} < {input.bbhist_txt} > {output.instlist_txt}"

rule srclist:
    input:
        exe = "{bench}/bin/{bin}/exe",
        instlist = "{bench}/cpt/{input}/{bingroup}/{bin}/instlist.txt",
    output:
        srclist = "{bench}/cpt/{input}/{bingroup}/{bin}/srclist.txt"
    shell:
        addr2line + " --exe {input.exe} --output-style=JSON < {input.instlist} > {output.srclist}"

rule srclocs:
    input:
        srclist_txt = "{dir,.*}/srclist.txt",
        srclocs_py = "helpers/srclocs.py",
    output:
        srclocs = "{dir,.*}/srclocs.txt"
    shell:
        "{input.srclocs_py} < {input.srclist_txt} > {output.srclocs}"

rule lehist:
    input:
        bbhist_txt = "{dir,.*}/bbhist.txt",
        srclocs_txt = "{dir,.*}/srclocs.txt",
        lehist_py = "helpers/lehist.py",
    output:
        lehist_txt = "{dir,.*}/lehist.txt"
    shell:
        "{input.lehist_py} --bbhist={input.bbhist_txt} --srclocs={input.srclocs_txt} > {output.lehist_txt}"

rule shlocedges:
    input:
        lehist_txts = lambda wildcards: expand("{bench}/cpt/{input}/{bingroup}/{bin}/lehist.txt", bench=wildcards.bench, input=wildcards.input, bingroup=wildcards.bingroup, bin=bingroups[wildcards.bingroup]),
        shlocedges_py = "helpers/shlocedges.py",
    output:
        shlocedges_txt = "{bench}/cpt/{input}/{bingroup}/shlocedges.txt"
    shell:
        "{input.shlocedges_py} {input.lehist_txts} > {output.shlocedges_txt}"
