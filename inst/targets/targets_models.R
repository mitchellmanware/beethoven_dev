target_models <-
  list(
    ############################################################################
    ############################################################################
    #########################             DEV             ######################
    targets::tar_target(
      dt_feat_calc_xyt_devsubset,
      command = data.table::data.table(
        qs::qread("inst/extdata/dt_feat_calc_xyt_devsubset.qs")
      ),
      description = "Imputed features + AQS sites (SUBSET FOR DEV)"
    )
    ,
    targets::tar_target(
      name = df_learner_type,
      command = beethoven::assign_learner_cv(
        learner = "xgb",
        cv_mode = c("spatial"),
        # cv_mode = c("spatial", "temporal", "spatiotemporal"),
        cv_rep = 2L,
        num_device = 1L
      ) %>%
        split(seq_len(nrow(.))),
      iteration = "list"
    )
    ,
    targets::tar_target(
      name = list_base_args_cv,
      command = list(
        spatial = list(
          target_cols = c("lon", "lat"),
          cv_make_fun = beethoven::generate_cv_index_sp,
          v = 10L,
          method = "snake"
        )
        # temporal = list(
        #   cv_fold = 10L,
        #   time_col = "time",
        #   window = 14L
        # )
        # spatiotemporal = list(
        #   target_cols = c("lon", "lat", "time"),
        #   cv_make_fun = beethoven::generate_cv_index_spt,
        #   ngroup_init = 8L,
        #   cv_pairs = 10L,
        #   preprocessing = "normalize",
        #   pairing = "1"
        # )
      )
    )
    ,
    targets::tar_target(
      name = list_base_params_candidates,
      command = list(
        # mlp = expand.grid(
        #   hidden_units = c(1024, 512, 256, 128, 64),
        #   dropout = 1 / seq(5, 2, -1),
        #   activation = c("relu", "leaky_relu"),
        #   learn_rate = c(0.1, 0.05, 0.01, 0.005)
        # )
        xgb = expand.grid(
          mtry = floor(c(0.025, seq(0.05, 0.2, 0.05)) * 2000L),
          trees = seq(1000, 3000, 1000),
          learn_rate = c(0.1, 0.05, 0.01, 0.005)
        )
        # lgb = expand.grid(
        #   mtry = floor(c(0.025, seq(0.05, 0.2, 0.05)) * 2000L),
        #   trees = seq(1000, 3000, 1000),
        #   learn_rate = c(0.1, 0.05, 0.01, 0.005)
        # )
        # elnet = expand.grid(
        #   mixture = seq(0, 1, length.out = 21),
        #   penalty = 10 ^ seq(-3, 5, 1)
        # )
      )
    )
    ,
    targets::tar_target(
      name = workflow_learner_base_best,
      command = beethoven::fit_base_learner(
        learner = df_learner_type$learner,
        dt_full = dt_feat_calc_xyt_devsubset,
        r_subsample = 0.3,
        model = beethoven::switch_model(
          model_type = df_learner_type$learner,
          device = "cuda"
        ),
        ##### specify `NULL` folds to trigger manual `cv_mode` #####
        folds = NULL,
        cv_mode = df_learner_type$cv_mode,
        args_generate_cv = list_base_args_cv[[df_learner_type$cv_mode]],
        tune_mode = "grid",
        tune_grid_in = list_base_params_candidates[[df_learner_type$learner]],
        tune_grid_size = 2L,
        yvar = "Arithmetic.Mean",
        xvar = seq(5, ncol(dt_feat_calc_xyt_devsubset)),
        nthreads = 2L,
        trim_resamples = FALSE,
        return_best = TRUE,
        metric = "rmse"
      ),
      pattern = map(df_learner_type),
      iteration = "list",
      resources = targets::tar_resources(
        crew = targets::tar_resources_crew(controller = "controller_gpu")
      )
    )
    ############################################################################
    ############################################################################
  )
