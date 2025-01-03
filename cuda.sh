#############################        MODELS        #############################
# Set environmental variable to indicate model fitting targets and CUDA path.
export BEETHOVEN=models

# Fit models via container_models.sif
apptainer exec --nv \
  --bind /usr/local/cuda/bin/nvcc:/usr/local/cuda/bin/nvcc \
  container_models.sif \
  sh
