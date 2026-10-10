#!/usr/bin/env nextflow
/*
 * Nextflow re-implementation of the same 4-step case study, now on a
 * smaller, GitHub-hosted dataset (the HBC "Mov10" RNA-seq teaching set,
 * control vs MOV10-overexpression, 3 vs 3 replicates):
 *   1. DOWNLOAD   - fetch the raw counts table from GitHub
 *   2. PREPARE    - drop mito genes, filter low expression, log-transform
 *   3. DIFFEXP    - limma: treatment vs control
 *   4. PLOT_*     - PCA, volcano, heatmap (three independent processes,
 *                   scheduled in parallel automatically by Nextflow)
 */
nextflow.enable.dsl = 2

params.counts_url = 'https://raw.githubusercontent.com/hbc/NGS_Data_Analysis_Course/master/sessionIII/data/Mov10_full_counts.txt'
params.outdir  = 'results'

process DOWNLOAD {
    tag "GitHub fetch"
    publishDir "${params.outdir}/data", mode: 'copy'

    output:
    path 'raw_counts.txt'

    script:
    """
    curl -fsSL -o raw_counts.txt ${params.counts_url}
    """
}

process PREPARE {
    tag "filter + log2"
    publishDir "${params.outdir}/data", mode: 'copy'

    input:
    path raw_table

    output:
    path 'expression_log2.csv'

    script:
    """
    prepare.R ${raw_table} expression_log2.csv
    """
}

process DIFFEXP {
    tag "limma"
    publishDir "${params.outdir}/de", mode: 'copy'

    input:
    path expr

    output:
    path 'DE_results.csv', emit: de_table
    path 'summary.txt',    emit: summary

    script:
    """
    diffexp.R ${expr} DE_results.csv summary.txt
    """
}

process PLOT_PCA {
    tag "PCA"
    publishDir "${params.outdir}/plots", mode: 'copy'

    input:
    path expr

    output:
    path 'PCA.png'

    script:
    """
    plot_pca.R ${expr} PCA.png
    """
}

process PLOT_VOLCANO {
    tag "volcano"
    publishDir "${params.outdir}/plots", mode: 'copy'

    input:
    path de_table

    output:
    path 'volcano.png'

    script:
    """
    plot_volcano.R ${de_table} volcano.png
    """
}

process PLOT_HEATMAP {
    tag "heatmap top30"
    publishDir "${params.outdir}/plots", mode: 'copy'

    input:
    path expr
    path de_table

    output:
    path 'heatmap_top30.png'

    script:
    """
    plot_heatmap.R ${expr} ${de_table} heatmap_top30.png
    """
}

workflow {
    raw  = DOWNLOAD()
    expr = PREPARE(raw)

    DIFFEXP(expr)

    // These three consume `expr` / the DE table only, so Nextflow runs
    // them concurrently once their inputs are ready -- the direct
    // equivalent of the poster's "three independent rules in parallel".
    PLOT_PCA(expr)
    PLOT_VOLCANO(DIFFEXP.out.de_table)
    PLOT_HEATMAP(expr, DIFFEXP.out.de_table)
}
