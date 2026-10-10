#!/usr/bin/env Rscript
suppressMessages(library(ggplot2))

args <- commandArgs(trailingOnly = TRUE)
e    <- read.csv(args[1], row.names = 1, check.names = FALSE)

top500 <- head(order(apply(e, 1, var), decreasing = TRUE), 500)
pr     <- prcomp(t(e[top500, ]))
ve     <- round(100 * summary(pr)$importance[2, 1:2])

df <- data.frame(
  PC1 = pr$x[, 1], PC2 = pr$x[, 2],
  sample = colnames(e),
  condition = ifelse(grepl("^T_", colnames(e)), "treatment", "control")
)

p <- ggplot(df, aes(PC1, PC2, color = condition, label = sample)) +
  geom_point(size = 4) +
  geom_text(vjust = -1, show.legend = FALSE) +
  xlab(paste0("PC1 (", ve[1], "%)")) +
  ylab(paste0("PC2 (", ve[2], "%)")) +
  theme_minimal()

ggsave(args[2], p, width = 5, height = 4)
