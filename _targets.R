library(targets)
library(tarchetypes)
library(geotargets)
library(qs)
library(tidyverse)
library(data.table)
library(sf)
library(crew)
library(lubridate)

################################################################################
##############################      BEETHOVEN      #############################
##### Main file controlling the settings, options, and sourcing of targets
##### for the beethoven analysis pipeline.

#############################      CONTROLLER      #############################
beethoven_controller <- crew::crew_controller_local(
  name = "beethoven_controller",
  workers = 25,
  seconds_idle = 30
)

##############################        STORE       ##############################
targets::tar_config_set(store = "/opt/_targets")

##############################       OPTIONS      ##############################
targets::tar_option_set(
  packages = c(
    "amadeus", "targets", "tarchetypes", "geotargets","dplyr", "tidyverse",
    "data.table", "sf", "crew", "crew.cluster","lubridate", "qs"
  ),
  repository = "local",
  error = "continue",
  memory = "transient",
  format = "qs",
  storage = "worker",
  deployment = "worker",
  garbage_collection = TRUE,
  seed = 202401L,
  controller = crew::crew_controller_group(beethoven_controller)
)

###########################      SOURCE TARGETS      ###########################
targets::tar_source("inst/targets/targets_run.R")

##############################      PIPELINE      ##############################
list(
  target_run
)
