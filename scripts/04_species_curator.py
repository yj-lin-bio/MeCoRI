import os
import re

INPUT_FILE = "format_tax/taxonomy_strictly_filtered.tsv"
OUTPUT_FILE = "format_tax/taxonomy_curated_strict.tsv"

def curate_taxonomy_string(tax_str):
    levels = [lvl.strip() for lvl in tax_str.split(";")]
    genus_str = ""
    original_genus = ""
    species_idx = -1

    for i, lvl in enumerate(levels):
        if lvl.startswith("g__"):
            original_genus = lvl[3:].strip()
            genus_str = re.sub(r"_[A-Z]$", "", original_genus)
            levels[i] = f"g__{genus_str}"
        elif lvl.startswith("s__"):
            species_idx = i
            break

    if species_idx == -1 or not genus_str:
        return ";".join(levels)

    raw_species = levels[species_idx][3:].strip().replace(" ", "_")
    if original_genus and original_genus != genus_str:
        if raw_species.startswith(original_genus + "_"):
            raw_species = raw_species.replace(original_genus + "_", genus_str + "_", 1)
        elif raw_species == original_genus:
            raw_species = genus_str

    parts = [p for p in raw_species.split("_") if p]
    if not parts:
        raw_species = "sp."
    else:
        if parts[0] != genus_str:
            parts.insert(0, genus_str)
        if len(parts) >= 2:
            epithet = parts[1]
            if re.match(r"^[A-Z]$", epithet) or epithet in ["sp.", "sp"]:
                raw_species = f"{parts[0]}_sp."
            elif re.match(r"^sp\d+[a-zA-Z0-9]*$", epithet):
                raw_species = f"{parts[0]}_sp."
            else:
                raw_species = f"{parts[0]}_{epithet}"
        else:
            raw_species = f"{parts[0]}_sp."

    levels[species_idx] = f"s__{raw_species}"
    return ";".join(levels)

def main():
    if not os.path.exists(INPUT_FILE):
        raise FileNotFoundError(f"Input file not found: {INPUT_FILE}")

    kept_count = 0
    dropped_count = 0

    with open(INPUT_FILE, "r", encoding="utf-8") as fin, open(OUTPUT_FILE, "w", encoding="utf-8") as fout:
        header = fin.readline()
        fout.write(header)

        for line in fin:
            parts = line.strip("\n").split("\t")
            if len(parts) >= 2:
                feature_id = parts[0]
                curated_tax = curate_taxonomy_string(parts[1])

                if curated_tax.strip().endswith("sp."):
                    dropped_count += 1
                    continue

                kept_count += 1
                if len(parts) > 2:
                    fout.write(f"{feature_id}\t{curated_tax}\t{parts[2]}\n")
                else:
                    fout.write(f"{feature_id}\t{curated_tax}\n")
            else:
                fout.write(line)

    print(f"[INFO] Strict Curation Complete: Kept {kept_count}, Dropped {dropped_count} uninformative entries.")

if __name__ == "__main__":
    main()