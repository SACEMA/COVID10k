#!/bin/bash

#SBATCH --job-name covid10k-bpsamples-R3
#SBATCH -t 60
#SBATCH -array=1-45

module load R/3.6.3
tar=$(tail -n+$SLURM ARRAY_TASK_ID R3.txt | head -n1)
make $tar
