
default: figs

INDIR := .
OUTDIR := ~/Dropbox/COVIDSA/outputs

${INDIR} ${OUTDIR}:
	mkdir -p $@

dirs: ${INDIR} ${OUTDIR}

R = Rscript $^ $@

# create the branching process samples
${OUTDIR}/bpsamples-%.rds: bpsamples.R ${INDIR}/params.json | ${OUTDIR}
	time ${R}

# use to create digests
${OUTDIR}/digested.rds: digest.R ${INDIR}/params.json $(wildcard ${OUTDIR}/bpsamples-*.rds) | ${OUTDIR}
	Rscript $(wordlist 1,2,$^) ${OUTDIR} $@

$(patsubst %,${OUTDIR}/%.rds,distros quantiles incidence): ${OUTDIR}/digested.rds

summaries: $(patsubst %,${OUTDIR}/%.rds,digested distros quantiles incidence)

# use the branching samples to estimate dates for 1k, 10k cases
${OUTDIR}/estimates.png: estimate.R $(addprefix ${OUTDIR}/,digested.rds distros.rds quantiles.rds)
	${R}

.PHONY: showday

# use the branching samples to estimate cases for 1 April
# or a different day with `make showday DAY=YYYY-MM-DD`
showday: april1.R ${OUTDIR}/digested.rds
	Rscript $^ ${DAY}

# use the branching samples to estimate...TBD
${OUTDIR}/hospitalziation.rds: hospitalization.R ${OUTDIR}/digested.rds ${INDIR}/hosp.json
	${R}

figs: ${OUTDIR}/estimates.png