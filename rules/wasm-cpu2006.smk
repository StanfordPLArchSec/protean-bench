import bench

bench.make_bench("wasm.401").add_input("data/ref/input/input.source 280", mem_size="10GiB")
bench.make_bench("wasm.429").add_input("data/ref/input/inp.in", mem_size="10GiB")
bench.make_bench("wasm.462").add_input("1397 8", mem_size="10GiB")
bench.make_bench("wasm.473").add_input("BigLakes2048.cfg", mem_size="10GiB")
bench.make_bench("wasm.433").add_input(stdin="data/ref/input/su3imp.in", mem_size="10GiB")
bench.make_bench("wasm.444").add_input("--input data/all/input/namd.input --iterations 38 --output namd.out", mem_size="10GiB")
bench.make_bench("wasm.470").add_input("3000 reference.dat 0 0 100_100_130_ldc.of", mem_size="10GiB")
