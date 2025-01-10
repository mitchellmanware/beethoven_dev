############################        SETTINGS        ############################
cat("Running non-target {beethoven}", Sys.getenv("BEETHOVEN"), "...\n")

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

############################           DEV          ############################
models_torchtensor <- "/inst/extdata/models_torchtensor.pt"
if (!file.exists(models_torchtensor)) {
  torch::torch_save(
    torch::torch_tensor(matrix(1:10, ncol = 2), device = "cuda"),
    path = models_torchtensor
  )
}
