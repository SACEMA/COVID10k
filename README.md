# COVID10k

Estimating time to 1k and 10k COVID-19 cases

# Running Analysis

This project uses gnu `make` to define dependencies between inputs. The basic flow of the analysis is:

 0. get latest data (`updateWHO.R`)
 1. generate analysis parameters (by-country json files) from WHO SITREP data (`WHOprocess.R`)
 2. from analysis parameters, simulate branching process time series (`bpsamples.R`)
 3. consolidate those results (`bpconsolidate.R`)
 4. various summaries outputs
 5. using the branching process series + hospitalization parameters, generate hospital trajectories (by-country)
 6. consolidate hospitalization results
 7. various summary outputs

## Generate Analysis Parameters

There are shared parameter files (`inputs/SCENARIO.json`), and country specific (`*-par.json`) parameter files. The country specific ones are made from the latest data:

`make params`

## Generate HPC slurm reference

Generate the list of branching process jobs to do:

`make R2.txt R3.txt`

then use `R2-bps.slurm R3-bps.slurm` to run the jobs.

## Consolidate Results, Summarize & Visualize

