#!/bin/bash

#SBATCH --job-name=dev
#SBATCH --mail-user=mitchell.manwarer@nih.gov
#SBATCH --mail-type=END,FAIL
#SBATCH --partition=geo
#SBATCH --ntasks=1
#SBATCH --mem=100G
#SBATCH --cpus-per-task=25
#SBATCH --gres=gpu:4
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
  --bind /ddn/gs1/group/set/Projects/NRT-AP-Model/input:/input \
  --bind $PWD/_targets:/opt/_targets \
  container_covariates.sif \
  Rscript --no-init-file /mnt/inst/targets/targets_start.R


#############################        MODELS        #############################
# Set environmental variable to indicate model fitting targets.
export BEETHOVEN=models

# Fit models via container_models.sif
apptainer exec \
  --nv \
  --bind $PWD:/mnt \
  --bind $PWD/inst:/inst \
  --bind /ddn/gs1/group/set/Projects/NRT-AP-Model/input:/input \
  --bind $PWD/_targets:/opt/_targets \
  --bind /usr/local/cuda/bin/nvcc:/usr/local/cuda/bin/nvcc \
  container_models.sif \
  Rscript --no-init-file /mnt/inst/targets/targets_start.R
