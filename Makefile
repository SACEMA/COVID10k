
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

summaries: $(patsubst %,${OUTDIR}/%.rds,digested distros quantiles incidence hospitalization)

# use the branching samples to estimate dates for 1k, 10k cases
estimates.png: estimate.R \
	$(addprefix ${OUTDIR}/,digested.rds distros.rds quantiles.rds)
	${R}

# use the branching samples to estimate dates for 1k, 10k cases
estimates-all.png: estimate-many.R ${OUTDIR} ${OUTDIR}/quantiles.rds
	${R}


.PHONY: showday

# use the branching samples to estimate cases for 1 April
# or a different day with `make showday DAY=YYYY-MM-DD`
showday: april1.R ${OUTDIR}/digested.rds
	Rscript $^ ${DAY}

# use the branching samples to estimate ward vs icu incidence
${OUTDIR}/hospitalization.rds: hospitalization.R ${INDIR}/hosp.json ${OUTDIR}/incidence.rds
	${R}

${OUTDIR}/hospdigest.csv: hospdigest.R ${OUTDIR}/hospitalization.rds ${OUTDIR}/incidence.rds
	${R}

.PRECIOUS: ${OUTDIR}/%-params.json

${OUTDIR}/%-params.json: WHOAFRO.R template-params.json
	${R}

${OUTDIR}/%-bpsamples.rds: bpsamples.R ${OUTDIR}/%-params.json
	${R}



# use to create digests
${OUTDIR}/%-digested.rds: digest-one.R ${OUTDIR}/%-params.json ${OUTDIR}/%-bpsamples.rds | ${OUTDIR}
	Rscript $^ $@

PERCENT := %

$(patsubst %,${OUTDIR}/${PERCENT}-%.rds,distros quantiles incidence): ${OUTDIR}/%-digested.rds

ALLAFROPARS := $(wildcard ${OUTDIR}/*-params.json)

allAFROpars: ${ALLAFROPARS}

allAFRO: $(ALLAFROPARS:params.json=bpsamples.rds)

allAFROdig: $(ALLAFROPARS:params.json=digested.rds)

ALLAFROPARSR3 := $(wildcard ${OUTDIR}/*-paramsR3.json)

allAFROparsR3: ${ALLAFROPARSR3}

allAFROR3: $(ALLAFROPARSR3:paramsR3.json=bpsamplesR3.rds)

allAFROdigR3: $(ALLAFROPARSR3:-paramsR3.json=R3-digested.rds)

${OUTDIR}/%-paramsR3.json: WHOAFRO.R template-paramsR3.json
	${R}

${OUTDIR}/%-bpsamplesR3.rds: bpsamples.R ${OUTDIR}/%-paramsR3.json
	${R}

${OUTDIR}/%R3-digested.rds: digest-one.R ${OUTDIR}/%-paramsR3.json ${OUTDIR}/%-bpsamplesR3.rds | ${OUTDIR}
	Rscript $^ $@

# use the branching samples to estimate dates for 1k, 10k cases
estimates-allR3.png: estimate-manyR3.R ${OUTDIR}
	${R}


figs: estimates.png estimates-all.png