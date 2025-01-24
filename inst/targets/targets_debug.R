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
        learner = "xgb",
        cv_mode = c("temporal"),
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
        temporal = list(
          cv_fold = 10L,
          time_col = "time",
          window = 14L
        )
      )
    )
    ,
    targets::tar_target(
      list_base_params_candidates,
      command = list(
        xgb = expand.grid(
          mtry = floor(c(0.025, seq(0.05, 0.2, 0.05)) * 2000L),
          trees = seq(1000, 3000, 1000),
          learn_rate = c(0.1, 0.05, 0.01, 0.005)
        )
      )
    )
    ,
    targets::tar_target(
      list_baselearner_params,
      command = list(
        learner = "xgb",
        dt_full = dt_feat_calc_xyt_devsubset[1:106144, ],
        r_subsample = 0.3,
        # model = beethoven::switch_model(
        #   model_type = "xgb",
        #   device = "cuda"
        # ),
        model = parsnip::boost_tree(
          mtry = parsnip::tune(),
          trees = parsnip::tune(),
          learn_rate = parsnip::tune()
        ) %>%
          parsnip::set_engine(
            "xgboost",
            device = "cuda",
            params = list(tree_method = "gpu_hist")
          ) %>%
          parsnip::set_mode("regression"),
        folds = 5L,
        cv_mode = "temporal",
        args_generate_cv = list_base_args_cv$temporal,
        tune_mode = "grid",
        tune_grid_in = list_base_params_candidates$xgb,
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
      dt_sample_rowidx,
      command = beethoven:::make_subdata(
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
      list_basetune_params,
      command = list(
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
      )
    )
    ,
    targets::tar_target(
      base_spec,
      command = parsnip::boost_tree(
        mode = "regression",
        trees = parsnip::tune(),
        mtry = parsnip::tune(),
        learn_rate = parsnip::tune()
      ) %>%
        parsnip::set_engine(
          "xgboost",
          device = "cuda",
          params = list(tree_method = "gpu_hist")
        )
    )
    ,
    targets::tar_target(
      base_flow,
      command = workflows::workflow() %>%
        workflows::add_recipe(base_recipe) %>%
        workflows::add_model(base_spec)
    )
    ,
    targets::tar_target(
      base_params,
      command = {
        mtry_param <- dials::mtry(range(
          floor(c(0.025, seq(0.05, 0.2, 0.05)) * 2000L)
        ))
        trees_param <- dials::trees(range(
          seq(1000, 3000, 1000)
        ))
        learn_rate_param <- dials::learn_rate(range(
          c(0.1, 0.05, 0.01, 0.005)
        ))
        dials::parameters(mtry_param, trees_param, learn_rate_param)
      }
    )
    ,
    targets::tar_target(
      wf_config,
      command = tune::control_grid(
        verbose = TRUE,
        save_pred = FALSE,
        save_workflow = TRUE
      )
    )
    ,
    targets::tar_target(
      base_wftune,
      command = tune::tune_grid(
        base_flow,
        resamples = list_basetune_params$resample,
        param_info = base_params,
        metrics = yardstick::metric_set(
          yardstick::rmse,
          yardstick::mape,
          yardstick::rsq,
          yardstick::mae
        ),
        grid = grid_params,
        control = wf_config
      ),
      resources = targets::tar_resources(
        crew = targets::tar_resources_crew(controller = "controller_gpu")
      )
    )
    # ,
    # targets::tar_target(
    #   base_wfparam,
    #   command = tune::select_best(
    #     base_wftune,
    #     metric = list_basetune_params$metric,
    #   )
    # )
    # ,
    # targets::tar_target(
    #   base_wfresult,
    #   tune::finalize_workflow(base_wf, base_wfparam)
    # )
    # ,
    # targets::tar_target(
    #   base_wf_fit_best,
    #   command = parsnip::fit(base_wfresult, list_baselearner_params$dt_full)
    # )
    # ,
    # targets::tar_target(
    #   base_wf_pred_best,
    #   command = stats::predict(base_wf_fit_best, new_data = data_full)
    # )
    # ,
    # targets::tar_target(
    #   base_wflist,
    #   command = list(
    #     base_prediction = base_wf_pred_best,
    #     base_parameter = base_wfparam,
    #     best_performance = base_wftune
    #   )
    # )
    ############################################################################
    ############################################################################
  )
