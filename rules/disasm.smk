rule disasm:
    input:
        "{bench}/bin/{bin}/exe"
    output:
        "{bench}/bin/{bin}/asm"
    shell:
        "objdump -d {input} > {output}"

