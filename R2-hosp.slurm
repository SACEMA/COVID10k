#!/bin/bash

#SBATCH --job-name covid10k-hosp-R2
#SBATCH -t 10:00:00
#SBATCH -array=1-45

module load R/3.6.3
tar=$(tail -n+$SLURM_ARRAY_TASK_ID hospR2.txt | head -n1)
make $tar
