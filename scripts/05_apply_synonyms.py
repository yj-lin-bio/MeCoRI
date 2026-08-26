import os
import sys

INPUT_FILE = "format_tax/taxonomy_curated_strict.tsv"
SYNONYM_FILE = "data/synonym.txt"
OUTPUT_FILE = "format_tax/taxonomy_curated_final.tsv"

def load_synonyms(filepath):
    syn_map = {}
    if not os.path.exists(filepath):
        print(f"[ERROR] Synonym mapping file missing: {filepath}")
        sys.exit(1)

    with open(filepath, "r", encoding="utf-8-sig", errors="replace") as f:
        _ = f.readline()
        for line in f:
            line = line.replace("\ufffd", " ").replace("\xa0", " ").strip()
            if not line:
                continue
            parts = line.split("\t")
            if len(parts) >= 2:
                syn_map[parts[0].strip()] = parts[1].strip()
    return syn_map

def main():
    syn_map = load_synonyms(SYNONYM_FILE)
    total_count = 0
    updated_count = 0

    with open(INPUT_FILE, "r", encoding="utf-8") as fin, open(OUTPUT_FILE, "w", encoding="utf-8") as fout:
        header = fin.readline()
        fout.write(header)

        for line in fin:
            parts = line.strip().split("\t")
            if len(parts) < 2:
                fout.write(line)
                continue

            total_count += 1
            feature_id, tax_str = parts[0], parts[1]
            confidence = parts[2] if len(parts) > 2 else ""

            levels = [lvl.strip() for lvl in tax_str.split(";")]
            s_idx = next((i for i, lvl in enumerate(levels) if lvl.startswith("s__")), -1)
            g_idx = next((i for i, lvl in enumerate(levels) if lvl.startswith("g__")), -1)

            is_updated = False
            if s_idx != -1:
                current_species = levels[s_idx][3:]
                if current_species in syn_map:
                    new_species = syn_map[current_species]
                    levels[s_idx] = f"s__{new_species}"
                    if g_idx != -1:
                        levels[g_idx] = f"g__{new_species.split('_')[0]}"
                    is_updated = True

            new_tax_str = ";".join(levels)
            out_line = f"{feature_id}\t{new_tax_str}\t{confidence}\n" if confidence else f"{feature_id}\t{new_tax_str}\n"
            fout.write(out_line)

            if is_updated:
                updated_count += 1

    print(f"[INFO] Synonym Synchronization: Processed {total_count}, Updated {updated_count} taxa.")

if __name__ == "__main__":
    main()