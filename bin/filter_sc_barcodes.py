#!/usr/bin/env python3
import sys
import pandas as pd

in_file = sys.argv[1]
out_file = sys.argv[2]

# in_file = "SR03-04-Pool-2_S2.mapped.sam"
# out_file = "SR03-04-Pool-2_S2_barcodes.tsv"

print("############ Clean PCR chimerism ############\n")

# only use read header and barcode column
mapping_output = pd.read_csv(in_file, sep="\t", header=None, usecols=[0,2], comment='@', names=["readname", "barcode"])
print(f"Parsed {mapping_output.shape[0]} reads")

# get cell barcode and UMI from header
mapping_output[["read", "CID", "MID"]] = mapping_output["readname"].str.split("_", expand=True)

# only keep CB_UMI barcode combination with highest UMI count
mapping_output = mapping_output.value_counts(["barcode", "CID", "MID"]).reset_index()
print(f"Counted {mapping_output.shape[0]} cell ID - UMI - barcode combinations")

idx = mapping_output.groupby(["CID", "MID"])['count'].transform(max) == mapping_output['count']
mapping_output_max = mapping_output[idx]
print(f"Removed {mapping_output.shape[0] - mapping_output_max.shape[0]} cell ID - UMI - barcode combinations with max count, kept {mapping_output_max.shape[0]}")

# remove ties by removing all duplicated CB_UMI values
mapping_output_max_no_ties = mapping_output_max.drop_duplicates(subset=["CID", "MID"], keep=False)
# looking at duplicated 
# mapping_output_max.loc[mapping_output_max.duplicated(["CID", "MID"], keep=False).values, :].sort_values(["count", "CID", "MID"], ascending=False).head()
print(f"Removed {mapping_output_max.shape[0] - mapping_output_max_no_ties.shape[0]} cell ID - UMI - barcode combinations with count ties, kept {mapping_output_max_no_ties.shape[0]}\n\n")

# write file to pass to umi-tools count_tab
# create read name that contains a unique index, UMI and cell barcode
mapping_output_max_no_ties = mapping_output_max_no_ties.reset_index()
mapping_output_max_no_ties["read"] = mapping_output_max_no_ties["index"].astype(str) + "_" + mapping_output_max_no_ties["MID"] + "_" + mapping_output_max_no_ties["CID"]

mapping_output_max_no_ties[["read", "barcode"]].to_csv(out_file, index=False, sep="\t", header=False)

# mapping_counts = mapping_output_max_no_ties[["CID", "barcode"]].value_counts().reset_index()
# print(f"Counted {mapping_counts['barcode'].unique().shape[0]} barcodes in {mapping_counts['CID'].unique().shape[0]} cells")
# print(f"In {mapping_counts.shape[0]} cell ID - barcode combinations")

# mapping_counts = mapping_counts.rename(columns={"barcode": "gene", "CID": "cell"})

# mapping_counts[["gene", "cell", "count"]].to_csv(out_file, index=False, sep="\t")
