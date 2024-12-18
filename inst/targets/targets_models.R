target_models <-
  list(
    ############################################################################
    ############################################################################
    #########################             DEV             ######################
    targets::tar_target(
      models_sessionInfo,
      command = sessionInfo(),
      description = "Session information | models"
    )
    ,
    targets::tar_target(
      models_beethovenEnv,
      command = Sys.getenv("BEETHOVEN"),
      description = "Beethoven environment variable | models"
    )
    ,
    targets::tar_target(
      models_cudaEnv,
      command = Sys.getenv("CUDA_VISIBLE_DEVICES"),
      description = "CUDA environment variable | models"
    )
    ,
    targets::tar_target(
      dev_torchcuda,
      command = torch::cuda_is_available(),
      description = "Torch CUDA availability | models"
    )
    ,
    targets::tar_target(
      dev_torchtensor,
      command = torch::torch_tensor(matrix(1:10, ncol = 2), device = "cuda:1")
    )
    ############################################################################
    ############################################################################
  )