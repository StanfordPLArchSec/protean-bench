rule bbhist:
    input:
        "../gem5/pincpu/build/X86/gem5.opt",
        "../gem5/pincpu/configs/pin.py",
        "x264/bin/base/exe",
    output:
        "x264/cpt/0/main/base/bbhist.txt"
    shell:
        "if [ -d x264/cpt/0/main/base/bbhist ]; then rm -r x264/cpt/0/main/base/bbhist; fi && " \
        "../gem5/pincpu/build/X86/gem5.opt -re --silent-redirect -d x264/cpt/0/main/base/bbhist ../gem5/pincpu/configs/pin-bbhist.py --stdin=/dev/null --stdout=stdout.txt --stderr=stderr.txt --mem-size=512MiB --max-stack-size=8MiB --chdir=x264/bin/base/run --bbhist=x264/cpt/0/main/base/bbhist.txt -- x264/bin/base/exe --pass 1 --stats x264_stats.log --bitrate 1000 --frames 1000 -o BuckBunny_New.264 BuckBunny.yuv 1280x720"
