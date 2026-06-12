#!/bin/sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
project_dir=$(CDPATH= cd "$script_dir/.." && pwd)
bio_apps_dir=$(CDPATH= cd "$project_dir/../../../.." && pwd)

for target_dir in \
    "$bio_apps_dir/tools/enrichment-r/target"
do
    if [ -d "$target_dir" ]; then
        PATH="$target_dir:$PATH"
    fi
done
export PATH

if ! command -v taf >/dev/null 2>&1; then
    echo "smoke: taf command not found in PATH." >&2
    exit 127
fi

if ! command -v taffish >/dev/null 2>&1; then
    echo "smoke: taffish command not found in PATH." >&2
    exit 127
fi

if ! command -v taf-enrichment-r-v0.1.0-r1 >/dev/null 2>&1; then
    echo "smoke: dependency wrapper not found in PATH: taf-enrichment-r-v0.1.0-r1" >&2
    exit 127
fi

TAFFISH_CONTAINER_BACKEND=${TAFFISH_CONTAINER_BACKEND:-podman}
export TAFFISH_CONTAINER_BACKEND
TAF_HISTORY_MODE=${TAF_HISTORY_MODE:-off}
export TAF_HISTORY_MODE

tmpdir=$(mktemp -d "$project_dir/.taf-smoke.XXXXXX")
cleanup() {
    cd "$project_dir" 2>/dev/null || :
    rm -rf "$tmpdir"
}
trap cleanup EXIT INT TERM HUP

cd "$project_dir"

echo "[SMOKE] taf check"
taf check

echo "[SMOKE] taf build"
taf build

flow_cmd="$project_dir/target/taf-rnaseq-enrichment-flow-v0.2.0-r1"
if [ ! -x "$flow_cmd" ]; then
    echo "smoke: built flow command is missing or not executable: $flow_cmd" >&2
    exit 1
fi

echo "[SMOKE] help and version"
"$flow_cmd" --help >/dev/null
"$flow_cmd" --version >/dev/null

run_dir="$tmpdir/run"
mkdir -p "$run_dir"

echo "[SMOKE] rnaseq-enrichment-flow tiny fixture"
(
    cd "$run_dir"
    "$flow_cmd" \
        --gene-list "$project_dir/testdata/gene_list.tsv" \
        --ranked-genes "$project_dir/testdata/ranked_genes.tsv" \
        --gene-sets "$project_dir/testdata/gene_sets.gmt" \
        --background "$project_dir/testdata/background.tsv" \
        --outdir enrichment-out \
        --min-size 1 \
        --max-size 20 \
        --top-n 5 \
        @render-dotplot-step: --vanilla @:
)
cd "$project_dir"

out="$run_dir/enrichment-out"

echo "[SMOKE] output checks"
test -s "$out/00_inputs/gene_list.tsv"
test -s "$out/00_inputs/ranked_genes.tsv"
test -s "$out/00_inputs/gene_sets.gmt"
test -s "$out/00_inputs/background.tsv"
test -s "$out/01_logs/flow.log"
test -s "$out/01_logs/steps/01_validate_inputs.log"
test -s "$out/01_logs/steps/02_enrichment.log"
test -s "$out/01_logs/steps/03_render_dotplot.log"
test -s "$out/01_logs/steps/04_render_extra_plots.log"
test -s "$out/02_intermediate/gene_list.normalized.tsv"
test -s "$out/02_intermediate/ranked_genes.normalized.tsv"
test -s "$out/02_intermediate/background.normalized.tsv"
test -s "$out/02_intermediate/gene_sets.stats.tsv"
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

grep -F 'set_alpha' "$out/03_results/enrichment/ora_results.tsv" >/dev/null
grep -F 'set_beta' "$out/03_results/enrichment/gsea_results.tsv" >/dev/null
grep -F 'ora_result_count' "$out/03_results/enrichment/enrichment_summary.tsv" >/dev/null
grep -F 'taf-enrichment-r-v0.1.0-r1' "$out/04_reports/commands.sh" >/dev/null
grep -F 'Rscript --vanilla' "$out/04_reports/commands.sh" >/dev/null
grep -F 'taf-enrichment-r	0.1.0-r1' "$out/04_reports/versions.tsv" >/dev/null
grep -F 'gene_list_genes	3' "$out/04_reports/flow_summary.tsv" >/dev/null
grep -F 'plot_label_wrap_width	48' "$out/04_reports/flow_summary.tsv" >/dev/null
grep -F 'classic_label_wrap_width	72' "$out/04_reports/flow_summary.tsv" >/dev/null
grep -F 'plot_renderer	rnaseq-enrichment-flow' "$out/03_results/enrichment/dotplot_source.tsv" >/dev/null
grep -F 'plot_family_version	0.2.0-r1' "$out/03_results/enrichment/dotplot_source.tsv" >/dev/null
grep -F 'ora_barplot' "$out/03_results/enrichment/plot_summary.tsv" >/dev/null
grep -F '"flow": "rnaseq-enrichment-flow"' "$out/run.manifest.json" >/dev/null
if command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool "$out/run.manifest.json" >/dev/null
fi

echo "[SMOKE] existing outdir is refused"
if (
    cd "$run_dir"
    "$flow_cmd" \
        --gene-list "$project_dir/testdata/gene_list.tsv" \
        --ranked-genes "$project_dir/testdata/ranked_genes.tsv" \
        --gene-sets "$project_dir/testdata/gene_sets.gmt" \
        --background "$project_dir/testdata/background.tsv" \
        --outdir enrichment-out
) >/dev/null 2>&1; then
    echo "smoke: existing outdir was not refused." >&2
    exit 1
fi

echo "[SMOKE] --force rerun"
(
    cd "$run_dir"
    "$flow_cmd" \
        --gene-list "$project_dir/testdata/gene_list.tsv" \
        --ranked-genes "$project_dir/testdata/ranked_genes.tsv" \
        --gene-sets "$project_dir/testdata/gene_sets.gmt" \
        --background "$project_dir/testdata/background.tsv" \
        --outdir enrichment-out \
        --min-size 1 \
        --max-size 20 \
        --top-n 3 \
        --force
)
test -s "$out/03_results/enrichment/ora_results.tsv"
grep -F 'top_n' "$out/run.manifest.json" >/dev/null

stray=$(find "$run_dir" -mindepth 1 -maxdepth 1 ! -name enrichment-out -print)
if [ -n "$stray" ]; then
    echo "smoke: flow wrote unexpected files outside outdir:" >&2
    printf '%s\n' "$stray" >&2
    exit 1
fi

echo "[SMOKE] ok"
