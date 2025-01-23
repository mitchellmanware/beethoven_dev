target_models <-
  list(
    targets::tar_target(
      dt_feat_calc_xyt_devsubset,
      command = data.table::data.table(
        qs::qread("inst/extdata/dt_feat_calc_xyt_devsubset.qs")
      ),
      description = "Imputed features + AQS sites (SUBSET FOR DEV)"
    )
    ,
    targets::tar_target(
      df_learner_type,
      command = beethoven::assign_learner_cv(
        learner = "mlp",
        cv_mode = c("spatiotemporal"),
        # cv_mode = c("spatial", "temporal", "spatiotemporal"),
        cv_rep = 2L,
        num_device = 1L
      ) %>%
        split(seq_len(nrow(.))),
      iteration = "list"
    )
    ,
    targets::tar_target(
      list_base_args_cv,
      command = list(
        # spatial = list(
        #   target_cols = c("lon", "lat"),
        #   cv_make_fun = beethoven::generate_cv_index_sp,
        #   v = 10L,
        #   method = "snake"
        # )
        # temporal = list(
        #   cv_fold = 10L,
        #   time_col = "time",
        #   window = 14L
        # )
        spatiotemporal = list(
          target_cols = c("lon", "lat", "time"),
          cv_make_fun = beethoven::generate_cv_index_spt,
          ngroup_init = 8L,
          cv_pairs = 10L,
          preprocessing = "normalize",
          pairing = "1"
        )
      )
    )
    ,
    targets::tar_target(
      list_base_params_candidates,
      command = list(
        mlp = expand.grid(
          hidden_units = c(1024, 512, 256, 128, 64),
          dropout = 1 / seq(5, 2, -1),
          activation = c("relu", "leaky_relu"),
          learn_rate = c(0.1, 0.05, 0.01, 0.005)
        )
      )
    )
    ,
    targets::tar_target(
      list_baselearner_params,
      command = list(
        learner = "mlp",
        dt_full = dt_feat_calc_xyt_devsubset[1:106144, ],
        r_subsample = 0.3,
        model = beethoven::switch_model(
          model_type = "mlp",
          device = "cuda"
        ),
        folds = 5L,
        cv_mode = "spatiotemporal",
        args_generate_cv = list_base_args_cv$spatiotemporal,
        tune_mode = "grid",
        tune_grid_in = list_base_params_candidates$mlp,
        tune_grid_size = 2L,
        tune_bayes_iter = 10L,
        yvar = "Arithmetic.Mean",
        xvar = seq(5, ncol(dt_feat_calc_xyt_devsubset)),
        nthreads = 2L,
        trim_resamples = FALSE,
        return_best = TRUE,
        metric = "rmse"
      )
    )
    ,
    targets::tar_target(
      dt_sample_rowidx,
      command = make_subdata_dev(
        list_baselearner_params$dt_full,
        p = list_baselearner_params$r_subsample,
        ngroup_init = 8L
      )
    )
    ,
    targets::tar_target(
      dt_sample,
      command = list_baselearner_params$dt_full[dt_sample_rowidx, ]
    )
    ,
    targets::tar_target(
      base_recipe,
      command = recipes::recipe(
        dt_sample[1, ]
      ) %>%
        recipes::update_role(list_baselearner_params$xvar) %>%
        recipes::update_role(
          list_baselearner_params$yvar, new_role = "outcome"
        )
    )
    ,
    targets::tar_target(
      args_generate_cv,
      command = c(
        list(data = dt_sample, cv_mode = list_baselearner_params$cv_mode),
        list_baselearner_params$args_generate_cv
      )
    )
    ,
    targets::tar_target(
      cv_mode_arg,
      command = match.arg(
        list_baselearner_params$cv_mode,
        c("spatial", "temporal", "spatiotemporal")
      )
    )
    ,
    targets::tar_target(
      target_fun,
      command = switch(
        cv_mode_arg,
        spatial = beethoven::generate_cv_index_sp,
        temporal = beethoven::generate_cv_index_ts,
        spatiotemporal = beethoven::generate_cv_index_spt
      )
    )
    ,
    # targets::tar_target(
    #   cv_index,
    #   command = generate_cv_index_sp_dev(
    #     data = args_generate_cv$data,
    #     target_cols = args_generate_cv$target_cols,
    #     v = list_baselearner_params$args_generate_cv$v,
    #     method = list_baselearner_params$args_generate_cv$method
    #   )
    # )
    # ,
    targets::tar_target(
      cv_index,
      command = beethoven::inject_match(target_fun, args_generate_cv)
    )
    ,
    targets::tar_target(
      base_vfold,
      command = beethoven::convert_cv_index_rset(
        cv_index, dt_sample, cv_mode = list_baselearner_params$cv_mode
      )
    )
    ,
    targets::tar_target(
      grid_row_idx,
      command = sample(
        nrow(list_baselearner_params$tune_grid_in),
        list_baselearner_params$tune_grid_size,
        replace = FALSE
      )
    )
    ,
    targets::tar_target(
      grid_params,
      command = list_baselearner_params$tune_grid_in[grid_row_idx, ]
    )
    ,
    targets::tar_target(
      base_wftune,
      command = beethoven::fit_base_tune(
        recipe = base_recipe,
        model = list_baselearner_params$model,
        resample = base_vfold,
        tune_mode = list_baselearner_params$tune_mode,
        grid = grid_params,
        iter_bayes = list_baselearner_params$tune_bayes_iter,
        trim_resamples = list_baselearner_params$trim_resamples,
        return_best = list_baselearner_params$return_best,
        data_full = list_baselearner_params$dt_full,
        metric = list_baselearner_params$metric
      ),
      resources = targets::tar_resources(
        crew = targets::tar_resources_crew(controller = "controller_gpu")
      )
    )
    ############################################################################
    ############################################################################
  )
