rnaseq-enrichment-flow 0.2.0-r1

Purpose:
  Run offline RNA-seq enrichment interpretation from DE gene lists, ranked
  genes, a GMT gene-set file, and an optional explicit background. The flow
  writes ORA and preranked GSEA tables, publication-oriented enrichment plots,
  summaries, logs, commands, versions, methods, and a manifest under one
  explicit output directory.

Usage:
  taf-rnaseq-enrichment-flow \
    --gene-list de-out/03_results/gene_lists/significant_genes.tsv \
    --ranked-genes de-out/03_results/gene_lists/ranked_genes.tsv \
    --gene-sets gene_sets.gmt \
    --background background.tsv \
    --outdir enrichment-out \
    [options]

Required inputs:
  --gene-sets PATH
      Standard GMT file. Gene IDs are treated as exact strings.

  At least one of:
    --gene-list PATH
        TSV for ORA. Uses --id-column, or a one-column gene list.

    --ranked-genes PATH
        TSV for preranked GSEA with gene IDs and numeric scores.

Recommended input:
  --background PATH
      ORA universe TSV. For RNA-seq this should usually be the tested or
      detectable gene universe from the DE analysis.

Required output:
  --outdir PATH, -o PATH
      Output directory. The flow refuses to run if PATH already exists unless
      --force is used.

Common options:
  --id-column NAME
      Gene ID column in list/background/ranked tables. Default: gene_id.

  --score-column NAME
      Score column in ranked genes. Default: score.

  --min-size N
      Minimum gene-set size after filtering. Default: 2.

  --max-size N
      Maximum gene-set size after filtering. Default: 500.

  --pvalue-cutoff X
      Raw p-value cutoff for retained ORA/GSEA rows. Default: 1.

  --padj-method NAME
      P-value adjustment method for ORA. Default: BH.

  --top-n N
      Number of terms shown in the main enrichment plots. Default: 20. Long
      term labels are wrapped in the final r3 plot set. dotplot.original.pdf/png
      is an optimized classic/original-style view; the raw dependency plot is
      retained under 02_intermediate/enrichment-r/.

  --seed N
      Random seed for fgsea. Default: 1.

  --force
      Replace the standard rnaseq-enrichment-flow output files inside an
      existing output directory.

Key outputs:
  <outdir>/03_results/enrichment/ora_results.tsv
      Over-representation analysis table.

  <outdir>/03_results/enrichment/gsea_results.tsv
      Preranked GSEA table.

  <outdir>/03_results/enrichment/enrichment_summary.tsv
      Compact enrichment summary.

  <outdir>/03_results/enrichment/dotplot.pdf and .png
      Primary readable ORA or GSEA dotplot.

  <outdir>/03_results/enrichment/dotplot.original.pdf and .png
      Optimized classic/original-style dotplot.

  <outdir>/03_results/enrichment/ora_barplot.* and gsea_*plot.*
      Additional ORA and GSEA plots in PDF/PNG.

  <outdir>/04_reports/
      commands.sh, versions.tsv, enrichment_versions.tsv, methods.txt,
      flow_summary.tsv, and provenance.

Upstream/downstream:
  Upstream:
    rnaseq-de-flow provides significant_genes.tsv and ranked_genes.tsv.
    User supplies compatible GMT and optional background.

  Downstream:
    rnaseq-report-flow can collect the enrichment output directory.

Advanced step passthrough:
  Optional expert slots for native tool parameters. They default to empty
  and are not needed for normal use.

  @enrichment-both-background-step: ... @: ORA+GSEA with background genes.
  @enrichment-both-step: ... @: ORA+GSEA without background genes.
  @enrichment-ora-background-step: ... @: ORA with background genes.
  @enrichment-ora-step: ... @: ORA without background genes.
  @enrichment-gsea-step: ... @: GSEA-only enrichment.
  @render-dotplot-step: ... @: Rscript invocation for the main dotplot.
  @render-extra-plots-step: ... @: Rscript invocation for extra plots.

Input examples:
  gene_list.tsv:
    gene_id
    YAL001C
    YBR160W

  ranked_genes.tsv:
    gene_id<TAB>score
    YAL001C<TAB>4.2
    YBR160W<TAB>-1.7

  gene_sets.gmt:
    set_id<TAB>description<TAB>gene1<TAB>gene2<TAB>gene3

Boundaries:
  r3 is offline and GMT-driven. It does not generate DE results, download
  gene sets, infer organisms, convert gene IDs, run online KEGG/MSigDB/Enrichr
  queries, or decide biological interpretation. Gene set source, ID system,
  background universe, and thresholds remain user responsibilities.

Detailed documentation:
  https://github.com/taffish/rnaseq-enrichment-flow

Wrapper options:
  -h, --help       Show this help.
  -v, --version    Show package and command version.
  --compile        Print generated shell code instead of running it.
