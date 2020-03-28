
.args <- if (interactive()) c("~/Dropbox/COVIDSA/outputs/params", "outputs/bpsR2", "R2.txt") else commandArgs(trailingOnly = TRUE)

rt <- "-par.json"

tars <- sprintf(
  "%s/%s",
  .args[2],
  gsub(rt, "-bpsamples.rds", list.files(.args[1], rt), fixed = TRUE)
)

write.table(tars, tail(.args, 1), quote = F, col.names = F, row.names = F)
