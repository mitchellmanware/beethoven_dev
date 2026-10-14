########################################################################################
# Generate spatiotemporal cross validation rset objects for model fitting.
rule model_cross:
    input:
        dt_feat_merge_sptmpl="output/dt_feat_merge_sptmpl.qs"

    output:
        list_base_params_static="output/list_base_params_static.qs",
        list_base_cv_rset="output/list_base_cv_rset.qs"
    
    params:
        chr_config_dir=os.path.join(
            os.environ["HOME"],
            config["chr_config_dir"],
        )

    container:
        "container/sif/container_models.sif"

    script:
        "../scripts/d01_cross.R"

########################################################################################