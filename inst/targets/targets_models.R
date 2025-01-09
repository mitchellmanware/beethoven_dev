target_models <-
  list(
    ############################################################################
    ############################################################################
    #########################             DEV             ######################
    targets::tar_target(
      models_helloworld,
      command = system("echo \"hello world\"", intern = TRUE)
    )
    ,
    targets::tar_target(
      models_libpaths,
      command = system(
        "Rscript -e 'version; .libPaths(); sessionInfo()'", intern = TRUE
      )
    )
    ,
    targets::tar_target(
      models_torchinstall,
      command = system(
        "Rscript -e 'torch::torch_is_installed()'", intern = TRUE
      )
    )
    ,
    targets::tar_target(
      models_sbatchdev,
      command = system("sbatch dev.sh", intern = TRUE)
    )
    # targets::tar_target(
    #   models_cudaavailable,
    #   command = system(
    #     "Rscript -e 'torch::cuda_is_available()'", intern = TRUE
    #   )
    # )
    # ,
    # targets::tar_target(
    #   models_cudadevicecount,
    #   command = system(
    #     "Rscript -e 'torch::cuda_device_count()'", intern = TRUE
    #   )
    # )
    ############################################################################
    ############################################################################
  )