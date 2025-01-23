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
scriptlines_apptainer <- "apptainer"
scriptlines_basedir <- "$PWD"
scriptlines_container <- "container_models_xgboost.sif"
scriptlines_gpu <- glue::glue(
  "#SBATCH --job-name=devgpu \
  #SBATCH --partition=geo \
  #SBATCH --gres=gpu:1 \
  #SBATCH --output=slurm/devgpu_%j.out \
  #SBATCH --error=slurm/devgpu_%j.err \
  {scriptlines_apptainer} exec --nv --bind {scriptlines_basedir}:/mnt ",
  "--bind {scriptlines_basedir}/inst:/inst ",
  "--bind {scriptlines_basedir}/input:/input ",
  "--bind {scriptlines_basedir}/_targets:/opt/_targets ",
  "{scriptlines_container} \\"
)
controller_gpu <- crew.cluster::crew_controller_slurm(
  name = "controller_gpu",
  workers = 4,
  seconds_idle = 30,
  options_cluster = crew.cluster::crew_options_slurm(
    verbose = TRUE,
    script_lines = scriptlines_gpu
  )
)

##############################        STORE       ##############################
targets::tar_config_set(store = "/opt/_targets")

##############################       OPTIONS      ##############################
targets::tar_option_set(
  packages = c(
    "amadeus", "targets", "tarchetypes", "dplyr", "tidyverse",
    "data.table", "sf", "crew", "crew.cluster", "lubridate", "qs2",
    "torch", "bonsai", "xgboost"
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
    default_controller,
    controller_gpu
  ),
  resources = targets::tar_resources(
    crew = targets::tar_resources_crew(controller = "default_controller")
  ),
  retrieval = "worker"
)

###########################      SOURCE TARGETS      ###########################
targets::tar_source("inst/targets/targets_critical.R")
# targets::tar_source("inst/targets/targets_initiate.R")
# targets::tar_source("inst/targets/targets_covariates.R")
targets::tar_source("inst/targets/targets_debug.R")

source("/mnt/function.R")

###########################      SYSTEM SETTINGS      ##########################
if (Sys.getenv("BEETHOVEN") == "covariates") {
  target_models <- NULL
}

##############################      PIPELINE      ##############################
list(
  target_critical,
  # target_initiate,
  # target_covariates,
  target_models
)
