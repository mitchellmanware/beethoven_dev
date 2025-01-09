target_models <-
  list(
    ############################################################################
    ############################################################################
    #########################             DEV             ######################
    targets::tar_target(
      models_sbatchdev,
      command = {
        sbatch_out <- system("sbatch dev.sh", intern = TRUE)
        models_job <- sub("Submitted batch job ", "", sbatch_out)
        system(paste0("squeue --job ", models_job, " --wait"))
      }
    )
    ,
    targets::tar_target(
      models_torchtensor,
      command = {
        models_sbatchdev
        torch::torch_load("/inst/extdata/torch_tensor", device = "cuda")
      }
    )
    ############################################################################
    ############################################################################
  )