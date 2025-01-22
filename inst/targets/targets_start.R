################################################################################
############################         STAGE          ############################
cat("Running {beethoven}", Sys.getenv("BEETHOVEN"), "targets ...\n")

############################        SETTINGS        ############################
# Set paths for R, CUDA, and LD_LIBRARY_PATH, and check for CUDA availability.
beethoven:::sys_beethoven(
  # path = paste0(
  #   "/usr/local/cuda11.8/bin:", "/usr/local/nvidia/bin:",
  #   "/usr/local/sbin:", "/usr/local/bin:", "/usr/sbin:", "/usr/bin:",
  #   "/sbin:", "/bin"
  # ),
  # ld_library_path = paste0("/usr/local/cuda11.8/lib64"),
  # cuda_home = paste0("/usr/local/cuda11.8")
)

# Check .libPaths().
cat("Active library paths:\n")
.libPaths()

# Check PATH.
cat("Active PATH:\n")
Sys.getenv("PATH")

# Check LD_LIBRARY_PATH
cat("Active LD_LIBRARY_PATH:\n")
Sys.getenv("LD_LIBRARY_PATH")

############################      RUN PIPELINE      ############################
targets::tar_make(reporter = "verbose_positives")
