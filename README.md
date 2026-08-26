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
