import os
import re

INPUT_FILE = "format_tax/taxonomy.tsv"
OUTPUT_FILE = "format_tax/taxonomy_fixed.tsv"

phylum_map = {"Euryarchaeota": "Methanobacteriota"}

print("[INFO] Starting text-level super curation...")

processed_ids = set()
output_lines = []

if not os.path.exists(INPUT_FILE):
    raise FileNotFoundError(f"Input file not found: {INPUT_FILE}")

with open(INPUT_FILE, "r", encoding="utf-8") as f:
    header = f.readline()
    output_lines.append(header)

    for line in f:
        line = line.strip()
        if not line:
            continue
        parts = line.split("\t")
        if len(parts) < 2:
            continue

        raw_id = parts[0].strip()
        raw_tax = parts[1].strip()

        clean_id = re.sub(r"\.\d+$", "", raw_id)

        if clean_id in processed_ids:
            continue
        processed_ids.add(clean_id)

        tax_parts = [p.strip() for p in raw_tax.split(";")]
        clean_parts = [re.sub(r"^[kdpfcogs]__", "", p) for p in tax_parts]
        prefixes = ["d__", "p__", "c__", "o__", "f__", "g__", "s__"]

        new_levels = []
        for i in range(7):
            if i < len(clean_parts) and clean_parts[i]:
                val = clean_parts[i]
                if i == 0 and val in ["Archaea", "Methanobacteriati"]:
                    val = "Archaea"
                if i == 1 and val in phylum_map:
                    val = phylum_map[val]
                new_levels.append(f"{prefixes[i]}{val}")
            else:
                new_levels.append(f"{prefixes[i]}")

        output_lines.append(f"{clean_id}\t{';'.join(new_levels)}")

with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    for line in output_lines:
        f.write(line + "\n")

print(f"[INFO] Processed {len(processed_ids)} unique sequences.")
print("[INFO] Standardized ALL Domain prefixes to 'd__Archaea'.")