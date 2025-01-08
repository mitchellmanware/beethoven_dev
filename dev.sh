#!/bin/bash

#SBATCH --job-name=dev_gpu
#SBATCH --mail-user=mitchell.manware@nih.gov
#SBATCH --mail-type=END,FAIL
#SBATCH --partition=geo
#SBATCH --ntasks=1
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:1
#SBATCH --output=slurm/gpu_%j.out
#SBATCH --error=slurm/gpu_%j.err

apptainer exec \
  --nv \
  --bind $PWD:/mnt \
  --bind /run/munge:/run/munge \
  --bind /ddn/gs1/tools/slurm/etc/slurm:/etc/slurm \
  container_models.sif \
  Rscript --no-init-file /mnt/dev.R
