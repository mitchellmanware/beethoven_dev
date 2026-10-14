################################################################################
# Run {glmnet} base learner models across all cross validation folds.

################################################################################
# Load libraries and source local functions.
library(beethoven)

################################################################################
# Import configured variables and inputs.
list_base_params_static <- qs2::qs_read(snakemake@input[[
  "list_base_params_static"
]])
list_base_cv_rset <- qs2::qs_read(snakemake@input[["list_base_cv_rset"]])

################################################################################
# Define {elnet} engine and device.
spec_elnet <- parsnip::linear_reg(
  mixture = parsnip::tune(),
  penalty = parsnip::tune()
) |>
  parsnip::set_engine("glmnet", device = "cpu") |>
  parsnip::set_mode("regression")

################################################################################
# Fit {elnet} base learner models.
mirai::daemons(length(list_base_cv_rset))
mirai_base_fit_elnet <- mirai::mirai_map(
  list_base_cv_rset,
  function(x) {
    beethoven::fit_base_learner(
      rset = x,
      model = spec_elnet,
      tune_grid_size = list_base_params_static$tune,
      yvar = list_base_params_static$yvar,
      xvar = list_base_params_static$xvar,
      drop_vars = list_base_params_static$dvar,
      normalize = list_base_params_static$normalize,
      metric = list_base_params_static$metric,
      full_data = list_base_params_static$data
    )
  },
  spec_elnet = spec_elnet,
  list_base_params_static = list_base_params_static
)
list_base_fit_elnet <- mirai::collect_mirai(
  mirai_base_fit_elnet,
  options = ".stop"
)
mirai::daemons(0)

################################################################################
qs2::qs_save(list_base_fit_elnet, snakemake@output[["list_base_fit_elnet"]])
