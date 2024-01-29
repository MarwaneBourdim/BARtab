#!/usr/bin/env python3

import pandas as pd
# import os
import sys

infile = sys.argv[1]
# infile = "/dawson_genomics/Projects/pfizer_lung_cancer/SR03_04/scripts/work/fb/73fe746ce7d69ae46b7239a3cc0aef/SR03-04-Pool-1_S1_unmapped_starcode.tsv"
outfile = sys.argv[2]
# length of cell barcode and UMI together
cb_umi_length = int(sys.argv[3])
# cb_umi_length = 28
# length of only the cell barcode
cb_length = int(sys.argv[4])
# cb_length = 16

print("############ Clean PCR chimerism ############\n")

# read starcode output into dataframe
starcode_output = pd.read_csv(infile, sep="\t", header=None, names=["sequence", "count"])
print(f"Parsed {starcode_output.shape[0]} cell ID-UMI-barcode combinations")

# split sequences into CB_UMI and lineage barcode
starcode_output['CB_UMI'] = starcode_output['sequence'].str[0:cb_umi_length]

# only keep CB_UMI barcode combination with highest UMI count
idx = starcode_output.groupby(['CB_UMI'])['count'].transform(max) == starcode_output['count']
starcode_output_max = starcode_output[idx]
print(f"Removed {starcode_output.shape[0] - starcode_output_max.shape[0]} cell ID-UMI-barcode combinations with max count, kept {starcode_output_max.shape[0]}")

# remove ties by removing all duplicated CB_UMI values
starcode_output_max_no_ties = starcode_output_max.drop_duplicates(subset=['CB_UMI'], keep=False)
print(f"Removed {starcode_output_max.shape[0] - starcode_output_max_no_ties.shape[0]} cell ID-UMI-barcode combinations with count ties, kept {starcode_output_max_no_ties.shape[0]}")

# write file to pass to umi-tools count_tab
# create read name that contains a unique index, UMI and cell barcode
starcode_output_max_no_ties = starcode_output_max_no_ties.reset_index()
starcode_output_max_no_ties["barcode"] = starcode_output_max_no_ties["sequence"].str[cb_umi_length:]
# it is essential to order by barcode before umi-tools count_tab
starcode_output_max_no_ties = starcode_output_max_no_ties.sort_values("barcode")
starcode_output_max_no_ties["read"] = starcode_output_max_no_ties["index"].astype(str) + "_" + starcode_output_max_no_ties["CB_UMI"].str[cb_length:cb_umi_length] + "_" + starcode_output_max_no_ties["CB_UMI"].str[0:cb_length]

starcode_output_max_no_ties[["read", "barcode"]].to_csv(outfile, index=False, sep="\t", header=False)

# # create columns with just cell barcode and lineage barcode, remove all other columns
# starcode_output_max_no_ties["cell"] = starcode_output_max_no_ties["CB_UMI"].str[0:cb_length]
# starcode_output_max_no_ties["gene"] = starcode_output_max_no_ties["sequence"].str[cb_umi_length:]
# starcode_output_max_no_ties = starcode_output_max_no_ties[["cell", "gene"]]

# starcode_counts = starcode_output_max_no_ties.value_counts().reset_index()

# starcode_counts[["gene", "cell", "count"]].to_csv(outfile, index=False, sep="\t")
