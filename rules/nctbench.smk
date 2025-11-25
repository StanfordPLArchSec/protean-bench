from bench import make_bench

make_bench("nctbench.openssl.dh").add_input("512 100000")
make_bench("nctbench.openssl.bnexp").add_input("512 100000")
make_bench("nctbench.openssl.ecadd").add_input("10000000")
