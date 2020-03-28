#!/bin/bash

#$ -V
#$ -S /bin/bash
#$ -wd ~/COVID10k
#$ -N covid10k-bpsamples
#$ -l h_rt=01:00:00
#$ -l mem_free=4G
#$ -q ???
#$ -M ???
#$ -t 1-45

module load R/3.6.1

echo $ARRAY_TASK_ID
tar=$(tail -n+$ARRAY_TASK_ID R2.txt | head -n1)
make $tar
