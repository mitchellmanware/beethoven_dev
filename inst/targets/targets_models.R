target_models <-
  list(
    ############################################################################
    ############################################################################
    #########################             DEV             ######################
    targets::tar_target(
      models_torchtensor,
      command = torch::cuda_device_count(),
      # resources = targets::tar_resources(
      #   crew = targets::tar_resources_crew(controller = "gpu_controller")
      # ),
      description = "Torch tensor test | models"
    )
    ############################################################################
    ############################################################################
  )