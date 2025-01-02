################################################################################
##############################      LIBPATHS       #############################
.libPaths(
  grep(
    paste0("biotools|", Sys.getenv("USER")), .libPaths(),
    value = TRUE,
    invert = TRUE
  )
)
cat("Active library paths:\n")
.libPaths()

if (Sys.getenv("BEETHOVEN") == "models") {
  cat("Torch status:\n")
  torch::torch_is_installed()
  cat("Cuda status:\n")
  torch::cuda_is_available()
}

############################      RUN PIPELINE      ############################
targets::tar_make(reporter = "verbose_positives")
