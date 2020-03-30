#!/bin/bash

#SBATCH --job-name covid10k-bpsamples-val
#SBATCH -t 60
#SBATCH -array=1-39

module load R/3.6.3
tar=$(tail -n+$SLURM_ARRAY_TASK_ID val.txt | head -n1)
make $tar
