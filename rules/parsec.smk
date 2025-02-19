class Benchmark:
    def __init__(self, name, run_args, mem = None, env = False, exe = None, dir = 'apps'):
        self.name = name
        self.arg_template = run_args
        self.mem = mem
        self.env = env
        self.exe = exe if exe else name
        self.dir = dir

    def root_dir(self) -> str:
        return os.path.join('pkgs', self.dir, self.name)

    def bin_dir(self, sw_name) -> str:
        return self.root_dir() + f'/inst/amd64-linux.ptex-{sw_name}/bin'

    def run_dir(self) -> str:
        return self.root_dir() + '/run'

    def get_exe(self, sw_name) -> str:
        return os.path.join(self.bin_dir(sw_name), self.exe)

    def build_cmd(self, sw_name) -> str:
        return f'bin/parsecmgmt -a build -c ptex-{sw_name} -p {self.name}'

    def args(self) -> str:
        return self.arg_template["simsmall"] # TODO: Parameterize.

    def get_env_script_opts(self) -> list:
        return [f'--env=../env.txt'] if self.env else []

benches = [
    Benchmark(
        name = 'blackscholes',
        run_args = {
            'simsmall':  '15 in_4K.txt prices.txt',
            'simmedium': '15 in_16K.txt prices.txt',
            'simlarge':  '15 in_64K.txt prices.txt',
        }
    ),
    Benchmark(
        name = 'bodytrack',
        run_args = {
            'simsmall':  'sequenceB_1 4 1 1000 5 0 14',
            'simmedium': 'sequenceB_2 4 2 2000 5 0 14',
            'simlarge':  'sequenceB_4 4 4 4000 5 0 14',
        },
    ),
    Benchmark(
        name = 'facesim',
        run_args = {
            'simsmall':  '-timing -threads 2',
            'simmedium': '-timing -threads 2',
            'simlarge':  '-timing -threads 2',
        },
        mem = '4GB'
    ),
    # WARN: May need to fix up thread count here (the number right before output.txt).
    # NOTE: Disabled due to crash. Apparent gem5 base bug (null pointer dereference).
    Benchmark(
        name = 'ferret',
        run_args = {
            'simsmall': 'corel lsh queries 10 20 3 output.txt',
        },
    ),
    Benchmark(
        name = 'fluidanimate',
        run_args = {
            'simsmall':  '8 1 in_35K.fluid  out.fluid',
            'simmedium': '8 5 in_100K.fluid out.fluid',
            'simlarge':  '8 5 in_300K.fluid out.fluid',
        },
    ),
    # WARN: Untested on host.
    # TODO: Need to set OMP_NUM_THREADS.
    # NOTE: Skipping for now because it requires clang being compiled with OpenMP.
    Benchmark(
        name = 'freqmine',
        run_args = {'simsmall': 'kosarak_250k.dat 220'},
    ),
    # WARN: May need to fix up number of threads.
    Benchmark(
        name = 'raytrace',
        exe = 'rtview',
        run_args = {'simsmall': 'happy_buddha.obj -automove -nthreads 15 -frames 3 -res 480 270'},
    ),
    Benchmark(
        name = 'swaptions',
        run_args = {
            'simsmall':  '-ns 16 -sm 10000 -nt 7',
            'simmedium': '-ns 32 -sm 20000 -nt 7',
            'simlarge':  '-ns 64 -sm 40000 -nt 7',
        },
    ),
    # WARN: Untested on host.
    # NOTE: Disabled because sched_getparam is unimplemented.
    Benchmark(
        name = 'vips',
        run_args = {'simsmall': "im_benchmark pomegranate_1600x1200.v output.v"},
        env = True,
    ),
    # WARN: May need to fix up number of threads.
    Benchmark(
        name = 'x264',
        run_args = {'simsmall': '--quiet --qp 20 --partitions b8x8,i4x4 --ref 5 --direct auto --b-pyramid --weightb --mixed-refs --no-fast-pskip --me umh --subme 7 --analyse b8x8,i4x4 --threads 15 -o eledream.264 eledream_640x360_8.y4m'},
    ),

    # TODO: In pkgs/kernels.
    Benchmark(
        name = 'canneal',
        dir = 'kernels',
        run_args = {'simsmall': '15 10000 2000 100000.nets 32'},
    ),

    Benchmark(
        name = 'dedup',
        dir = 'kernels',
        run_args = {'simsmall': '-c -p -v -t 4 -i media.dat -o output.dat.ddp'},
    ),

    # TODO: In pkgs/kernels.
    Benchmark(
        name = 'streamcluster',
        dir = 'kernels',
        run_args = {'simsmall': '10 20 32 4096 4096 1000 none output.txt 4'},
    ),
]
benches = dict([(os.path.join(bench.dir, bench.name), bench) for bench in benches])

def get_parsec_bench(dir, name):
    return benches[os.path.join(dir, name)]

shared_env = "export LLVM=$(realpath {params.llvm}) " \
        "LIBC=$(realpath {params.libc}) " \
        "LIBCXX=$(realpath {params.libcxx}) " \
        "CCAS=$(realpath {params.llvm}/bin/clang) " \
        "GNU_HOST_NAME=x86_64-pc-linux-gnu " \
        "GNU_TARGET_NAME=x86_64-pc-linux-gnu " \
        "CC=$(realpath {input.clang}) " \
        "CXX=$(realpath {input.clangxx}) && "

rule build_parsec:
    input:
        clang = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang",
        clangxx = lambda w: get_compiler(w.bin)["bin"] + "/bin/clang++",
        flang = lambda w: get_compiler(w.bin)["bin"] + "/bin/flang-new",
        libc = "libraries/{bin}/libc/projects/libc/lib/libllvmlibc.a",
        libcxx = "libraries/{bin}/libcxx/lib/libc++.a",
        libcxxabi = "libraries/{bin}/libcxx/lib/libc++abi.a",
        bldconf = "parsec/config/ptex-{bin}.bldconf",
    output:
        # exe = "parsec/pkgs/{benchdir}/{bench}/inst/amd64-linux.ptex-{bin}/bin/{exename}",
        stamp = "parsec/pkgs/{benchdir}/{bench}/run/host.{bin}.stamp",
    params:
        build_cmd = lambda w: get_parsec_bench(w.benchdir, w.bench).build_cmd(w.bin),
        llvm = lambda w: get_compiler(w.bin)["bin"],
        libc = "libraries/{bin}/libc",
        libcxx = "libraries/{bin}/libcxx",
        outdir = lambda w: expand("parsec/pkgs/{benchdir}/{bench}/inst", **w)[0],
    shell:
        "STAMP=$(realpath {output.stamp}) && "
        "rm -r {params.outdir} && "
        + shared_env +
        "pushd parsec && "
        "{params.build_cmd} && "
        "popd && "
        "touch {output.stamp}"

rule run_parsec:
    input:
        stamp = "parsec/pkgs/{benchdir}/{bench}/run/host.{bin}.stamp",
        gem5 = lambda w: expand("../gem5/{sim}/build/X86_MESI_Three_Level/gem5.opt", sim=hwconf_to_sim(w.hwconf)),
        run_script = lambda w: expand("../gem5/{sim}/configs/AlderLake/run.py", sim=hwconf_to_sim(w.hwconf)),
    output:
        "parsec/pkgs/{benchdir}/{bench}/run/exp/{bin}/{hwconf}/stamp.txt"
    params:
        exe = lambda w: "parsec/" + get_parsec_bench(w.benchdir, w.bench).get_exe(w.bin),
        rundir = lambda w: "parsec/" + get_parsec_bench(w.benchdir, w.bench).run_dir(),
        outdir = "parsec/pkgs/{benchdir}/{bench}/run/exp/{bin}/{hwconf}",
        gem5_opts = lambda w: get_hwconf(w.hwconf)["gem5_opts"],
        script_opts = lambda w: get_hwconf(w.hwconf)["script_opts"],
        bench_args = lambda w: get_parsec_bench(w.benchdir, w.bench).args(),
        env_script_opts = lambda w: get_parsec_bench(w.benchdir, w.bench).get_env_script_opts(),
    shell:
        "{input.gem5} --outdir={params.outdir} -re {params.gem5_opts} "
        "{input.run_script} {params.script_opts} --chdir={params.rundir} "
        "-c {params.exe} --options='{params.bench_args}' {params.env_script_opts} && "
        "touch {output}"

# rule run_parsec:
#     input:
#         gem5 = lambda wildcards: expand("../gem5/{sim}/build/X86_MESI_Three_Level/gem5.opt", sim=hwconf_to_sim(wildcards.hwconf)),
#         # exe = lambda wildcards: wildcards.
#     output:
#         stamp = "parsec/{bench}/
