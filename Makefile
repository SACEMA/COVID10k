
# use a local make file to override the 3 variables that follow
-include local.make

INDIR ?= inputs
OUTDIR ?= outputs
REPDIR ?= reports

PARDIR := ${OUTDIR}/params
VALDIR := ${OUTDIR}/valpars
BPDIRBASE := ${OUTDIR}/bps
HOSPDIRBASE := ${OUTDIR}/hosp
FIGDIR := ${OUTDIR}/figs

${INDIR} ${OUTDIR} ${REPDIR} ${PARDIR} ${VALDIR} \
${BPDIRBASE}R2 ${BPDIRBASE}R3 ${BPDIRBASE}validate \
${HOSPDIRBASE}R2 ${HOSPDIRBASE}R3:
	mkdir -p $@

R = Rscript $^ $@

.PHONY: latest-WHO.rds

${INDIR}/latest-WHO.rds: updateWHO.R | ${INDIR}
	${R}

# this date sets the limit on reporting used to seed forecasts
DATELIM ?= 2020-03-25

PARREF := ${PARDIR}/SouthAfrica-par.json

params: ${PARREF}

R2.txt: slurm.R ${PARREF} | ${PARDIR}
	Rscript $< ${PARDIR} ${BPDIRBASE}R2 $@

R3.txt: slurm.R ${PARREF} | ${PARDIR}
	Rscript $< ${PARDIR} ${BPDIRBASE}R3 $@

${BPDIRBASE}R2/%-bpsamples.rds: bpsample.R ${PARDIR}/%-par.json ${INDIR}/R2.json | ${BPDIRBASE}R2
	${R}

${BPDIRBASE}R3/%-bpsamples.rds: bpsample.R ${PARDIR}/%-par.json ${INDIR}/R3.json | ${BPDIRBASE}R3
	${R}

${BPDIRBASE}%/bpmerge.rds: bpmerge.R $(wildcard ${BPDIRBASE}%/*-bpsamples.rds)
	Rscript $< ${PARDIR} $@

${BPDIRBASE}validate/bpmerge.rds: bpmerge.R $(wildcard ${BPDIRBASE}%/*-bpsamples.rds)
	Rscript $< ${VALDIR} $@

${OUTDIR}/%digest.rds: digest.R ${INDIR}/%.json ${BPDIRBASE}%/bpmerge.rds
	Rscript $< ${PARDIR} $@


testbpsample: $(patsubst %,${BPDIRBASE}R2/%-bpsamples.rds,SouthAfrica Zimbabwe Tunisia)

testbpmerge: ${BPDIRBASE}R2/bpmerge.rds

${HOSPDIRBASE}%-hosp.rds: hospestimate.R ${BPDIRBASE}%-bpsamples.rds ${INDIR}/hosp.json | ${HOSPDIRBASE}R2 ${HOSPDIRBASE}R3
	${R}

testhosp: ${HOSPDIRBASE}R2/SouthAfrica-hosp.rds

hosp%.txt: %.txt
	sed 's/bps$*/hosp$*/g' $^ > $@
	sed -i '' 's/bpsamples/hosp/g' $@


${VALDIR}/%-pars.json: validate.R | ${VALDIR}
	Rscript $^ $|

VALREF := ${VALDIR}/SouthAfrica-par.json

valpars: ${VALREF}

${BPDIRBASE}validate/%-bpsamples.rds: bpsample.R ${VALDIR}/%-pars.json ${INDIR}/validate.json | ${BPDIRBASE}validate
	${R}

ALLVALPARS := $(notdir $(wildcard ${VALDIR}/*-pars.json))
ALLVALSAMP := $(addprefix ${BPDIRBASE}validate/,$(subst pars.json,bpsamples.rds,${ALLVALPARS}))

val.txt: | valpars
	printf "%s\n" ${ALLVALSAMP} > $@

${OUTDIR}/%digest.rds: digest.R ${INDIR}/%.json ${BPDIRBASE}%/bpmerge.rds
	Rscript $^ $@

${OUTDIR}/%quantiles.rds: ${OUTDIR}/%digest.rds

${FIGDIR}/validation.png: figs/checkforecast.R ${OUTDIR}/validatequantiles.rds $(wildcard ${VALDIR}/*-pars.json) | ${VALDIR} ${FIGDIR}
	Rscript $(wordlist 1,2,$^) $|

forecastfig: ${OUTDIR}/validatedigest.rds ${FIGDIR}/validation.png

default: ${OUTDIR}/R3-merge.rds ${OUTDIR}/R2-merge.rds figs

dirs: ${INDIR} ${OUTDIR} ${FIGDIR}

# create the branching process samples
${OUTDIR}/bpsamples-%.rds: bpsamples.R ${INDIR}/params.json | ${OUTDIR}
	time ${R}

# use to create digests
${OUTDIR}/digested.rds: digest.R ${INDIR}/params.json $(wildcard ${OUTDIR}/bpsamples-*.rds) | ${OUTDIR}
	Rscript $(wordlist 1,2,$^) ${OUTDIR} $@

#$(patsubst %,${OUTDIR}/%.rds,distros quantiles incidence): ${OUTDIR}/digested.rds

summaries: $(patsubst %,${OUTDIR}/%.rds,digested distros quantiles incidence hospitalization)

# use the branching samples to estimate dates for 1k, 10k cases
estimates.png: estimate.R \
	$(addprefix ${OUTDIR}/,digested.rds distros.rds quantiles.rds)
	${R}

# use the branching samples to estimate dates for 1k, 10k cases
${FIGDIR}/estimate-all.jpg ${FIGDIR}/estimate-all.png: estimate-many.R ${OUTDIR}/R2quantiles.rds
	${R}

${FIGDIR}/estimate-all.csv: ${FIGDIR}/estimate-all.png

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

${OUTDIR}/R3-merge.rds: merge.R $(wildcard ${OUTDIR}/*-paramsR3.json) $(wildcard ${OUTDIR}/*R3-digested.rds)
	Rscript $< ${OUTDIR} -paramsR3.json R3-digested.rds $@



DD ?= 2020-05-01



deathsDate: deathsOn.R
	Rscript $^ ${OUTPUT} ${DD}

# use the branching samples to estimate dates for 1k, 10k cases
estimates-allR3.png: estimate-manyR3.R ${OUTDIR}
	${R}

${FIGDIR}/map_inset.png: mapping_cases.R Shapefiles/Detailed/detailed_2013.shp ${FIGDIR}/estimate-all.csv
	${R}

figs: ${FIGDIR}/estimate-all.png ${FIGDIR}/map_inset.png