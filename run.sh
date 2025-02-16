#!/bin/bash

#SBATCH --job-name=dev
#SBATCH --mail-user=mitchell.manware@nih.gov
#SBATCH --mail-type=END,FAIL
#SBATCH --partition=geo
#SBATCH --ntasks=1
#SBATCH --mem=100G
#SBATCH --cpus-per-task=25
#SBATCH --error=slurm/dev_%j.err
#SBATCH --output=slurm/dev_%j.out

############################      CERTIFICATES      ############################
# Export CURL_CA_BUNDLE and SSL_CERT_FILE environmental variables to vertify
# servers' SSL certificates during download.
export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

###############################      GPU SETUP     #############################
# Ensure all allocated GPUs are visible
export CUDA_VISIBLE_DEVICES=$(echo $(seq 0 $((SLURM_GPUS_ON_NODE-1))) | tr ' ' ',')

#############################      COVARIATES      #############################
# Set environmental variable to indicate download and covariate
# calculation targets.
export BEETHOVEN=covariates

# Download and calculate covariates via container_covariates.sif
apptainer exec \
  --bind $PWD:/mnt \
  --bind $PWD/inst:/inst \
  --bind $PWD/input:/input \
  --bind $PWD/_targets:/opt/_targets \
  container_covariates.sif \
  /usr/local/lib/R/bin/Rscript --no-init-file /mnt/inst/targets/targets_start.R

#############################        MODELS        #############################
# Set environmental variable to indicate model fitting targets.
export BEETHOVEN=models

# Fit base learner models via container_models.sif.
apptainer exec \
  --nv \
  --bind $PWD:/mnt \
  --bind $PWD/inst:/inst \
  --bind $PWD/input:/input \
  --bind $PWD/_targets:/opt/_targets \
  --bind /run/munge:/run/munge \
  --bind /ddn/gs1/tools/slurm/etc/slurm:/ddn/gs1/tools/slurm/etc/slurm \
  container_models.sif \
  /usr/local/lib/R/bin/Rscript --no-init-file /mnt/inst/targets/targets_start.R
