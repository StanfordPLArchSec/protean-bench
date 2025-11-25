import bench

mem = "10GiB"

bench.make_bench("wasm.605").add_input("inp.in", mem_size=mem)
bench.make_bench("wasm.625").add_input("--dumpyuv 50 --frames 156 -o BuckBunny_New.264 BuckBunny.yuv 1280x720", mem_size=mem)
bench.make_bench("wasm.657").add_input("cpu2006docs.tar.xz 4 055ce243071129412e9dd0b3b69a21654033a9b723d874b2015c774fac1553d9713be561ca86f74e4f16f22e664fc17a79f30caa5ad2c04fbc447549c2810fae 1548636 1555348 0", mem_size=mem)


