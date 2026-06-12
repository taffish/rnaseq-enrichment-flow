#!/bin/sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
project_dir=$(CDPATH= cd "$script_dir/.." && pwd)
bio_apps_dir=$(CDPATH= cd "$project_dir/../../../.." && pwd)
rnaseq_root=$(CDPATH= cd "$project_dir/../.." && pwd)
de_flow_dir="$rnaseq_root/subflows/rnaseq-de-flow"
default_data_root=$(CDPATH= cd "$rnaseq_root/test-data/yeast/data/03_results" 2>/dev/null && pwd || printf '%s\n' "$rnaseq_root/test-data/yeast/data/03_results")
data_root=${TAFFISH_RNASEQ_TESTDATA:-$default_data_root}

for target_dir in \
    "$bio_apps_dir/tools/enrichment-r/target" \
    "$bio_apps_dir/tools/bioconductor-rnaseq/target" \
    "$de_flow_dir/target"
do
    if [ -d "$target_dir" ]; then
        PATH="$target_dir:$PATH"
    fi
done
export PATH

TAFFISH_CONTAINER_BACKEND=${TAFFISH_CONTAINER_BACKEND:-podman}
export TAFFISH_CONTAINER_BACKEND
TAF_HISTORY_MODE=${TAF_HISTORY_MODE:-off}
export TAF_HISTORY_MODE

skip_formal() {
    echo "formal: skipped: $*" >&2
    exit 0
}

if [ ! -d "$data_root" ]; then
    skip_formal "RNA-seq formal data root not found: $data_root"
fi

counts="$data_root/yeast-snf2-counts-medium-v1/counts/gene_counts_12v12.tsv"
selected="$data_root/yeast-snf2-counts-medium-v1/source/selected_count_files.tsv"
gene_sets_pkg="$data_root/yeast-sgd-go-gene-sets-r64.4.1-v1"
gene_sets="$gene_sets_pkg/gene_sets/sgd_go_bp.gmt"
background="$gene_sets_pkg/background/yeast_background_genes.tsv"

[ -s "$counts" ] || skip_formal "missing yeast count matrix: $counts"
[ -s "$selected" ] || skip_formal "missing yeast selected count-file map: $selected"
[ -s "$gene_sets" ] || skip_formal "missing yeast SGD GO BP GMT: $gene_sets"
[ -s "$background" ] || skip_formal "missing yeast enrichment background: $background"

if ! command -v taf >/dev/null 2>&1; then
    echo "formal: taf command not found in PATH." >&2
    exit 127
fi

for dep in \
    taf-enrichment-r-v0.1.0-r1 \
    taf-bioconductor-rnaseq-v3.23-r1
do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "formal: dependency wrapper not found in PATH: $dep" >&2
        exit 127
    fi
done

echo "[FORMAL] build rnaseq-de-flow"
(
    cd "$de_flow_dir"
    taf check
    taf build
)
de_flow_cmd="$de_flow_dir/target/taf-rnaseq-de-flow-v0.2.0-r1"
if [ ! -x "$de_flow_cmd" ]; then
    echo "formal: built DE flow command is missing or not executable: $de_flow_cmd" >&2
    exit 1
fi

tmpdir=$(mktemp -d "$project_dir/.taf-formal.XXXXXX")
cleanup() {
    cd "$project_dir" 2>/dev/null || :
    rm -rf "$tmpdir"
}
trap cleanup EXIT INT TERM HUP

cd "$project_dir"

echo "[FORMAL] taf check"
taf check

echo "[FORMAL] taf build"
taf build

flow_cmd="$project_dir/target/taf-rnaseq-enrichment-flow-v0.2.0-r1"
if [ ! -x "$flow_cmd" ]; then
    echo "formal: built flow command is missing or not executable: $flow_cmd" >&2
    exit 1
fi

run_dir="$tmpdir/run"
mkdir -p "$run_dir"

metadata="$run_dir/metadata.tsv"
awk -F '\t' -v OFS='\t' '
    NR == 1 {
        for (i = 1; i <= NF; i++) col[$i] = i
        if (!("sample_id" in col) || !("condition" in col)) {
            print "formal: selected_count_files.tsv must contain sample_id and condition" > "/dev/stderr"
            exit 2
        }
        print "sample", "condition"
        next
    }
    $0 == "" { next }
    {
        print $(col["sample_id"]), $(col["condition"])
    }
' "$selected" > "$metadata"

echo "[FORMAL] rnaseq-de-flow yeast 12v12 count matrix"
(
    cd "$run_dir"
    "$de_flow_cmd" \
        --counts "$counts" \
        --metadata "$metadata" \
        --design '~ condition' \
        --contrast condition:snf2_KO:WT \
        --outdir de-out \
        --fit-type local \
        --min-count 10 \
        --min-samples 4 \
        --padj-cutoff 0.05 \
        --lfc-cutoff 1 \
        --top-var 500 \
        --top-heatmap 50
)

de_out="$run_dir/de-out"
test -s "$de_out/03_results/gene_lists/significant_genes.tsv"
test -s "$de_out/03_results/gene_lists/ranked_genes.tsv"

echo "[FORMAL] rnaseq-enrichment-flow yeast GO enrichment"
(
    cd "$run_dir"
    "$flow_cmd" \
        --gene-list "$de_out/03_results/gene_lists/significant_genes.tsv" \
        --ranked-genes "$de_out/03_results/gene_lists/ranked_genes.tsv" \
        --gene-sets "$gene_sets" \
        --background "$background" \
        --outdir enrichment-out \
        --min-size 2 \
        --max-size 500 \
        --top-n 20
)

out="$run_dir/enrichment-out"
test -s "$out/03_results/enrichment/ora_results.tsv"
test -s "$out/03_results/enrichment/gsea_results.tsv"
test -s "$out/03_results/enrichment/enrichment_summary.tsv"
test -s "$out/03_results/enrichment/dotplot.pdf"
test -s "$out/03_results/enrichment/dotplot.png"
test -s "$out/03_results/enrichment/dotplot.original.pdf"
test -s "$out/03_results/enrichment/dotplot.original.png"
test -s "$out/03_results/enrichment/ora_barplot.pdf"
test -s "$out/03_results/enrichment/ora_barplot.png"
test -s "$out/03_results/enrichment/gsea_nes_plot.pdf"
test -s "$out/03_results/enrichment/gsea_nes_plot.png"
test -s "$out/03_results/enrichment/gsea_enrichment_curves.pdf"
test -s "$out/03_results/enrichment/gsea_enrichment_curves.png"
test -s "$out/03_results/enrichment/dotplot_source.tsv"
test -s "$out/03_results/enrichment/plot_summary.tsv"
test -s "$out/04_reports/commands.sh"
test -s "$out/04_reports/versions.tsv"
test -s "$out/04_reports/enrichment_versions.tsv"
test -s "$out/04_reports/methods.txt"
test -s "$out/04_reports/flow_summary.tsv"
test -s "$out/run.manifest.json"

grep -F 'gene_sets	2274' "$out/04_reports/flow_summary.tsv" >/dev/null
grep -F 'background_genes	7127' "$out/04_reports/flow_summary.tsv" >/dev/null
grep -F 'plot_terms	20' "$out/04_reports/flow_summary.tsv" >/dev/null
grep -F 'plot_label_wrap_width	48' "$out/04_reports/flow_summary.tsv" >/dev/null
grep -F 'classic_label_wrap_width	72' "$out/04_reports/flow_summary.tsv" >/dev/null
grep -F 'plot_renderer	rnaseq-enrichment-flow' "$out/03_results/enrichment/dotplot_source.tsv" >/dev/null
grep -F 'plot_family_version	0.2.0-r1' "$out/03_results/enrichment/dotplot_source.tsv" >/dev/null
grep -F 'gsea_enrichment_curves' "$out/03_results/enrichment/plot_summary.tsv" >/dev/null
grep -F 'taf-enrichment-r-v0.1.0-r1' "$out/04_reports/commands.sh" >/dev/null
grep -F '"flow": "rnaseq-enrichment-flow"' "$out/run.manifest.json" >/dev/null

ora_rows=$(awk 'NR > 1 { c++ } END { print c + 0 }' "$out/03_results/enrichment/ora_results.tsv")
gsea_rows=$(awk 'NR > 1 { c++ } END { print c + 0 }' "$out/03_results/enrichment/gsea_results.tsv")
[ "$ora_rows" -gt 0 ] || {
    echo "formal: expected non-empty ORA results for yeast GO formal test" >&2
    exit 1
}
[ "$gsea_rows" -gt 0 ] || {
    echo "formal: expected non-empty GSEA results for yeast GO formal test" >&2
    exit 1
}

if command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool "$out/run.manifest.json" >/dev/null
fi

echo "[FORMAL] ok"
