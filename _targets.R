################################################################################
##############################      BEETHOVEN      #############################
##### Main file controlling the settings, options, and sourcing of targets
##### for the beethoven analysis pipeline.

#############################      CONTROLLER      #############################
default_controller <- crew::crew_controller_local(
  name = "default_controller",
  workers = 25,
  seconds_idle = 30
)
gpu_controller <- crew.cluster::crew_controller_slurm(
  name = "gpu_controller",
  workers = 4,
  seconds_idle = 30,
  options_cluster = crew.cluster::crew_options_slurm(
    verbose = TRUE,
    script_lines = paste0(
      "#!/bin/bash\n\n",
      "#SBATCH --job-name=dev_gpu\n",
      "#SBATCH --partition=geo\n",
      "#SBATCH --ntasks=1\n",
      "#SBATCH --mem=16G\n",
      "#SBATCH --cpus-per-task=4\n",
      "#SBATCH --gres=gpu:1\n",
      "#SBATCH --output=slurm/gpu_%j.out\n",
      "#SBATCH --error=slurm/gpu_%j.err\n\n",
      "apptainer exec \\\n",
      "  --nv \\\n",
      "  --bind $PWD:/mnt \\\n",
      "  --bind $PWD/inst:/inst \\\n",
      "  --bind /ddn/gs1/group/set/Projects/NRT-AP-Model/input:/input \\\n",
      "  --bind $PWD/_targets:/opt/_targets \\\n",
      "  --bind /run/munge:/run/munge \\\n",
      "  --bind /ddn/gs1/tools/slurm/etc/slurm:/etc/slurm \\\n",
      "  container_models.sif \\\n",
      "  /usr/local/bin/R --no-init-file --no-save"
    )
  ),
  reset_globals = FALSE,
  reset_packages = FALSE,
  reset_options = FALSE
)

##############################        STORE       ##############################
targets::tar_config_set(store = "/opt/_targets")

##############################       OPTIONS      ##############################
targets::tar_option_set(
  packages = c(
    "amadeus", "targets", "tarchetypes", "dplyr", "tidyverse",
    "data.table", "sf", "crew", "crew.cluster", "lubridate", "qs2",
    "torch"
  ),
  repository = "local",
  error = "continue",
  memory = "transient",
  format = "qs",
  storage = "worker",
  deployment = "worker",
  garbage_collection = TRUE,
  seed = 202401L,
  controller = crew::crew_controller_group(
    default_controller#, gpu_controller
  ),
  retrieval = "worker"
)

###########################      SOURCE TARGETS      ###########################
targets::tar_source("inst/targets/targets_critical.R")
targets::tar_source("inst/targets/targets_initiate.R")
targets::tar_source("inst/targets/targets_covariates.R")
targets::tar_source("inst/targets/targets_models.R")

###########################      SYSTEM SETTINGS      ##########################
if (Sys.getenv("BEETHOVEN") == "covariates") {
  target_models <- NULL
} else {
  # options(
  #   clustermq.scheduler = "slurm",
  #   clustermq.template = "/mnt/gpu_controller.tmpl"
  # )
}

##############################      PIPELINE      ##############################
list(
  target_critical,
  target_initiate,
  target_covariates,
  target_models
)
