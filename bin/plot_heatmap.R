#!/usr/bin/env Rscript
suppressMessages(library(pheatmap))

args <- commandArgs(trailingOnly = TRUE)
e    <- read.csv(args[1], row.names = 1, check.names = FALSE)
de   <- read.csv(args[2], row.names = 1)

top30 <- rownames(de)[order(de$adj.P.Val)][1:30]

png(args[3], width = 600, height = 900)
pheatmap(e[top30, ], scale = "row")
dev.off()
