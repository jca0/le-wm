#!/bin/bash
#SBATCH --job-name=lewm_pusht
#SBATCH --partition=mit_normal_gpu
#SBATCH --output=logs/train_pusht_%j.out
#SBATCH --error=logs/train_pusht_%j.err
#SBATCH --time=6:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --gres=gpu:l40s:1

# Create logs directory if it doesn't exist
mkdir -p logs

# Print some info
echo "Job started at: $(date)"
echo "Running on node: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"

# Activate virtual environment
source /home/jingcao/workspace/le-wm/.venv/bin/activate

# Set environment variables
export STABLEWM_HOME=/scratch/jingcao/.stable_worldmodel

# Create datasets directory on this node's scratch
mkdir -p /scratch/jingcao/.stable_worldmodel/datasets
echo "Created directory: /scratch/jingcao/.stable_worldmodel/datasets"

# Download dataset if not already present
if [ ! -f /scratch/jingcao/.stable_worldmodel/datasets/pusht_expert_train.h5 ]; then
    echo "Downloading dataset from Hugging Face..."
    cd /scratch/jingcao/.stable_worldmodel/datasets
    hf download quentinll/lewm-pusht --repo-type=dataset --local-dir .
    echo "Dataset downloaded, checking contents..."
    ls -lh /scratch/jingcao/.stable_worldmodel/datasets/

    # Decompress if compressed
    if [ -f pusht_expert_train.h5.zst ]; then
        echo "Decompressing dataset..."
        zstd -d pusht_expert_train.h5.zst
        echo "Decompression complete"
        ls -lh /scratch/jingcao/.stable_worldmodel/datasets/pusht_expert_train.h5
    fi
else
    echo "Dataset already exists on this node"
fi

# Change to the working directory
cd /home/jingcao/workspace/le-wm

# Run training with fixed run name for checkpoint resumption
# This allows resuming from the same checkpoint directory
python train.py data=pusht subdir=pusht_run_001

echo "Job finished at: $(date)"
