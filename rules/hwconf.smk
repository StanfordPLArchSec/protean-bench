def get_hwconf_addons(wildcards):
    addons_dir = "hwconfs/addons"
    addons = wildcards.addons.split(".")
    return expand("hwconfs/addons/{addon}", addon=addons)

rule hwconf:
    input:
        hwconf_base = "hwconfs/{hwconf}",
        hwconf_addons = get_hwconf_addons,
    output:
        hwconf = "hwconfs/{hwconf}.{addons}"
    wildcard_constraints:
        hwconf = r"\w+",
        addons = r"\w+(\.\w+)*",
    shell:
        "echo $(cat {input.hwconf_base} {input.hwconf_addons}) > {output.hwconf}"
        
