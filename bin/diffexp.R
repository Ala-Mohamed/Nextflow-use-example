#!/usr/bin/env Rscript
suppressMessages(library(limma))

args        <- commandArgs(trailingOnly = TRUE)
exprfile    <- args[1]
outfile     <- args[2]
summaryfile <- args[3]

e <- read.csv(exprfile, row.names = 1, check.names = FALSE)
condition <- ifelse(grepl("^T_", colnames(e)), "treatment", "control")

design <- model.matrix(~condition)
fit    <- eBayes(lmFit(e, design), trend = TRUE)
res    <- topTable(fit, coef = "conditiontreatment", n = Inf)

write.csv(res, outfile)

sig <- subset(res, adj.P.Val < 0.05 & abs(logFC) > 1)
writeLines(
  sprintf("%d significant genes (adj.p<0.05, |log2FC|>1)", nrow(sig)),
  summaryfile
)
