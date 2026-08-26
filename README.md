## Overview

**MeCoRI (Methyl-Coenzyme M Reductase Isoenzymes)** is an automated curation framework for high-resolution taxonomic classification of methanogenic *Archaea*

Unlike static reference collections, MeCoRI provides a fully reproducible workflow that:
- Retrieves reference sequences from NCBI and GTDB
- Harmonizes taxonomy across different classification systems
- Removes ambiguous and uninformative entries
- Standardizes species-level annotations
- Generates classifier-ready reference datasets
- Supports future database updates as new releases become available

### Current Release (GTDB R226 / NCBI - March 31, 2026)
The current MeCoRI release contains:
- **694** curated reference sequences
- **233** species
- Integrated *mcr*A and *mrt*A marker genes
- GTDB-compatible taxonomy

### Supported Applications
The database supports both:
- Amplicon-based community profiling
- Full-length gene classification


---

## Repository Structure

<details>
<summary><strong>Click to expand the full directory structure</strong></summary>

```text
MeCoRI/
├── README.md
├── environment.yml
├── database/
│   ├── MeCoRI_tax.qza
│   ├── MeCoRI_seq.qza
│   └── classifier_MeCoRI.qza
├── data/
│   ├── raw/
│   │   └── PF02745.hmm
│   ├── final/
│   └── synonym.txt
├── scripts/
│   ├── 00_prep_gtdb.sh
│   ├── 01_fetch_and_merge.sh
│   ├── 02_super_cleaner.py
│   ├── 03_tax_filter.py
│   ├── 04_species_curator.py
│   ├── 05_apply_synonyms.py
│   ├── 06_curate_pipeline.sh
│   └── 07_train_model.sh
└── benchmark/
    ├── mock_seq.fasta
    ├── mock_taxonomy.tsv
    ├── mock_seq.qza
    └── PRJNA1378807_rep-seqs.qza
```

</details>

---

## MeCoRI Tutorial
### A Beginner-Friendly Guide to Methanogen Classification

Welcome to the MeCoRI tutorial.

This guide is designed for users with little bioinformatics experience.

The tutorial is divided into three parts:

- **Quick Start** (recommended for all users)
- **Reproducing the paper benchmarks**
- **Analyzing your own sequencing data**

---


# Part 1. Quick Start (Recommended)

<details>
<summary><strong>Click to expand the full directory structure</strong></summary>
    
```text

Most users should start here.

The MeCoRI repository already includes a curated reference database and a pre-trained classifier. Therefore, you do **not** need to rebuild the database from NCBI or GTDB.

## Step 1. Install the MeCoRI Environment

MeCoRI provides an environment file that installs all required dependencies.

### Correct installation

Create the environment using:

```bash
mamba env create -f environment.yml
```

This will create an environment named:

```text
mecori
```

### Correct activation

After installation:

```bash
conda activate mecori
```

If successful, your terminal should display:

```text
(mecori)
```

### Important

Do **not** use:

```bash
conda env create -f environment.yml
mamba activate mecori
```

These methods may fail because the QIIME 2 channel configuration in `environment.yml` requires installation through **mamba** but activation through **conda**.

---

## Step 2. Confirm That the Database Files Are Available

Run:

```bash
ls database/
```

Expected output:

```text
MeCoRI_tax.qza
MeCoRI_seq.qza
classifier_MeCoRI.qza
```

These files include:

| File | Description |
|--------|--------|
| `classifier_MeCoRI.qza` | Pre-trained Naive Bayes classifier |
| `MeCoRI_tax.qza` | Curated taxonomy reference |
| `MeCoRI_seq.qza` | Curated reference sequences |


```

</details>
---

# Part 2. Test MeCoRI Using the Mock Community

This section demonstrates the classification accuracy reported in the manuscript.

The repository contains:

```text
benchmark/
├── mock_seq.fasta
├── mock_taxonomy.tsv
├── mock_seq.qza
└── PRJNA1378807_rep-seqs.qza
```

where:

| File | Description |
|--------|--------|
| `mock_seq.fasta` | Mock community sequences |
| `mock_seq.qza` | `mock_seq.fasta` in QIIME 2 format |
| `mock_taxonomy.tsv` | Expected taxonomy labels |
| `PRJNA1378807_rep-seqs.qza` | Real-world dataset used in our paper. This file already contains representative sequences, so no DADA2 processing is required. |

## Run Classification (Mock Community)

```bash
qiime feature-classifier classify-sklearn \
  --i-classifier database/classifier_MeCoRI.qza \
  --i-reads benchmark/mock_seq.qza \
  --o-classification mock_results_MeCoRI.qza
```

## Run Classification (PRJNA1378807)

```bash
qiime feature-classifier classify-sklearn \
  --i-classifier database/classifier_MeCoRI.qza \
  --i-reads benchmark/rep-seqs.qza \
  --o-classification PRJNA1378807_MeCoRI.qza
```

---

# Part 3. Advanced Tutorial: Update the Database

This section is intended for users who wish to generate an updated MeCoRI database using the most recent public resources.

## Overview

The complete rebuilding workflow consists of four main stages:

1. GTDB Download & Extraction
2. Reference Collection & Merging
3. Taxonomic Curation & Dereplication
4. Classifier Training

---

## Step 1. Download and Prepare GTDB Resources

Run the following script to handle both downloading GTDB resources and extracting candidate sequences:

```bash
bash scripts/00_prep_gtdb.sh
```

> ⚠️ **Important**
>
> The files to be downloaded are approximately **174.42 GB** and **122.88 GB**.
> Because they will be fully decompressed into FASTA files, please ensure your disk has at least **2 TB** of available storage before running this step.

This script will automatically:

- Detect and download the latest GTDB archaeal taxonomy, protein, and nucleotide datasets.
- Build the protein database (`all_gtdb_proteins.faa`) and nucleotide database (`all_gtdb_nt.fna`).
- Perform HMM-based screening using `PF02745.hmm` to identify candidate *mcr*A/*mrt*A-associated sequences.
- Extract target nucleotide sequences and their corresponding taxonomy using an embedded Python script.

### Expected Outputs

Located in `data/raw/` (or the working directory defined in the script):

```text
ar53_taxonomy.tsv
all_gtdb_proteins.faa
all_gtdb_nt.fna
gtdb_mcrA_mrtA_hits.tsv
mcrA_mrtA_target_ids.txt
gtdb_mcrA_mrtA.fasta
gtdb_mcrA_mrtA_tax.tsv
```

---

## Step 2. Retrieve and Merge Public Reference Resources

Run:

```bash
bash scripts/01_fetch_and_merge.sh
```

### Expected Outputs

Located in `data/merged/`:

```text
mcrA_mrtA_seqs.qza
mcrA_mrtA_tax.qza
```

---

## Step 3. Master Taxonomic Curation & Dereplication

Run:

```bash
bash scripts/06_curate_pipeline.sh
```

This pipeline orchestrates the curation scripts (`02_super_cleaner.py`–`05_apply_synonyms.py`) together with RESCRIPt dereplication to standardize taxonomy, remove ambiguous and incomplete classifications, harmonize species names and synonyms, and generate a curated non-redundant reference database.

### Expected Outputs

Located in `data/final/`:

```text
MeCoRI_seq.qza
MeCoRI_tax.qza
MeCoRI_tax.qzv
```

---

## Step 4. Train a New Classifier

Run:

```bash
bash scripts/07_train_model.sh
```

The Naive Bayes classifier is trained using:

- Reference sequences: `data/final/MeCoRI_seq.qza`
- Reference taxonomy: `data/final/MeCoRI_tax.qza`

### Expected Output

Located in `models/`:

```text
classifier_MeCoRI.qza
```

---

# Verify Successful Completion

After rebuilding the database, verify that the following files have been generated:

```text
data/final/
├── MeCoRI_seq.qza
├── MeCoRI_tax.qza
└── MeCoRI_tax.qzv

models/
└── classifier_MeCoRI.qza
```

These files can be used exactly as described in the Quick Start section for:

- Mock community validation
- Environmental dataset classification
- Custom *mcrA*/*mrtA* taxonomic profiling
