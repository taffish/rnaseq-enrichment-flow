rnaseq-enrichment-flow 0.1.0-r1

Purpose:
  Run offline RNA-seq enrichment interpretation from DE gene lists, ranked
  genes, a GMT gene-set file, and an optional explicit background. The flow
  writes ORA and preranked GSEA tables, a dotplot, summaries, logs, commands,
  versions, methods, and a manifest under one explicit output directory.

Flow family role:
  This is a TAFFISH RNA-seq subflow. It can be run directly from compatible DE
  gene-list inputs, and its enrichment outputs are intended for future
  rnaseq-standard-flow orchestration.

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
      Number of terms shown in the dotplot. Default: 20.

  --seed N
      Random seed for fgsea. Default: 1.

  --force
      Replace the standard rnaseq-enrichment-flow output files inside an
      existing output directory.

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

Output tree:
  <outdir>/00_inputs/gene_list.tsv
  <outdir>/00_inputs/ranked_genes.tsv
  <outdir>/00_inputs/gene_sets.gmt
  <outdir>/00_inputs/background.tsv
  <outdir>/01_logs/flow.log
  <outdir>/01_logs/steps/01_validate_inputs.log
  <outdir>/01_logs/steps/02_enrichment.log
  <outdir>/02_intermediate/
  <outdir>/03_results/enrichment/ora_results.tsv
  <outdir>/03_results/enrichment/gsea_results.tsv
  <outdir>/03_results/enrichment/enrichment_summary.tsv
  <outdir>/03_results/enrichment/dotplot.pdf
  <outdir>/03_results/enrichment/dotplot.png
  <outdir>/04_reports/commands.sh
  <outdir>/04_reports/versions.tsv
  <outdir>/04_reports/enrichment_versions.tsv
  <outdir>/04_reports/methods.txt
  <outdir>/04_reports/flow_summary.tsv
  <outdir>/run.manifest.json

Dependencies:
  taf-enrichment-r 0.1.0-r1

Boundaries:
  r1 is offline and GMT-driven. It does not generate DE results, download
  gene sets, infer organisms, convert gene IDs, run online KEGG/MSigDB/Enrichr
  queries, or decide biological interpretation. Gene set source, ID system,
  background universe, and thresholds remain user responsibilities.

Wrapper options:
  -h, --help       Show this help.
  -v, --version    Show package and command version.
  --compile        Print generated shell code instead of running it.
