# v02
# 20 02 2025

# Regenerated parsed modules after fixing 'bugs' in:
# macsr_nf_dev/bin/process_network_modules.sh
# Part of issue was the non-standard input module form (e.g. spurious 2nd column, sometimes, nostly not, either '1' or '1.0')
# Special character stripping added

# GENE COUNT CHECKS: /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/bin/test_count_genes.sh
# ALSO module count checks: /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/bin/test_process_network_modules.sh

# Run: change script method db as needed
cd /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/bin
./run_process_network_modules.sh

# COPY ENSGs
cp /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/compiled_module_datasets/v02/pre_processed_networks/*R1*.dat	\
	/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/compiled_module_datasets/v02/converted_networks/ensembl_gene_id
cp /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/compiled_module_datasets/v02/pre_processed_networks/*M1*.dat \
	/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/compiled_module_datasets/v02/converted_networks/ensembl_gene_id
cp /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/compiled_module_datasets/v02/pre_processed_networks/network_modules_K1_cpdb_parsed.dat \
	/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/compiled_module_datasets/v02/converted_networks/ensembl_gene_id

# parse prev K1 ID conv files too
cd /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/bin/
./process_parsed_file.sh \
	/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/previous_versions/v1/converted_networks/ad_hoc_id_conversion/network_modules_K1_humanbase_converted_original_to_ensembl_gene_id.dat > \
	/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/compiled_module_datasets/v02/converted_networks/ensembl_gene_id/network_modules_K1_humanbase_parsed.dat

./process_parsed_file.sh \
	/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/previous_versions/v1/converted_networks/ad_hoc_id_conversion/network_modules_K1_string_converted_original_to_Gene_stable_ID.dat > \
	/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/compiled_module_datasets/v02/converted_networks/ensembl_gene_id/network_modules_K1_string_parsed.dat

# remember to remove any moduels with < 3 genes from *ID CONVERTED* K1 ( as per bin/process_network_modules.sh)
cd /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/compiled_module_datasets/v02/converted_networks/ensembl_gene_id
mkdir -p k1_no_colnum_filter
mv network_modules_K1_cpdb_parsed.dat k1_no_colnum_filter/
mv network_modules_K1_string_parsed.dat k1_no_colnum_filter/
mv network_modules_K1_humanbase_parsed.dat k1_no_colnum_filter/

awk -F'\t' 'NF >3' k1_no_colnum_filter/network_modules_K1_cpdb_parsed.dat > network_modules_K1_cpdb_parsed.dat
awk -F'\t' 'NF >3' k1_no_colnum_filter/network_modules_K1_string_parsed.dat > network_modules_K1_string_parsed.dat
awk -F'\t' 'NF >3' k1_no_colnum_filter/network_modules_K1_humanbase_parsed.dat > network_modules_K1_humanbase_parsed.dat

# ENSEMBLE GENE CONV IDS
cd /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/compiled_module_datasets/v02/converted_networks/ensembl_gene_id
wc -l *
#     4043 network_modules_K1_cpdb_parsed.dat
#     1457 network_modules_K1_humanbase_parsed.dat
#     4638 network_modules_K1_string_parsed.dat
#     5178 network_modules_M1_cpdb_parsed.dat
#      676 network_modules_M1_humanbase_parsed.dat
#     1343 network_modules_M1_string_parsed.dat
#     3674 network_modules_R1_cpdb_parsed.dat
#      589 network_modules_R1_humanbase_parsed.dat
#     1191 network_modules_R1_string_parsed.dat
#    22789 total
wc -l k1_no_colnum_filter/*
    # 4043 k1_no_colnum_filter/network_modules_K1_cpdb_parsed.dat
    # 1869 k1_no_colnum_filter/network_modules_K1_humanbase_parsed.dat
    # 5753 k1_no_colnum_filter/network_modules_K1_string_parsed.dat

# PRE PROC NETWORKS
cd /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/compiled_module_datasets/v02/pre_processed_networks
wc -l *
# 	  4043 network_modules_K1_cpdb_parsed.dat
#     1483 network_modules_K1_humanbase_parsed.dat
#     4701 network_modules_K1_string_parsed.dat
#     5178 network_modules_M1_cpdb_parsed.dat
#      676 network_modules_M1_humanbase_parsed.dat
#     1343 network_modules_M1_string_parsed.dat
#     3674 network_modules_R1_cpdb_parsed.dat
# #     589 network_modules_R1_humanbase_parsed.dat
#     1191 network_modules_R1_string_parsed.dat
#   22878 total

wc -l k1_no_colnum_filter/*

#     6736 k1_no_colnum_filter/network_modules_K1_cpdb_parsed.dat
#     1869 k1_no_colnum_filter/network_modules_K1_humanbase_parsed.dat
#     5753 k1_no_colnum_filter/network_modules_K1_string_parsed.dat
#    14358 total


# -----------------------------------------------------------------------------------------------

# Gene counts test summary 21 02 2025

# -----------------------------------------------------------------------------------------------

export SOURCE_NETWORKS_DIR='/Users/ash/Dropbox/bioinf/MACSMAF/datasets/d024'
export PRE_PROC_NETWORK_DIR='/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/compiled_module_datasets/v02/pre_processed_networks'
export CONVERTED_NETWORKS_DIR='/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/compiled_module_datasets/v02/converted_networks/ensembl_gene_id'
export BIN_DIR='/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/bin'

# -----------------------------------------------------------------------------------------------

# RUN TEST

# 1. Check gene counts
${BIN_DIR}/test_count_genes.sh "${SOURCE_NETWORKS_DIR}" 'M1' 'cpdb'