#!/bin/bash
set -euo pipefail

THREADS=36

mkdir -p data/raw
cd data/raw

echo "=================================================="
echo " GTDB mcrA/mrtA preparation"
echo "=================================================="

############################################################
# Required HMM
############################################################

if [[ ! -f PF02745.hmm ]]; then
    echo
    echo "[ERROR] PF02745.hmm not found:"
    echo "$(pwd)/PF02745.hmm"
    echo
    exit 1
fi

echo "[INFO] Found PF02745.hmm"

############################################################
# Detect existing GTDB release-specific files
############################################################

echo
echo "[INFO] Checking existing GTDB files ..."

shopt -s nullglob

AA_FILES=(gtdb_proteins_aa_reps_r*.tar.gz)
NT_FILES=(gtdb_proteins_nt_reps_r*.tar.gz)
TAX_FILES=(ar53_taxonomy_r*.tsv.gz)

shopt -u nullglob

############################################################
# Helper function
############################################################

extract_release() {

    local filename="$1"

    if [[ "${filename}" =~ _r([0-9]+)\.(tar\.gz|tsv\.gz)$ ]]; then
        echo "r${BASH_REMATCH[1]}"
    else
        echo ""
    fi

}

############################################################
# Select existing AA archive
############################################################

AA_TAR=""

if (( ${#AA_FILES[@]} > 1 )); then

    echo
    echo "[ERROR] Multiple AA archives found:"
    printf '  %s\n' "${AA_FILES[@]}"
    echo
    echo "[ERROR] Please keep only one GTDB AA release."
    exit 1

elif (( ${#AA_FILES[@]} == 1 )); then

    AA_TAR="${AA_FILES[0]}"

    echo "[INFO] Existing AA archive:"
    echo "       ${AA_TAR}"

fi

############################################################
# Select existing NT archive
############################################################

NT_TAR=""

if (( ${#NT_FILES[@]} > 1 )); then

    echo
    echo "[ERROR] Multiple NT archives found:"
    printf '  %s\n' "${NT_FILES[@]}"
    echo
    echo "[ERROR] Please keep only one GTDB NT release."
    exit 1

elif (( ${#NT_FILES[@]} == 1 )); then

    NT_TAR="${NT_FILES[0]}"

    echo "[INFO] Existing NT archive:"
    echo "       ${NT_TAR}"

fi

############################################################
# Select existing taxonomy
############################################################

TAX_GZ=""

if (( ${#TAX_FILES[@]} > 1 )); then

    echo
    echo "[ERROR] Multiple taxonomy archives found:"
    printf '  %s\n' "${TAX_FILES[@]}"
    echo
    echo "[ERROR] Please keep only one GTDB taxonomy release."
    exit 1

elif (( ${#TAX_FILES[@]} == 1 )); then

    TAX_GZ="${TAX_FILES[0]}"

    echo "[INFO] Existing taxonomy:"
    echo "       ${TAX_GZ}"

fi

############################################################
# Determine existing releases
############################################################

AA_RELEASE=""
NT_RELEASE=""
TAX_RELEASE=""

if [[ -n "${AA_TAR}" ]]; then
    AA_RELEASE=$(extract_release "${AA_TAR}")
fi

if [[ -n "${NT_TAR}" ]]; then
    NT_RELEASE=$(extract_release "${NT_TAR}")
fi

if [[ -n "${TAX_GZ}" ]]; then
    TAX_RELEASE=$(extract_release "${TAX_GZ}")
fi

############################################################
# Check release consistency
############################################################

if [[ -n "${AA_RELEASE}" && \
      -n "${NT_RELEASE}" && \
      "${AA_RELEASE}" != "${NT_RELEASE}" ]]; then

    echo
    echo "[ERROR] AA and NT GTDB releases do not match:"
    echo "       AA = ${AA_RELEASE}"
    echo "       NT = ${NT_RELEASE}"
    echo
    exit 1

fi

if [[ -n "${AA_RELEASE}" && \
      -n "${TAX_RELEASE}" && \
      "${AA_RELEASE}" != "${TAX_RELEASE}" ]]; then

    echo
    echo "[ERROR] AA and taxonomy GTDB releases do not match:"
    echo "       AA  = ${AA_RELEASE}"
    echo "       TAX = ${TAX_RELEASE}"
    echo
    exit 1

fi

if [[ -n "${NT_RELEASE}" && \
      -n "${TAX_RELEASE}" && \
      "${NT_RELEASE}" != "${TAX_RELEASE}" ]]; then

    echo
    echo "[ERROR] NT and taxonomy GTDB releases do not match:"
    echo "       NT  = ${NT_RELEASE}"
    echo "       TAX = ${TAX_RELEASE}"
    echo
    exit 1

fi

############################################################
# Determine GTDB release
############################################################

GTDB_RELEASE=""

if [[ -n "${AA_RELEASE}" ]]; then
    GTDB_RELEASE="${AA_RELEASE}"
elif [[ -n "${NT_RELEASE}" ]]; then
    GTDB_RELEASE="${NT_RELEASE}"
elif [[ -n "${TAX_RELEASE}" ]]; then
    GTDB_RELEASE="${TAX_RELEASE}"
fi

############################################################
# If an existing release was found
############################################################

if [[ -n "${GTDB_RELEASE}" ]]; then

    echo
    echo "=================================================="
    echo "[INFO] Existing GTDB release detected: ${GTDB_RELEASE}"
    echo "=================================================="

    ########################################################
    # Fill missing filenames using detected release
    ########################################################

    if [[ -z "${AA_TAR}" ]]; then

        AA_TAR="gtdb_proteins_aa_reps_${GTDB_RELEASE}.tar.gz"

        echo
        echo "[INFO] Missing AA archive:"
        echo "       ${AA_TAR}"

    fi

    if [[ -z "${NT_TAR}" ]]; then

        NT_TAR="gtdb_proteins_nt_reps_${GTDB_RELEASE}.tar.gz"

        echo
        echo "[INFO] Missing NT archive:"
        echo "       ${NT_TAR}"

    fi

    if [[ -z "${TAX_GZ}" ]]; then

        TAX_GZ="ar53_taxonomy_${GTDB_RELEASE}.tsv.gz"

        echo
        echo "[INFO] Missing taxonomy:"
        echo "       ${TAX_GZ}"

    fi

    ########################################################
    # Convert r232 -> release232/232.0
    ########################################################

    RELEASE_NUMBER="${GTDB_RELEASE#r}"

    RELEASE_PATH="release${RELEASE_NUMBER}/${RELEASE_NUMBER}.0"

    BASE_URL="https://data.gtdb.ecogenomic.org/releases/${RELEASE_PATH}"

    echo
    echo "[INFO] GTDB release path:"
    echo "       ${RELEASE_PATH}"

    ########################################################
    # Download missing taxonomy only
    ########################################################

    if [[ -f "${TAX_GZ}" ]]; then

        echo
        echo "[INFO] Found ${TAX_GZ}"
        echo "[INFO] Skipping taxonomy download"

    else

        echo
        echo "[INFO] Downloading missing taxonomy:"
        echo "       ${TAX_GZ}"

        wget \
            "${BASE_URL}/${TAX_GZ}"

    fi

    ########################################################
    # Download missing AA only
    ########################################################

    if [[ -f "${AA_TAR}" ]]; then

        echo
        echo "[INFO] Found ${AA_TAR}"
        echo "[INFO] Skipping AA download"

    else

        echo
        echo "[INFO] Downloading missing AA archive:"
        echo "       ${AA_TAR}"

        wget \
            "${BASE_URL}/genomic_files_reps/${AA_TAR}"

    fi

    ########################################################
    # Download missing NT only
    ########################################################

    if [[ -f "${NT_TAR}" ]]; then

        echo
        echo "[INFO] Found ${NT_TAR}"
        echo "[INFO] Skipping NT download"

    else

        echo
        echo "[INFO] Downloading missing NT archive:"
        echo "       ${NT_TAR}"

        wget \
            "${BASE_URL}/genomic_files_reps/${NT_TAR}"

    fi

############################################################
# No existing GTDB release
############################################################

else

    echo
    echo "[INFO] No existing GTDB release-specific files found."
    echo "[INFO] Detecting latest GTDB release ..."

    # GTDB /releases/latest/ no longer redirects to releaseXXX/XXX.0.
    # Read the release number directly from VERSION.txt instead.
    VERSION_CONTENT=$(curl -fsSL \
        https://data.gtdb.ecogenomic.org/releases/latest/VERSION.txt)

    RELEASE_NUMBER=$(printf '%s\n' "${VERSION_CONTENT}" \
        | grep -m1 -E '^v[0-9]+$' \
        | sed 's/^v//')

    if [[ -z "${RELEASE_NUMBER}" ]]; then

        echo
        echo "[ERROR] Could not determine GTDB release from:"
        echo "https://data.gtdb.ecogenomic.org/releases/latest/VERSION.txt"
        echo "${VERSION_CONTENT}"
        exit 1

    fi

    GTDB_RELEASE="r${RELEASE_NUMBER}"

    # The /latest/ directory uses release-independent filenames.
    BASE_URL="https://data.gtdb.ecogenomic.org/releases/latest"

    TAX_GZ="ar53_taxonomy.tsv.gz"
    AA_TAR="gtdb_proteins_aa_reps.tar.gz"
    NT_TAR="gtdb_proteins_nt_reps.tar.gz"

    echo
    echo "[INFO] Latest GTDB release: ${GTDB_RELEASE}"

    ########################################################
    # Download taxonomy
    ########################################################

    if [[ -f "${TAX_GZ}" ]]; then

        echo "[INFO] Found ${TAX_GZ}"
        echo "[INFO] Skipping download"

    else

        echo "[INFO] Downloading ${TAX_GZ}"

        wget \
            "${BASE_URL}/${TAX_GZ}"

    fi

    ########################################################
    # Download AA
    ########################################################

    if [[ -f "${AA_TAR}" ]]; then

        echo "[INFO] Found ${AA_TAR}"
        echo "[INFO] Skipping download"

    else

        echo "[INFO] Downloading ${AA_TAR}"

        wget \
            "${BASE_URL}/genomic_files_reps/${AA_TAR}"

    fi

    ########################################################
    # Download NT
    ########################################################

    if [[ -f "${NT_TAR}" ]]; then

        echo "[INFO] Found ${NT_TAR}"
        echo "[INFO] Skipping download"

    else

        echo "[INFO] Downloading ${NT_TAR}"

        wget \
            "${BASE_URL}/genomic_files_reps/${NT_TAR}"

    fi

fi

############################################################
# Final GTDB file check
############################################################

echo
echo "[INFO] Final GTDB input check"

for file in "${TAX_GZ}" "${AA_TAR}" "${NT_TAR}"; do

    if [[ ! -f "${file}" ]]; then

        echo
        echo "[ERROR] Required GTDB file missing:"
        echo "       ${file}"
        exit 1

    fi

    echo "[OK] ${file}"

done

############################################################
# Extract taxonomy
############################################################

if [[ -f ar53_taxonomy.tsv ]]; then

    echo
    echo "[INFO] Found existing ar53_taxonomy.tsv"
    echo "[INFO] Skipping extraction"

else

    echo
    echo "[INFO] Extracting taxonomy"

    gunzip -c "${TAX_GZ}" \
        > ar53_taxonomy.tsv

fi

############################################################
# Build protein database
############################################################

if [[ -f all_gtdb_proteins.faa ]]; then

    echo
    echo "[INFO] Found existing all_gtdb_proteins.faa"
    echo "[INFO] Skipping extraction"

else

    echo
    echo "[INFO] Building all_gtdb_proteins.faa"

    tar -xOzf "${AA_TAR}" \
        --wildcards "*.faa.gz" \
    | gzip -dc \
    > all_gtdb_proteins.faa

fi

############################################################
# Build nucleotide database
############################################################

if [[ -f all_gtdb_nt.fna ]]; then

    echo
    echo "[INFO] Found existing all_gtdb_nt.fna"
    echo "[INFO] Skipping extraction"

else

    echo
    echo "[INFO] Building all_gtdb_nt.fna"

    tar -xOzf "${NT_TAR}" \
        --wildcards "*.fna.gz" \
    | gzip -dc \
    > all_gtdb_nt.fna

fi

############################################################
# HMM search
############################################################

if [[ -f gtdb_mcrA_mrtA_hits.tsv ]]; then

    echo
    echo "[INFO] Found existing gtdb_mcrA_mrtA_hits.tsv"
    echo "[INFO] Skipping hmmsearch"

else

    echo
    echo "[INFO] Running hmmsearch (PF02745)"

    hmmsearch \
        --cpu "${THREADS}" \
        -E 1e-10 \
        --domE 1e-10 \
        --tblout gtdb_mcrA_mrtA_hits.tsv \
        PF02745.hmm \
        all_gtdb_proteins.faa \
        > /dev/null

fi

############################################################
# Extract target IDs
############################################################

if [[ -f mcrA_mrtA_target_ids.txt ]]; then

    echo
    echo "[INFO] Found existing mcrA_mrtA_target_ids.txt"
    echo "[INFO] Skipping target ID extraction"

else

    echo
    echo "[INFO] Extracting target IDs"

    grep -v '^#' gtdb_mcrA_mrtA_hits.tsv \
        | awk '{print $1}' \
        | sort -u \
        > mcrA_mrtA_target_ids.txt

fi

HIT_COUNT=$(wc -l < mcrA_mrtA_target_ids.txt)

echo
echo "[INFO] ${HIT_COUNT} candidate mcrA/mrtA proteins found"

############################################################
# Extract DNA sequences + taxonomy
############################################################

if [[ -f gtdb_mcrA_mrtA.fasta && \
      -f gtdb_mcrA_mrtA_tax.tsv ]]; then

    echo
    echo "[INFO] Found existing mcrA/mrtA outputs"
    echo "[INFO] Skipping sequence/taxonomy extraction"

else

    echo
    echo "[INFO] Extracting DNA sequences and taxonomy"

    python3 << 'PYTHON'

IDS_FILE = "mcrA_mrtA_target_ids.txt"
TAX_FILE = "ar53_taxonomy.tsv"
DNA_FILE = "all_gtdb_nt.fna"

OUT_FASTA = "gtdb_mcrA_mrtA.fasta"
OUT_TAX = "gtdb_mcrA_mrtA_tax.tsv"

print("[INFO] Loading target IDs")

with open(IDS_FILE) as f:

    target_ids = {
        line.strip()
        for line in f
        if line.strip()
    }

print(f"[INFO] Loaded {len(target_ids)} IDs")

############################################################
# Load taxonomy
############################################################

print("[INFO] Loading taxonomy")

tax_dict = {}

with open(TAX_FILE) as f:

    for line in f:

        parts = line.rstrip("\n").split("\t")

        if len(parts) >= 2:

            tax_dict[parts[0]] = parts[1]

print(
    f"[INFO] Loaded {len(tax_dict)} taxonomy records"
)

############################################################
# Extract DNA
############################################################

print("[INFO] Extracting nucleotide sequences")

tax_lines = ["Feature ID\tTaxon\n"]

found = 0

with open(DNA_FILE) as fin, \
     open(OUT_FASTA, "w") as fout:

    keep = False

    for line in fin:

        if line.startswith(">"):

            seqid = line.split()[0][1:]

            if seqid in target_ids:

                keep = True

                fout.write(line)

                found += 1

                genome_id = "_".join(
                    seqid.split("_")[:-1]
                )

                taxonomy = tax_dict.get(
                    genome_id,
                    "Unknown"
                )

                tax_lines.append(
                    f"{seqid}\t{taxonomy}\n"
                )

            else:

                keep = False

        elif keep:

            fout.write(line)

############################################################
# Write taxonomy
############################################################

with open(OUT_TAX, "w") as fout:

    fout.writelines(tax_lines)

print(
    f"[INFO] Extracted {found} nucleotide sequences"
)

print(
    f"[INFO] FASTA: {OUT_FASTA}"
)

print(
    f"[INFO] TAX:   {OUT_TAX}"
)

if found == 0:

    print(
        "[WARNING] No target nucleotide sequences "
        "were found."
    )

PYTHON

fi

############################################################
# Summary
############################################################

echo
echo "=================================================="
echo " GTDB preparation completed"
echo "=================================================="
echo

echo "GTDB release:"
echo "  ${GTDB_RELEASE}"

echo
echo "GTDB input files:"
echo "  ${TAX_GZ}"
echo "  ${AA_TAR}"
echo "  ${NT_TAR}"

echo
echo "Output files:"
echo "  ar53_taxonomy.tsv"
echo "  all_gtdb_proteins.faa"
echo "  all_gtdb_nt.fna"
echo "  gtdb_mcrA_mrtA_hits.tsv"
echo "  mcrA_mrtA_target_ids.txt"
echo "  gtdb_mcrA_mrtA.fasta"
echo "  gtdb_mcrA_mrtA_tax.tsv"

echo
echo "Next step:"
echo "bash scripts/01_fetch_and_merge.sh"
echo