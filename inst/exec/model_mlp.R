############################        SETTINGS        ############################
cat("Running non-target {beethoven}", Sys.getenv("BEETHOVEN"), "...\n")
cat("Model: {brulee} multi-layer perceptron\n")

# Set paths for R, CUDA, and LD_LIBRARY_PATH, and check for CUDA availability.
beethoven:::sys_beethoven()

# Check .libPaths().
cat("Active library paths:\n")
.libPaths()

# Check PATH.
cat("Active PATH:\n")
Sys.getenv("PATH")

# Check LD_LIBRARY_PATH
cat("Active LD_LIBRARY_PATH:\n")
Sys.getenv("LD_LIBRARY_PATH")

# Check torch::cuda_is_available().
cat("torch::cuda_is_available():\n")
torch::cuda_is_available()

############################       BRULEE MLP       ############################
# Read full covariate data.
dt_feat_calc_imputed <- qs::qread("/inst/extdata/dt_feat_calc_imputed.qs")

# Subset to 2018 and 100 covariates.
dt_feat_calc_imputed_2018 <- dt_feat_calc_imputed[
  grep("2018", dt_feat_calc_imputed$time), c(1:4, 2065:2165)
]

# Set model.
mlp_model <- beethoven::switch_model("mlp", device = "cuda")

# Set grid.
mlp_grid <- expand.grid(
  hidden_units = list(16, c(8, 8), c(8, 16, 32)),
  dropout = c(0.2, 0.3333333),
  activation = c("relu"),
  learn_rate = c(0.1)
)

# Fit mlp with {brulee} (spatiotemporal fold cross validation and grid tuning).
mlp <- beethoven::fit_base_learner(
  learner = "mlp",
  dt_full = dt_feat_calc_imputed_2018,
  r_subsample = 0.3,
  model = mlp_model,
  folds = 5L,
  cv_mode = "spatiotemporal",
  tune_mode = "grid",
  tune_grid_in = mlp_grid,
  tune_grid_size = 2,
  learn_rate = 0.1,
  yvar = "Arithmetic.Mean",
  xvar = seq(5, ncol(dt_feat_calc_imputed_2018)),
  nthreads = 1,
  trim_resamples = FALSE,
  return_best = TRUE
)

############################          SAVE          ############################
model_mlp <- "/inst/extdata/model_mlp.pt"
if (!file.exists(model_mlp)) {
  torch::torch_save(
    mlp,
    path = model_mlp
  )
}
