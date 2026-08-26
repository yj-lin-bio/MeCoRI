import csv
import os

INPUT_TSV = "format_tax/taxonomy_fixed.tsv"
OUTPUT_TSV = "format_tax/taxonomy_strictly_filtered.tsv"

stats = {
    "p__uncultured_archaeon": 0,
    "p__unclassified": 0,
    "p__Empty": 0,
    "c__uncultured": 0,
    "c__Empty": 0,
    "o__unclassified_Thermoplasmata": 0,
    "f__uncultured": 0,
    "f__Empty": 0,
    "g__uncultured": 0,
    "g__unidentified": 0,
    "g__Empty": 0,
    "s__cluster_archaeon": 0,
    "s__Empty": 0,
    "Total_Kept": 0,
}

if not os.path.exists(INPUT_TSV):
    raise FileNotFoundError(f"Input file not found: {INPUT_TSV}")

with open(INPUT_TSV, "r", encoding="utf-8") as fin, open(OUTPUT_TSV, "w", newline="", encoding="utf-8") as fout:
    reader = csv.reader(fin, delimiter="\t")
    writer = csv.writer(fout, delimiter="\t")

    header = next(reader)
    writer.writerow(header)

    for row in reader:
        if len(row) < 2:
            continue

        taxa = [t.strip() for t in row[1].split(";")]
        while len(taxa) < 7:
            taxa.append("")

        p, c, o, f, g, s = taxa[1], taxa[2], taxa[3], taxa[4], taxa[5], taxa[6]
        drop = False

        if "p__uncultured_archaeon" in p:
            stats["p__uncultured_archaeon"] += 1
            drop = True
        elif "p__unclassified" in p:
            stats["p__unclassified"] += 1
            drop = True
        elif p == "p__":
            stats["p__Empty"] += 1
            drop = True
        elif "c__uncultured" in c and not drop:
            stats["c__uncultured"] += 1
            drop = True
        elif c == "c__" and not drop:
            stats["c__Empty"] += 1
            drop = True
        elif "o__unclassified_Thermoplasmata" in o and not drop:
            stats["o__unclassified_Thermoplasmata"] += 1
            drop = True
        elif "f__uncultured" in f and not drop:
            stats["f__uncultured"] += 1
            drop = True
        elif f == "f__" and not drop:
            stats["f__Empty"] += 1
            drop = True
        elif "g__uncultured" in g and not drop:
            stats["g__uncultured"] += 1
            drop = True
        elif "g__unidentified" in g and not drop:
            stats["g__unidentified"] += 1
            drop = True
        elif g == "g__" and not drop:
            stats["g__Empty"] += 1
            drop = True
        elif "s__cluster archaeon" in s and not drop:
            stats["s__cluster_archaeon"] += 1
            drop = True
        elif s == "s__" and not drop:
            stats["s__Empty"] += 1
            drop = True

        if not drop:
            stats["Total_Kept"] += 1
            writer.writerow(row)

print("[INFO] Filtering Report:")
for key, val in stats.items():
    print(f"  - {key}: {val}")