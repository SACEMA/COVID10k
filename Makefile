
default: $(patsubst %,bpsamples-%.rds,$(shell seq -s " " -w 0 9))

R = Rscript $^ $@

# create the branching process samples
bpsamples-%.rds: bpsamples.R params.json
	time ${R}

# use to create digests
digested.rds: digest.R $(wildcard bpsamples-*.rds)
	${R}

distros.rds quantiles.rds: digested.rds 

# use the branching samples to estimate...TBD
estimates.png: estimate.R digested.rds distros.rds quantiles.rds
	${R}