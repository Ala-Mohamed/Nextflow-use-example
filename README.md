# Nextflow version of the Mov10 case study (smaller dataset)

Same 4-step pipeline as before, but on the public **HBC "Mov10" RNA-seq
teaching dataset** instead of the GSE106305 hypoxia table, because that
dataset's exact GEO FTP path couldn't be verified or reached from the
previous sandbox. This one is confirmed working: it's hosted on GitHub
(`raw.githubusercontent.com`, always on the sandbox's network allowlist),
and I downloaded and parsed it directly in this session to confirm it.

**Honest note on "smaller":** the raw download is ~0.8 MB, slightly
*larger* than the original ~0.6 MB RPKM table, not smaller — I checked
several genuinely smaller public options first (GEO FTP, Bioconductor's
`pasilla`/`airway` packages, Zenodo-hosted teaching sets) and none of
those hosts were reachable from this sandbox. What I could shrink is the
*working* dataset: `prepare.R` now also keeps only the 2,000 most
variable genes, so `expression_log2.csv`, the DE table and all three plots
are much smaller and the whole run is faster than before, at the cost of
one extra filtering step.

**Why this dataset is a good stand-in:** it's real published data (MOV10
knockdown/overexpression vs. control), used in HBC's own DESeq2/limma
teaching materials, with the same shape as the original — a two-group
comparison. I verified it in this session: parsing the real file and
ranking genes by variance correctly surfaces `MOV10` itself as the single
highest-variance gene (control ≈1,400–1,700 counts vs. overexpression
≈32,000–71,000 counts), which is exactly the expected biology — a strong
sanity check that the volcano plot, heatmap and PCA will all show a real,
interpretable signal.

## What changed from the hypoxia version

| | Before (hypoxia) | Now (Mov10) |
|---|---|---|
| Source | GEO GSE106305 RPKM table (unverified URL) | `hbc/NGS_Data_Analysis_Course` on GitHub (verified, HTTP 200) |
| Format | gzipped RPKM | plain-text raw counts |
| Design | 2 vs 2 (hypoxia vs normoxia) | 3 vs 3 (control vs MOV10-overexpression), selected out of an 8-sample file |
| Column prefix / condition | `H_` / `N_`, "hypoxia" / "normoxia" | `T_` / `C_`, "treatment" / "control" |
| Gene filter | mito genes + expressed only | same, plus top 2,000 by variance (new — keeps the demo small) |
| `main.nf` param | `params.geo_url` | `params.counts_url` |

Only `prepare.R`, `diffexp.R` and `plot_pca.R` changed logic (the column
selection/renaming, and the `H_`/`N_` → `T_`/`C_` swap everywhere a
condition label is built). `plot_volcano.R` and `plot_heatmap.R` were
untouched — they only ever consumed the already-labeled expression and DE
tables, so the dataset swap is invisible to them.

## Project layout

```
nf-mov10-demo/
├── main.nf                  # the workflow (equivalent of Snakefile)
├── nextflow.config          # params + environment (equivalent of config.yaml)
├── conf/environment.yml     # conda env, same packages as before
└── bin/                     # one script per step (Nextflow auto-adds this to PATH)
    ├── prepare.R             # now: select 3v3 design, rename cols, filter, top-2000-by-variance
    ├── diffexp.R             # now: T_/C_ and "treatment"/"control"
    ├── plot_pca.R            # now: T_/C_ and "treatment"/"control"
    ├── plot_volcano.R        # unchanged
    └── plot_heatmap.R        # unchanged
```

## Step-by-step: how to run it

1. **Install Nextflow** (needs Java 11+):
   ```bash
   curl -s https://get.nextflow.io | bash
   ./nextflow -version
   ```

2. **The download URL is already set and verified** in `nextflow.config`
   (`params.counts_url`), pointing at the real Mov10 counts file. No
   editing needed unless you want a different source.

3. **Run with conda**, matching the poster's `--use-conda`:
   ```bash
   cd nf-mov10-demo
   ./nextflow run main.nf -profile conda --outdir results
   ```

4. **Override a parameter without editing the file:**
   ```bash
   ./nextflow run main.nf -profile conda --counts_url "https://...other_file..." --outdir results_v2
   ```

5. **Re-run only what changed.** Edit `bin/prepare.R` (e.g. change the
   top-N variable-gene cutoff) and re-run with:
   ```bash
   ./nextflow run main.nf -profile conda -resume
   ```
   DOWNLOAD is skipped (untouched), PREPARE re-runs, and everything
   downstream re-runs automatically because its input changed — no rule
   name needed, unlike Snakemake's `--forcerun prepare`.

6. **Inspect the outputs**, under `results/`:
   ```
   results/data/raw_counts.txt
   results/data/expression_log2.csv
   results/de/DE_results.csv
   results/de/summary.txt
   results/plots/PCA.png
   results/plots/volcano.png
   results/plots/heatmap_top30.png
   ```
   `MOV10` should show up as one of the strongest hits in `DE_results.csv`
   and near the top of `heatmap_top30.png` — a good one-line sanity check
   that the run worked.

7. **Get the same reports Nextflow gives you for free:**
   ```bash
   ./nextflow run main.nf -profile conda -with-report report.html -with-timeline timeline.html -with-dag dag.png
   ```

## Concept-by-concept comparison (unchanged from before)

| Concept | Snakemake (poster) | Nextflow (this repo) |
|---|---|---|
| Pipeline definition | `Snakefile`, rules | `main.nf`, processes |
| Config | `config.yaml` | `nextflow.config` → `params` |
| Wiring steps together | rule `input:`/`output:` filenames link rules; DAG inferred backward from the target | explicit channels: `expr = PREPARE(raw)` passes data forward; DAG inferred forward from source |
| Parallel independent steps | 3 separate rules (PCA, volcano, heatmap) run in parallel automatically | 3 separate processes (`PLOT_PCA`, `PLOT_VOLCANO`, `PLOT_HEATMAP`) run concurrently automatically — same behavior, no extra code needed |
| Environments | `environment.yaml` + `--use-conda` | `conf/environment.yml` + `-profile conda` (or swap in `-profile docker`) |
| One-command run | `snakemake --use-conda --cores 2` | `nextflow run main.nf -profile conda` |
| Resume after a fix | `--forcerun <rule>` (you name the rule) | `-resume` (automatic, hash-based, no rule name needed) |
| Cluster execution | `--cluster` + a submit template, or a profile | built-in executors: add `-profile slurm` (already stubbed in `nextflow.config`) |
| Run report / provenance | `--report` | `-with-report`, `-with-timeline`, `-with-trace` |
| Visualize the DAG | `snakemake --dag \| dot -Tpng` | `-with-dag dag.png` |

## What's different in practice

- **Direction of thinking.** In Snakemake you write a rule and say what file
  it needs; Snakemake works backward from your target file to figure out the
  order. In Nextflow you write a process and immediately pass its output into
  the next process as a channel; the order is explicit in `workflow { }`,
  reading top to bottom.
- **The three parallel plot steps cost nothing extra in either engine** —
  worth demonstrating side by side, since it's often assumed Nextflow needs
  special syntax for parallelism and Snakemake doesn't; both get it for free
  from the dependency graph.
- **`-resume` vs `--forcerun`** is the best "wow" moment for a live demo:
  change one line in `bin/prepare.R`, re-run both pipelines, and show that
  Nextflow figures out what to re-run on its own while Snakemake needs you to
  name the rule.

## Verified in this session

- `curl` to `raw.githubusercontent.com/hbc/NGS_Data_Analysis_Course/...` → **HTTP 200**, 799,832 bytes.
- The file parses as expected: 8 columns, 23,368 genes.
- The `C_`/`T_` column selection, mito filter, expression filter and
  top-2000-by-variance logic in `prepare.R` were replicated in Python
  against the real downloaded file and behave as intended (see note above
  on `MOV10` itself coming out as the top-variance gene).
- **Not verified:** actually running `nextflow run` end to end — this
  sandbox has no R/Nextflow installed, so `limma`'s model fit and the
  plotting scripts haven't been executed. The R logic is otherwise
  unchanged from the version you already reviewed for the hypoxia dataset.
