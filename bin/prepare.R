#!/usr/bin/env Rscript
# Select a clean 2-group design, drop mito genes, filter low expression,
# keep the most variable genes (keeps the demo small and fast), log2-transform.
#
# Source file has 8 columns: Mov10_kd_2, Mov10_kd_3, Mov10_oe_1..3, Irrel_kd_1..3
# We use Irrel_kd_* as the control group and Mov10_oe_* as the treatment
# group (a balanced 3-vs-3 design) and drop the knockdown columns.
args    <- commandArgs(trailingOnly = TRUE)
infile  <- args[1]
outfile <- args[2]

m <- read.delim(infile, row.names = 1, check.names = FALSE)

keep_cols <- c("Irrel_kd_1", "Irrel_kd_2", "Irrel_kd_3",
               "Mov10_oe_1", "Mov10_oe_2", "Mov10_oe_3")
m <- m[, keep_cols]
colnames(m) <- c("C_1", "C_2", "C_3", "T_1", "T_2", "T_3")

m <- m[!grepl("^MT-", rownames(m)), ]   # drop mitochondrial genes
m <- m[rowMeans(m) >= 1, ]              # keep expressed genes only

# Keep the 2000 most variable genes so the downstream steps (and the whole
# demo) stay small -- this is the size-reduction lever, since the raw
# download itself (~0.8 MB) is already in the same ballpark as before.
v <- apply(m, 1, var)
top <- order(v, decreasing = TRUE)[seq_len(min(2000, length(v)))]
m <- m[top, ]

write.csv(log2(m + 1), outfile)
