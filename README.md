# rnaseq-enrichment-flow

`taf-rnaseq-enrichment-flow` runs a compact, offline RNA-seq enrichment
interpretation step from DE gene lists, ranked genes, a GMT gene-set file, and
an optional explicit background. It writes ORA and preranked GSEA tables,
publication-oriented enrichment plots, summaries, logs, commands, versions,
methods, and a manifest under one explicit output directory.

Package identity:

- name: `rnaseq-enrichment-flow`
- command: `taf-rnaseq-enrichment-flow`
- kind: `flow`
- version: `0.1.0-r3`
- license: Apache-2.0

## RNA-seq Flow Position

This app is a reusable subflow in the TAFFISH bulk RNA-seq flow family. It can
be run directly from compatible gene lists, ranked genes, GMT files, and
background genes, and it is also designed to be called by the
`rnaseq-standard-flow` umbrella. The umbrella should reuse this flow's offline
enrichment contract rather than duplicate its ORA/GSEA logic.

## Scope

r3 supports:

- ORA from a significant gene list
- preranked GSEA from a ranked gene table
- combined ORA + GSEA in one run
- standard GMT gene-set input
- explicit background gene universe for ORA
- readable final dotplots with wrapped long term labels
- optimized classic/original-style dotplots with wider labels as
  `dotplot.original.pdf/png`
- ORA adjusted-p-value barplots
- GSEA normalized-enrichment-score plots
- GSEA running enrichment score curves
- `plot_summary.tsv` for plot discovery by report flows
- fixed output tree under `<outdir>/`
- input snapshots under `<outdir>/00_inputs/`
- provenance files: `commands.sh`, `versions.tsv`, `methods.txt`,
  `flow_summary.tsv`, and `run.manifest.json`

r3 deliberately does not download MSigDB, KEGG, GO, Reactome, Enrichr, or
g:Profiler data. It does not perform identifier conversion, organism detection,
gene-set propagation, differential expression, or statistical interpretation
beyond running the requested offline enrichment route.

## Dependencies

The flow depends on one version-pinned TAFFISH tool app:

| Dependency | Version | Role |
| --- | --- | --- |
| `taf-enrichment-r` | `0.1.0-r1` | offline GMT-based ORA/GSEA runtime |

The script also uses ordinary shell utilities (`sh`, `awk`, `sed`, `sort`,
`date`, `mkdir`, `cp`, `rm`, `grep`, and related POSIX tools) for validation,
bookkeeping, and provenance. The enrichment calculations and r3 plot rendering
both run through the explicit `taf-enrichment-r` dependency; the flow does not
call host-installed R, fgsea, clusterProfiler, or plotting packages.

## Usage

Run directly after `rnaseq-de-flow`:

```sh
taf-rnaseq-enrichment-flow \
  --gene-list de-out/03_results/gene_lists/significant_genes.tsv \
  --ranked-genes de-out/03_results/gene_lists/ranked_genes.tsv \
  --gene-sets gene_sets.gmt \
  --background background.tsv \
  --outdir enrichment-out
```

Run ORA only:

```sh
taf-rnaseq-enrichment-flow \
  --gene-list de-out/03_results/gene_lists/up_genes.tsv \
  --gene-sets gene_sets.gmt \
  --background background.tsv \
  --outdir enrichment-up-out
```

Run GSEA only:

```sh
taf-rnaseq-enrichment-flow \
  --ranked-genes de-out/03_results/gene_lists/ranked_genes.tsv \
  --gene-sets gene_sets.gmt \
  --outdir enrichment-gsea-out
```

## Parameters

Required input/output:

- `--gene-sets PATH`: standard GMT file.
- `--outdir PATH`, `-o PATH`: output directory. The flow refuses to run if it
  already exists unless `--force` is used.
- At least one of `--gene-list` or `--ranked-genes` is required.

Analysis inputs:

- `--gene-list PATH`: TSV for ORA. The default ID column is `gene_id`; a
  one-column file with or without a `gene_id` header is also accepted.
- `--ranked-genes PATH`: TSV for GSEA with gene IDs and numeric scores.
- `--background PATH`: optional ORA universe. For RNA-seq, this should usually
  be the set of genes tested or detectable in the DE analysis.

Common controls:

- `--id-column NAME`: gene ID column in list/background/ranked tables.
  Default: `gene_id`.
- `--score-column NAME`: score column in ranked genes. Default: `score`.
- `--min-size N`: minimum gene-set size after filtering. Default: `2`.
- `--max-size N`: maximum gene-set size after filtering. Default: `500`.
- `--pvalue-cutoff X`: raw p-value cutoff for retained ORA/GSEA rows.
  Default: `1`.
- `--padj-method NAME`: p-value adjustment method for ORA. Default: `BH`.
- `--top-n N`: terms shown in the dotplot. Default: `20`. Long descriptions
  are wrapped in the final r3 plots so yeast/GO terms remain inspectable.
- `--seed N`: random seed for fgsea. Default: `1`.
- `--force`: replace the standard rnaseq-enrichment-flow output files inside an
  existing output directory.

## Input Tables

Gene list:

```text
gene_id
YAL001C
YBR160W
YDR050C
```

Ranked genes:

```text
gene_id	score
YAL001C	4.2
YBR160W	2.1
YDR050C	-1.7
```

Background:

```text
gene_id
YAL001C
YBR160W
YDR050C
YLR044C
```

GMT:

```text
GO:0000001	mitochondrion inheritance [biological_process]	YAL001C	YBR160W
GO:0000002	mitochondrial genome maintenance [biological_process]	YDR050C
```

Rules:

- Gene IDs are exact strings.
- The flow does not map gene symbols, Ensembl IDs, RefSeq IDs, or systematic IDs.
- If `--background` is provided, ORA query genes must be inside it.
- Ranked gene scores must be numeric.
- Duplicate gene IDs in list, ranked, or background inputs are rejected.
- GMT set IDs must be unique.

## Outputs

All flow-created outputs are written under `<outdir>/`:

```text
<outdir>/
  00_inputs/
    gene_list.tsv
    ranked_genes.tsv
    gene_sets.gmt
    background.tsv
  01_logs/
    flow.log
    steps/
      01_validate_inputs.log
      02_enrichment.log
      03_render_dotplot.log
      04_render_extra_plots.log
  02_intermediate/
    gene_list.normalized.tsv
    ranked_genes.normalized.tsv
    background.normalized.tsv
    gene_sets.stats.tsv
    enrichment-r/
    plot/
  03_results/
    enrichment/
      ora_results.tsv
      gsea_results.tsv
      enrichment_summary.tsv
      dotplot.pdf
      dotplot.png
      dotplot.original.pdf
      dotplot.original.png
      ora_barplot.pdf
      ora_barplot.png
      gsea_nes_plot.pdf
      gsea_nes_plot.png
      gsea_enrichment_curves.pdf
      gsea_enrichment_curves.png
      dotplot_source.tsv
      plot_summary.tsv
  04_reports/
    commands.sh
    versions.tsv
    enrichment_versions.tsv
    methods.txt
    flow_summary.tsv
  run.manifest.json
```

Important files:

- `03_results/enrichment/ora_results.tsv`: hypergeometric ORA table.
- `03_results/enrichment/gsea_results.tsv`: fgsea preranked GSEA table.
- `03_results/enrichment/dotplot.pdf` and `.png`: readable r3 plot of top ORA
  terms when ORA has rows, otherwise top GSEA terms, otherwise an empty-result
  plot. Long terms are wrapped and the canvas height scales with `--top-n`.
- `03_results/enrichment/dotplot.original.pdf` and `.png`: optimized
  classic/original-style re-rendering with wider labels. The raw
  dependency-generated plot remains in `02_intermediate/enrichment-r/`.
- `03_results/enrichment/ora_barplot.pdf` and `.png`: top ORA terms as
  adjusted-p-value bars.
- `03_results/enrichment/gsea_nes_plot.pdf` and `.png`: top GSEA terms by
  normalized enrichment score.
- `03_results/enrichment/gsea_enrichment_curves.pdf` and `.png`: running
  enrichment score curves for the top GSEA terms.
- `03_results/enrichment/dotplot_source.tsv`: plot renderer, source table,
  number of plotted terms, wrapping width, extra plot counts, and canvas size.
- `03_results/enrichment/plot_summary.tsv`: machine-readable plot inventory.
- `04_reports/flow_summary.tsv`: flow-level counts and parameters.
- `04_reports/commands.sh`: exact dependency command used by the flow.
- `run.manifest.json`: input, parameter, dependency, count, and output manifest.

## Connection From DE Flow

`rnaseq-de-flow` writes the two main inputs expected here:

```text
de-out/03_results/gene_lists/significant_genes.tsv
de-out/03_results/gene_lists/ranked_genes.tsv
```

`significant_genes.tsv` is used for ORA. `ranked_genes.tsv` is used for GSEA.
The user still must provide a compatible GMT and background. For RNA-seq, the
background should generally come from the tested gene universe, not from all
genes in an organism.

## Boundaries

This flow is an interpretation aid, not a replacement for biological review.
Enrichment results depend heavily on the gene universe, ID system, gene-set
source, redundancy, and thresholds. The flow records these choices but does not
decide whether a term is biologically causal or experimentally validated.

Smoke uses a tiny artificial GMT to verify the execution path. Formal RNA-seq
testing uses the central yeast SNF2 count data plus the SGD GO-derived
GMT/background bundle when available. The central data tree can be prepared
with `repos/apps/bio/flows/rna-seq/test-data/yeast/rnaseq-yeast-get-data`;
downstream formal tests read it via `TAFFISH_RNASEQ_TESTDATA` or the default
local `test-data/yeast/data/03_results` path.
