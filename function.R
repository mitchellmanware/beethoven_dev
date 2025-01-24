fit_base_tune_dev <-
  function(
    recipe,
    model,
    resample,
    tune_mode = c("bayes", "grid"),
    grid = NULL,
    iter_bayes = 10L,
    trim_resamples = TRUE,
    return_best = TRUE,
    data_full = NULL,
    metric = "rmse"
  ) {
    stopifnot("data_full must be entered." = !is.null(data_full))
    tune_mode <- match.arg(tune_mode)
    base_wf <-
      workflows::workflow() %>%
      workflows::add_recipe(recipe) %>%
      workflows::add_model(model)

    if (tune_mode == "grid") {
      wf_config <-
        tune::control_grid(
          verbose = TRUE,
          save_pred = FALSE,
          save_workflow = TRUE
        )
      base_wftune <-
        base_wf %>%
        tune::tune_grid(
          resamples = resample,
          grid = grid,
          metrics =
          yardstick::metric_set(
            yardstick::rmse,
            yardstick::mape,
            yardstick::rsq,
            yardstick::mae
          ),
          control = wf_config
        )
    } else {
      wf_config <-
        tune::control_bayes(
          verbose = TRUE,
          save_pred = FALSE,
          save_workflow = TRUE
        )
      base_wftune <-
        base_wf %>%
        tune::tune_bayes(
          resamples = resample,
          iter = iter_bayes,
          metrics =
          yardstick::metric_set(
            yardstick::rmse,
            yardstick::mae,
            yardstick::mape,
            yardstick::rsq
          ),
          control = wf_config
        )
    }
    # DEVELOPMENT CHANGE
    # mm-0904 Drop base_wftune from return when trim_resamples = TRUE
    # due to large data size. 1 iter > 25Gb
    # if (trim_resamples) {
    #   base_wftune$splits <- NA
    # }
    if (return_best) {
      # Select the best hyperparameters
      metric <- match.arg(metric, c("rmse", "rsq", "mae"))
      base_wfparam <-
        tune::select_best(
          base_wftune,
          metric = metric
        )
      # finalize workflow with the best tuned hyperparameters
      base_wfresult <- tune::finalize_workflow(base_wf, base_wfparam)

      # DEVELOPMENT CHANGE
      # mm-0904 unlist multi-layered hidden units if mlp model
      if (model$engine == "brulee" && is.list(grid$hidden_units)) {
        base_wfresult$fit$actions$model$spec$args$hidden_units <-
          unlist(
            rlang::quo_get_expr(
              base_wfresult$fit$actions$model$spec$args$hidden_units
            )
          )
      }

      # Best-fit model
      base_wf_fit_best <- parsnip::fit(base_wfresult, data = data_full)
      # Prediction with the best model
      base_wf_pred_best <-
        stats::predict(base_wf_fit_best, new_data = data_full)

      base_wflist <-
        list(
          base_prediction = base_wf_pred_best,
          base_parameter = base_wfparam,
          best_performance = base_wftune
        )
    }
    # DEVELOPMENT CHANGE
    # mm-0904 see above
    if (trim_resamples) {
      base_wflist <- base_wflist[-3]
    }
    return(base_wflist)
  }
