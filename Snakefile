########################################################################################
# Path to BEETHOVEN configuration file.
configfile: "config/config.yaml"

########################################################################################
print(
    f"Running {{beethoven}} pipeline: "
    f"{config['chr_config_daterange']['start']} - "
    f"{config['chr_config_daterange']['end']}"
)

########################################################################################
# Define pipeline endpoint.
rule all:
    input:
        "output/dt_pred_merge_sptmpl.qs"

###############################      PIPELINE RULES      ###############################
include: "rules/a01_initiate.smk"
include: "rules/b01_download.smk"
include: "rules/c01_calculate.smk"
include: "rules/f01_grid.smk"
