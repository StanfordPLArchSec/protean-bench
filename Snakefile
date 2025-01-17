rule bbhist:
    input:
        "../gem5/pincpu/build/X86/gem5.opt",
        "../gem5/pincpu/configs/pin-bbhist.py",
        "{bench}/bin/{bin}/exe",
        "{bench}/inputs/{input}",
    output:
        "{bench}/cpt/{input}/{bingroup}/{bin}/bbhist.txt",
    params:
        bindir = "{bench}/bin/{bin}",
        exe = "{bench}/bin/{bin}/exe",
        rundir = "{bench}/bin/{bin}/run",
        outdir = "{bench}/cpt/{input}/{bingroup}/{bin}/bbhist",
    shell:
        "if [ -d {params.outdir} ]; then rm -r {params.outdir}; fi && " \
        "../gem5/pincpu/build/X86/gem5.opt -re --silent-redirect -d {params.outdir} " \
        "../gem5/pincpu/configs/pin-bbhist.py --stdin=/dev/null --stdout=stdout.txt --stderr=stderr.txt " \
        "--mem-size=512MiB --max-stack-size=8MiB --chdir={wildcards.bench}/bin/{wildcards.bin}/run " \
        "--bbhist={output} " \
        "-- {params.exe} $(cat {wildcards.bench}/inputs/{wildcards.input})"
