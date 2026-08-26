#!/bin/bash
set -euo pipefail

mkdir -p data/raw data/merged

echo "[INFO] Fetching mcrA sequences from NCBI..."
qiime rescript get-ncbi-data \
  --p-query '("mcrA"[Gene] OR "methyl coenzyme M reductase alpha subunit"[Title/Abstract]) AND "Archaea"[Organism]' \
  --p-n-jobs 4 \
  --o-sequences data/raw/ncbi_mcrA_seqs.qza \
  --o-taxonomy data/raw/ncbi_mcrA_tax.qza

echo "[INFO] Fetching mrtA sequences from NCBI..."
qiime rescript get-ncbi-data \
  --p-query '("mrtA"[Gene] OR "methyl-coenzyme M reductase II subunit alpha"[Title/Abstract] OR "methyl coenzyme M reductase II alpha subunit"[Title/Abstract]) AND "Archaea"[Organism]' \
  --p-n-jobs 4 \
  --o-sequences data/raw/ncbi_mrtA_seqs.qza \
  --o-taxonomy data/raw/ncbi_mrtA_tax.qza

echo "[INFO] Fetching literature-derived sets via NCBI..."
qiime rescript get-ncbi-data \
  --p-query 'PRJNA472146[BioProject] AND (mcrA[Gene] OR "methyl-coenzyme M reductase subunit alpha")' \
  --p-n-jobs 4 \
  --o-sequences data/raw/borrel2019_mcrA_seqs.qza \
  --o-taxonomy data/raw/borrel2019_mcrA_tax.qza

qiime rescript get-ncbi-data \
  --p-query 'PRJNA475886[BioProject]' \
  --p-n-jobs 4 \
  --o-sequences data/raw/wang2019_mcrA_seqs.qza \
  --o-taxonomy data/raw/wang2019_mcrA_tax.qza

qiime rescript get-ncbi-data \
  --p-query '(LIHJ01000000[Accession] OR LIHK01000000[Accession] OR KT387805:KT387832[Accession])' \
  --p-n-jobs 4 \
  --o-sequences data/raw/evans2015_mcrA_seqs.qza \
  --o-taxonomy data/raw/evans2015_mcrA_tax.qza

echo "[INFO] Fetching Yang (Mothur 2014) dataset from GFZ Potsdam..."
wget -qO data/raw/mcrAtemplate.fasta https://datapub.gfz-potsdam.de/download/10.5880.GFZ.4.5.2014.001/mcrAtemplate.fasta
wget -qO data/raw/tax4mcrA.taxonomy.txt https://datapub.gfz-potsdam.de/download/10.5880.GFZ.4.5.2014.001/tax4mcrA.taxonomy.txt

echo "[INFO] Importing Yang dataset into QIIME 2 artifacts..."
qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path data/raw/mcrAtemplate.fasta \
  --output-path data/raw/mothur2014_mcrA_seqs.qza

qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --input-format HeaderlessTSVTaxonomyFormat \
  --input-path data/raw/tax4mcrA.taxonomy.txt \
  --output-path data/raw/mothur2014_mcrA_tax.qza

echo "[INFO] Importing parsed GTDB dataset into QIIME 2 artifacts..."
qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path data/raw/gtdb_mcrA_mrtA.fasta \
  --output-path data/raw/gtdb_mcrA_mrtA_seqs.qza

qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --input-format TSVTaxonomyFormat \
  --input-path data/raw/gtdb_mcrA_mrtA_tax.tsv \
  --output-path data/raw/gtdb_mcrA_mrtA_tax.qza

echo "[INFO] Merging all sequence files..."
qiime feature-table merge-seqs \
  --i-data data/raw/ncbi_mcrA_seqs.qza \
  --i-data data/raw/ncbi_mrtA_seqs.qza \
  --i-data data/raw/borrel2019_mcrA_seqs.qza \
  --i-data data/raw/wang2019_mcrA_seqs.qza \
  --i-data data/raw/evans2015_mcrA_seqs.qza \
  --i-data data/raw/mothur2014_mcrA_seqs.qza \
  --i-data data/raw/gtdb_mcrA_mrtA_seqs.qza \
  --o-merged-data data/merged/mcrA_mrtA_seqs.qza

echo "[INFO] Merging all taxonomy files..."
qiime feature-table merge-taxa \
  --i-data data/raw/ncbi_mcrA_tax.qza \
  --i-data data/raw/ncbi_mrtA_tax.qza \
  --i-data data/raw/borrel2019_mcrA_tax.qza \
  --i-data data/raw/wang2019_mcrA_tax.qza \
  --i-data data/raw/evans2015_mcrA_tax.qza \
  --i-data data/raw/mothur2014_mcrA_tax.qza \
  --i-data data/raw/gtdb_mcrA_mrtA_tax.qza \
  --o-merged-data data/merged/mcrA_mrtA_tax.qza

echo "[INFO] Data acquisition and merging complete."