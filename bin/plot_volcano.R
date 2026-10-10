#!/usr/bin/env Rscript
suppressMessages(library(ggplot2))

args <- commandArgs(trailingOnly = TRUE)
de   <- read.csv(args[1], row.names = 1)

de$sig <- ifelse(de$adj.P.Val < 0.05 & de$logFC >  1, "Up",
           ifelse(de$adj.P.Val < 0.05 & de$logFC < -1, "Down", "NS"))

p <- ggplot(de, aes(logFC, -log10(adj.P.Val), color = sig)) +
  geom_point(alpha = 0.6) +
  scale_color_manual(values = c(Up = "firebrick", Down = "steelblue", NS = "grey80")) +
  theme_minimal()

ggsave(args[2], p, width = 5, height = 4)
