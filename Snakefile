gem5_pin_src = "../gem5/pincpu"
gem5_pin_exe = gem5_pin_src + "/build/X86/gem5.opt"
gem5_pin_configs = gem5_pin_src + "/configs"

rule bbhist:
    input:
        gem5_pin_exe,
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
        "../gem5/pincpu/build/X86/gem5.opt -re --silent-redirect -d {params.outdir} " \
        "{input.bbhist_py} --stdin=/dev/null --stdout=stdout.txt --stderr=stderr.txt " \
        "--mem-size=512MiB --max-stack-size=8MiB --chdir={params.rundir} " \
        "--bbhist={output.bbhist_txt} " \
        "-- {input.exe} $(cat {input.argfile})"
