#!/bin/bash

# COUNT GENES IN VARIOUS NETWORKS FOR COMPARISON AND TESTING
# 21 02 25

export SOURCE_NETWORKS_DIR='/Users/ash/Dropbox/bioinf/MACSMAF/datasets/d024'
export PRE_PROC_NETWORK_DIR='/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/compiled_module_datasets/v02/pre_processed_networks'
export CONVERTED_NETWORKS_DIR='/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/compiled_module_datasets/v02/converted_networks/ensembl_gene_id'
export BIN_DIR='/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/bin'


# SOURCE NETWORKS

echo "SOURCE NETWORKS using M1"
# 1. Check gene counts
${BIN_DIR}/test_count_genes.sh "${SOURCE_NETWORKS_DIR}/M1" 'M1' 'cpdb'

# 2. Check gene counts
${BIN_DIR}/test_count_genes.sh "${SOURCE_NETWORKS_DIR}/M1" 'M1' 'string' '1'

# 3. Check gene counts
${BIN_DIR}/test_count_genes.sh "${SOURCE_NETWORKS_DIR}/M1" 'M1' 'humanbase' '1'

echo "--------------------------------"

echo "SOURCE NETWORKS using R1"
# 4. Check gene counts
${BIN_DIR}/test_count_genes.sh "${SOURCE_NETWORKS_DIR}/R1" 'R1' 'cpdb'

# 5. Check gene counts
${BIN_DIR}/test_count_genes.sh "${SOURCE_NETWORKS_DIR}/R1" 'R1' 'string' '1'

# 5. Check gene counts
${BIN_DIR}/test_count_genes.sh "${SOURCE_NETWORKS_DIR}/R1" 'R1' 'humanbase' '1'

echo "--------------------------------"

echo "SOURCE NETWORKS using K1"
# 1. Check gene counts
${BIN_DIR}/test_count_genes.sh "${SOURCE_NETWORKS_DIR}/K1" 'K1' 'cpdb'

# 2. Check gene counts
${BIN_DIR}/test_count_genes.sh "${SOURCE_NETWORKS_DIR}/K1" 'K1' 'string' '1'

# 3. Check gene counts
${BIN_DIR}/test_count_genes.sh "${SOURCE_NETWORKS_DIR}/K1" 'K1' 'humanbase' '1'


# echo "--------------------------------"

# echo "PRE-PROCESSED NETWORKS using M1"
# # 1. Check gene counts
# ${BIN_DIR}/test_count_genes.sh "${PRE_PROC_NETWORK_DIR}" 'M1' 'cpdb'

# echo "--------------------------------"

# echo "PRE-PROCESSED NETWORKS using R1"
# # 1. Check gene counts
# ${BIN_DIR}/test_count_genes.sh "${PRE_PROC_NETWORK_DIR}" 'R1' 'cpdb'


