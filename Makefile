
R := Rscript $^ $@

# create the branching process samples
bpsamples.rds: bpsamples.R params.json
	${R}

# use the branching samples to estimate...TBD
estimates.png: estimate.R bpsamples.rds
	${R}