################################################################################
############################         STAGE          ############################
cat("Running", Sys.getenv("BEETHOVEN"), "targets...\n")

############################        LIBPATHS        ############################
# Exclude user-specific and host paths from available library paths.
.libPaths(
  grep(
    paste0("biotools|", Sys.getenv("USER")), .libPaths(),
    value = TRUE,
    invert = TRUE
  )
)
# Check .libPaths().
cat("Active library paths:\n")
.libPaths()

############################      ENVIRONMENT       ############################
# Set environmental variables relative to container paths.
Sys.setenv(
  "PATH" = paste0(
    "/usr/local/cuda/bin:", "/usr/local/nvidia/bin:", "/usr/local/cuda/bin:",
    "/usr/local/sbin:", "/usr/local/bin:", "/usr/sbin:", "/usr/bin:",
    "/sbin:", "/bin"
  ),
  "LD_LIBRARY_PATH" = "/usr/local/cuda/lib64",
  "CUDA_HOME" = "/usr/local/cuda"
)

# Check PATH.
cat("Active PATH:\n")
Sys.getenv("PATH")

# Check LD_LIBRARY_PATH
cat("Active LD_LIBRARY_PATH:\n")
Sys.getenv("LD_LIBRARY_PATH")

############################         TORCH          ############################
# Check for torch and cuda installations.
if (Sys.getenv("BEETHOVEN") == "models") {
  # Check torch::torch_tensor().
  cat("torch::cuda_is_available():\n")
  torch::cuda_is_available()
}

############################      RUN PIPELINE      ############################
targets::tar_make(reporter = "verbose_positives")
