target_models <-
  list(
    ############################################################################
    ############################################################################
    #########################             DEV             ######################
    targets::tar_target(
      model_mlp,
      command = torch::torch_load("/inst/extdata/model_mlp.pt"),
      format = "torch"
    )
    ,
    targets::tar_target(
      dt_feat_calc_imputed,
      command = {
        dt_full <- qs::qread("inst/extdata/dt_feat_calc_imputed.qs")
        dt_full[grep("2018|2019", dt_full$time), c(1:5, 2065:2165)]
      },
      description = "Import features | models"
    )
    ,
    targets::tar_target(
      models_mlp,
      command = {
        # Manual dependency
        models_cudadevicecount

        # Set model.
        mlp_model <- beethoven::switch_model("mlp", device = "cuda")

        # Set grid.
        mlp_grid <- expand.grid(
          hidden_units = list(c(64, 64), c(64, 128), c(128, 128)),
          dropout = c(0.2, 0.3333333),
          activation = c("relu"),
          learn_rate = c(0.1, 0.05, 0.01)
        )

        # Fit mlp with {brulee} (spatiotemporal fold cross validation and
        # grid tuning).
        beethoven::fit_base_learner(
          learner = "mlp",
          dt_full = dt_feat_calc_imputed,
          r_subsample = 0.3,
          model = mlp_model,
          folds = 5L, # 5 fold cross validation for exploration
          cv_mode = "spatiotemporal",
          tune_mode = "grid",
          tune_grid_in = mlp_grid,
          tune_grid_size = 2, # 2 grid tuning for exploration
          learn_rate = 0.1,
          yvar = "Arithmetic.Mean",
          xvar = seq(5, ncol(dt_feat_calc_imputed)),
          nthreads = 1,
          trim_resamples = FALSE,
          return_best = TRUE
        )
      },
      resources = targets::tar_resources(
        crew = targets::tar_resources_crew(controller = "gpu_controller")
      ),
      description = "{brulee} mlp test | models"
    )
    ############################################################################
    ############################################################################
  )
