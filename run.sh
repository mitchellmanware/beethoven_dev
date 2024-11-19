#!/bin/bash

#SBATCH --job-name=dev
#SBATCH --mail-user=mitchell.manwarer@nih.gov
#SBATCH --mail-type=END,FAIL
#SBATCH --partition=geo
#SBATCH --ntasks=1
#SBATCH --mem=200G
#SBATCH --cpus-per-task=100
#SBATCH --error=slurm/dev_%j.err
#SBATCH --output=slurm/dev_%j.out

# Set the CURL_CA_BUNDLE and SSL_CERT_FILE to vertify the server's SSL
# certificate during download.
export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# run pipeline in the container
apptainer exec \
  --bind $PWD:/mnt \
  --bind $PWD/inst:/inst \
  --bind $PWD/input:/input \
  --bind $PWD/_targets:/opt/_targets \
  beethoven_dl_calc.sif \
  Rscript --no-init-file /mnt/inst/targets/targets_start.R
