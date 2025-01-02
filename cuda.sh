#############################        MODELS        #############################
# Set environmental variable to indicate model fitting targets and CUDA path.
export BEETHOVEN=models
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Fit models via container_models.sif
apptainer exec --nv \
  --bind /usr/local/cuda-12.3/bin:/usr/local/cuda/bin \
  --bind /usr/local/cuda-12.3/lib64:/usr/local/cuda/lib64 \
  container_models.sif \
  R --no-init-file
