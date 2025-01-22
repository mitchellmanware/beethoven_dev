#!/bin/bash

#############################        MODELS        #############################
# Set environmental variable to indicate model fitting targets.
export BEETHOVEN=models

# Run post-model targets via container_models.sif.
apptainer exec \
  --nv \
  --bind $PWD:/mnt \
  --bind $PWD/inst:/inst \
  --bind $PWD/input:/input \
  --bind $PWD/_targets:/opt/_targets \
  --bind /ddn/gs1/tools/cuda11.8:/usr/local/cuda \
  --bind /run/munge:/run/munge \
  --bind /ddn/gs1/tools/slurm/etc/slurm:/ddn/gs1/tools/slurm/etc/slurm \
  container/container_models_xgboost.sif \
  /usr/local/lib/R/bin/R --no-init-file
