#!/bin/bash

#SBATCH --job-name=dev_initiate
#SBATCH --mail-user=mitchell.manware@nih.gov
#SBATCH --mail-type=END,FAIL
#SBATCH --partition=geo
#SBATCH --ntasks=1
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:1
#SBATCH --output=slurm/initiate_%j.out
#SBATCH --error=slurm/initiate_%j.err

# Open Bash shell or R session via `container_models.sif`
# for interactive development.

apptainer exec \
  --nv \
  --bind $PWD:/mnt \
  --bind /run/munge:/run/munge \
  --bind /ddn/gs1/tools/slurm/etc/slurm:/ddn/gs1/tools/slurm/etc/slurm \
  container_models.sif \
  sbatch dev.sh
  