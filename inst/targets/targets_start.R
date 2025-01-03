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

############################         SETENV         ############################
# Set environmental variables relative to container paths.
Sys.setenv(
  LD_LIBRARY_PATH = paste0(
    "/usr/local/cuda/lib64:",
    "/.singularity.d/libs:$LD_LIBRARY_PATH"
  ),
  PATH = "/usr/local/cuda/bin",
  CUDA_HOME = "/usr/local/cuda"
)

# Check $PATH.
cat("Active $PATH:\n")
Sys.getenv("PATH")

# Check $LD_LIBRARY_PATH.
cat("Active $LD_LIBRARY_PATH:\n")
Sys.getenv("LD_LIBRARY_PATH")

# Check $CUDA_HOME.
cat("Active $CUDA_HOME:\n")
Sys.getenv("CUDA_HOME")

# Check $CUDA_VISIBLE_DEVICES.
cat("Active $CUDA_VISIBLE_DEVICES:\n")
Sys.getenv("CUDA_VISIBLE_DEVICES")

############################         TORCH          ############################
# Check for torch and cuda installations.
if (Sys.getenv("BEETHOVEN") == "models") {
  cat("torch_is_installed():\n")
  torch::torch_is_installed()
  cat("cuda_is_available():\n")
  torch::cuda_is_available()
}

############################      RUN PIPELINE      ############################
targets::tar_make(reporter = "verbose_positives")
