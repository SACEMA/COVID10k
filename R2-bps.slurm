#!/bin/bash

#SBATCH --job-name covid10k-bpsamples-R2
#SBATCH -t 60
#SBATCH -array=1-45

module load R/3.6.3
tar=$(tail -n+$SLURM_ARRAY_TASK_ID R2.txt | head -n1)
make $tar
