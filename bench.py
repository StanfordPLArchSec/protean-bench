import math
import humanfriendly

benches = []

def time_to_minutes(s):
    h, m, s = map(int, s.split(":"))
    return math.ceil(h * 60 + m + s / 60)

class Input:
    def __init__(self, name: str, args: str, stdin: str, mem_size: str, stack_size: str, deps: list, runtime: str, host_mem: str):
        self.name = name
        self.args = args
        self.mem_size = mem_size
        self.stack_size = stack_size
        self.stdin = stdin
        self.deps = deps
        self.runtime = runtime
        self.host_mem = host_mem

    # TODO: Rename to reflect host.
    def mem_plus(self, s: str) -> str:
        a = humanfriendly.parse_size(self.host_mem)
        b = humanfriendly.parse_size(s)
        return humanfriendly.format_size(a + b)

    def runtime_seconds(self) -> int:
        return time_to_minutes(self.runtime)


class Benchmark:
    def __init__(self, name: str):
        self.name = name
        self.inputs = []

    def add_input(self, args: str = "", stdin: str = "/dev/null", mem_size: str = "512MiB", stack_size: str = "8MiB", deps = [], runtime = "01:00:00",
                  host_mem = None):
        if not host_mem:
            host_mem = mem_size
        self.inputs.append(Input(
            name = str(len(self.inputs)),
            args = args,
            stdin = stdin,
            mem_size = mem_size,
            stack_size = stack_size,
            deps = deps,
            runtime = runtime,
            host_mem = host_mem,
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
    
