#!/bin/bash
#SBATCH --job-name=mcrA_mrtA_curate
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --time=04:00:00
#SBATCH --mem=32G
#SBATCH --output=curate_%j.out
#SBATCH --error=curate_%j.err
#SBATCH --export=NONE
#SBATCH --get-user-env

set -euo pipefail

mkdir -p format_tax data/final

echo "[INFO] Step 1: Exporting raw merged taxonomy..."
qiime tools export \
  --input-path data/merged/mcrA_mrtA_tax.qza \
  --output-path format_tax/

echo "[INFO] Step 2: Standardizing prefixes..."
python3 scripts/02_super_cleaner.py

echo "[INFO] Step 3: Filtering uncultured/unidentified entries..."
python3 scripts/03_tax_filter.py

echo "[INFO] Step 4: Enforcing strict binomial species naming..."
python3 scripts/04_species_curator.py

echo "[INFO] Step 5: Synchronizing taxonomic synonyms..."
python3 scripts/05_apply_synonyms.py

echo "[INFO] Step 6: Re-importing curated taxonomy to QIIME 2..."
qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --input-format TSVTaxonomyFormat \
  --input-path format_tax/taxonomy_curated_final.tsv \
  --output-path data/final/mcrA_mrtA_curated_tax.qza

echo "[INFO] Step 7: Subsetting sequence artifacts to match curated taxonomy..."
qiime feature-table filter-seqs \
  --i-data data/merged/mcrA_mrtA_seqs.qza \
  --m-metadata-file format_tax/taxonomy_curated_final.tsv \
  --o-filtered-data data/final/mcrA_mrtA_curated_seqs.qza

echo "[INFO] Step 8: Dereplicating via RESCRIPt (Super Mode)..."
qiime rescript dereplicate \
  --i-sequences data/final/mcrA_mrtA_curated_seqs.qza \
  --i-taxa data/final/mcrA_mrtA_curated_tax.qza \
  --p-mode 'super' \
  --o-dereplicated-sequences data/final/MeCoRI_seq.qza \
  --o-dereplicated-taxa data/final/MeCoRI_tax.qza

echo "[INFO] Step 9: Generating final taxonomy visualization..."
qiime metadata tabulate \
  --m-input-file data/final/MeCoRI_tax.qza \
  --o-visualization data/final/MeCoRI_tax.qzv

echo "[INFO] Master curation completed successfully."