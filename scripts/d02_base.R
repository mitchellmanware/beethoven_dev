################################################################################
# Run {xgboost} base learner models across all cross validation folds.

################################################################################
# Load libraries and source local functions.
library(beethoven)

################################################################################
# Import configured variables and inputs.
# list_base_params_static <- qs2::qs_read(snakemake@input[["list_base_params_static"]])
# list_base_cv_index <- qs2::qs_read(snakemake@input[["list_base_cv_index"]])
list_base_params_static <- qs2::qs_read("../output/list_base_params_static.qs")
list_base_cv_rset <- qs2::qs_read("../output/list_base_cv_rset.qs")

################################################################################
# Define {elnet} engine and device.
spec_elnet <- parsnip::linear_reg(
  mixture = parsnip::tune(),
  penalty = parsnip::tune()
) |>
  parsnip::set_engine("brulee", device = "cpu") |>
  parsnip::set_mode("regression")

################################################################################
# Fit {elnet} base learner models.
m <- beethoven::fit_base_learner(
  rset = list_base_cv_rset[[1]],
  model = spec_elnet,
  tune_grid_size = 2,
  yvar = list_base_params_static$yvar,
  xvar = list_base_params_static$xvar,
  drop_vars = list_base_params_static$dvar,
  normalize = list_base_params_static$normalize,
  metric = list_base_params_static$metric,
  full_data = list_base_params_static$data
)
m
