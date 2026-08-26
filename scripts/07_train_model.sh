#!/bin/bash
#SBATCH --job-name=train_mecori
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --time=06:00:00
#SBATCH --mem=32G
#SBATCH --output=train_%j.out
#SBATCH --error=train_%j.err
#SBATCH --export=NONE
#SBATCH --get-user-env

set -euo pipefail
mkdir -p models

echo "[INFO] Training Naive Bayes Classifier on dereplicated references..."
qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads data/final/MeCoRI_seq.qza \
  --i-reference-taxonomy data/final/MeCoRI_tax.qza \
  --o-classifier models/classifier_MeCoRI.qza

echo "[INFO] Classifier training complete: models/classifier_MeCoRI.qza"