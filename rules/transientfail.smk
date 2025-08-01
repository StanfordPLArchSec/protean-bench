rule clone_transientfail:
    input:
        clang = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang"
    output:
        directory("transientfail/{bin}/src")
    params:
        git_url = "https://github.com/isec-tugraz/transientfail.git",
        clang = lambda w: os.path.abspath(get_compiler(w.bin)["bin"] + "/bin/clang"),
    shell:
        "rm -rf {output} && "
        "git clone {params.git_url} {output} && "
        "find {output} -name Makefile | xargs -n1 sed -i 's|gcc|{params.clang}|g' && "
        "sed -i 's|#include <seccomp.h>||g' {output}/pocs/spectre/STL/main.c"

def transientfail_stem(w):
    if w.spec == "stl":
        assert w.mode == "sa_ip"
        return "{spec}"
    else:
        return "{spec}/{mode}"

def transientfail_make_target(w):
    return expand("spectre/" + transientfail_stem(w), spec=w.spec, mode=w.mode)

def transientfail_orig_exe(w):
    return expand("transientfail/{bin}/src/pocs/spectre/" + transientfail_stem(w) + "/poc_x86",
                  bin=w.bin, spec=w.spec.upper(), mode=w.mode)
        
rule build_transientfail:
    input:
        "transientfail/{bin}/src"
    output:
        "transientfail/{bin}/{spec}/{mode}/exe"
    params:
        make = transientfail_make_target,
        orig_exe = transientfail_orig_exe,
    shell:
        'make -C {input}/pocs {params.make} && cp {params.orig_exe} {output}'

rule run_transientfail:
    input:
        exe = "transientfail/{bin}/{spec}/{mode}/exe",
        gem5 = lambda w: expand("../gem5/{sim}/build/X86_MESI_Three_Level/gem5.opt",
                                sim=hwconf_to_sim(w.hwconf)),
        script = lambda w: expand("../gem5/{sim}/configs/deprecated/example/se.py",
                                  sim=hwconf_to_sim(w.hwconf)),
    output:
        "transientfail/{bin}/{spec}/{mode}/{hwconf}/stamp.txt"
    params:
        outdir = lambda w: expand("transientfail/{bin}/{spec}/{mode}/{hwconf}", **w),
        gem5_opts = lambda w: get_hwconf(w.hwconf)["gem5_opts"],
        script_opts = lambda w: [x for x in get_hwconf(w.hwconf)["script_opts"]
                                 if x not in ["--ruby", "--enable-prefetch"]],
    shell:
        'ulimit -t 3600; '
        '{input.gem5} -re --silent-redirect -d {params.outdir} {params.gem5_opts} {input.script} --output=stdout.txt --errout=stderr.txt --cpu-type=X86O3CPU --caches {params.script_opts} --num-cpus=4 -- {input.exe}; '
        'rc=$? && '
        'if [ $rc -eq 152 ]; then rc=0 && touch {output}; fi && '
        'exit $rc'
