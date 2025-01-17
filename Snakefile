rule bbhist:
    input:
        "../gem5/pincpu/build/X86/gem5.opt",
        "../gem5/pincpu/configs/pin-bbhist.py",
        "{bench}/bin/{bin}/exe",
        "{bench}/inputs/{input}",
    output:
        "{bench}/cpt/{input}/{bingroup}/{bin}/bbhist.txt",
    params:
        bindir = "{wildcards.bench}/bin/{wildcards.bin}",
        exe = "{params.bindir}/exe",
        rundir = "{params.bindir}/run",
        cptdir = "{wildcards.bench}/cpt/{wildcards.input}/{wildcards.bingroup}/{wildcards.bin}",
        outdir = "{params.cptdir}/bbhist"
    shell:
        "if [ -d {wildcards.bench}/cpt/{wildcards.input}/{wildcards.bingroup}/{wildcards.bin}/bbhist ]; then rm -r {wildcards.bench}/cpt/{wildcards.input}/{wildcards.bingroup}/{wildcards.bin}/bbhist; fi && " \
        "../gem5/pincpu/build/X86/gem5.opt -re --silent-redirect -d {wildcards.bench}/cpt/{wildcards.input}/{wildcards.bingroup}/{wildcards.bin}/bbhist " \
        "../gem5/pincpu/configs/pin-bbhist.py --stdin=/dev/null --stdout=stdout.txt --stderr=stderr.txt " \
        "--mem-size=512MiB --max-stack-size=8MiB --chdir={wildcards.bench}/bin/{wildcards.bin}/run " \
        "--bbhist={wildcards.bench}/cpt/{wildcards.input}/{wildcards.bingroup}/{wildcards.bin}/bbhist.txt " \
        "-- {wildcards.bench}/bin/{wildcards.bin}/exe $(cat {wildcards.bench}/inputs/{wildcards.input})"
