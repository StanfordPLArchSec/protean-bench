import math

benches = []

def time_to_minutes(s):
    h, m, s = map(int, s.split(":"))
    return math.ceil(h * 60 + m + s / 60)

class Input:
    def __init__(self, name: str, args: str, stdin: str, mem_size: str, stack_size: str, deps: list, runtime: str):
        self.name = name
        self.args = args
        self.mem_size = mem_size
        self.stack_size = stack_size
        self.stdin = stdin
        self.deps = deps
        self.runtime = runtime

    def mem_mib(self) -> int:
        s = self.mem_size
        suffixes = {"MiB": 1, "GiB": 1024}
        for suffix, multiplier in suffixes.items():
            if s.endswith(suffix):
                return int(s.removesuffix(suffix))
        raise ValueError(f"Unrecognized human-readable memory size {s}")

    def runtime_seconds(self) -> int:
        return time_to_minutes(self.runtime)


class Benchmark:
    def __init__(self, name: str):
        self.name = name
        self.inputs = []

    def add_input(self, args: str = "", stdin: str = "/dev/null", mem_size: str = "512MiB", stack_size: str = "8MiB", deps = [], runtime = "01:00:00"):
        self.inputs.append(Input(
            name = str(len(self.inputs)),
            args = args,
            stdin = stdin,
            mem_size = mem_size,
            stack_size = stack_size,
            deps = deps,
            runtime = runtime,
        ))
        return self

    def get_input(self, name: str):
        matches = list(filter(lambda input: input.name == name, self.inputs))
        if len(matches) != 1:
            raise KeyError(f"Benchmark {self.name} has no input {name}")
        return matches[0]

def make_bench(name: str):
    bench = Benchmark(name)
    benches.append(bench)
    return bench

def get_bench(name: str):
    matches = list(filter(lambda bench: bench.name == name, benches))
    if len(matches) != 1:
        raise KeyError(f"Benchmark not found: {name}")
    return matches[0]
    
