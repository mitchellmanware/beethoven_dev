target_models <-
  list(
    ############################################################################
    ############################################################################
    #########################             DEV             ######################
    targets::tar_target(
      model_torchtensor,
      command = torch::torch_load("/inst/extdata/model_torchtensor.pt"),
      format = "torch"
    )
    ,
    targets::tar_target(
      model_mlp,
      command = torch::torch_load("/inst/extdata/model_mlp.pt"),
      format = "torch"
    )
    ############################################################################
    ############################################################################
  )
