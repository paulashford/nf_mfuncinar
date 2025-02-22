#!/usr/bin/env bash
# run_workflows.sh
export NF_WORKFLOW_DIR=/Users/ash/git/macsmaf/macsr_nf
export NF_CONFIG="${NF_WORKFLOW_DIR}/macsr_nf_dev/conf/base.config"
export NXF_FILE_ROOT="${NF_WORKFLOW_DIR}/macsr_nf_dev"
export DEBUG='false'
source "${NXF_FILE_ROOT}/venv/bin/activate"
# source venv/bin/activate
nextflow run ${NF_WORKFLOW_DIR}/macsr_nf_dev/workflows/macs_nf_dev.nf -c "${NF_CONFIG}"
# nextflow run ${NF_WORKFLOW_DIR}/macsr_nf_dev/workflows/macs_nf_dev.nf -c "${NF_CONFIG}" -resume


# id_conversion ad-hoc
# export proj_root=~/git/macsmaf/macsr_nf/macsr_nf_dev
# export NF_CONFIG="${proj_root}/conf/base.config"
# source "${proj_root}/venv/bin/activate"
# cd ${proj_root}/workflows
# nextflow run id_conversion_ad_hoc.nf -c "${NF_CONFIG}"

# redundant NXF_ROOT_DIR == NXF_FILE_ROOT - see: https://www.nextflow.io/docs/latest/reference/env-vars.html#nextflow-settings
# export NXF_ROOT_DIR="${NF_WORKFLOW_DIR}/macsr_nf_dev"	
# note this is the macsr_nf_dev directory and subworkflow etc scripts should use relative paths
# export NXF_SCRIPT_DIR=/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev

# if need rds to tsv 
# example: 
# export input_rds=/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/enrichment/K1_cpdb_0.9_enrichment_with_metrics.rds
# export output_tsv=/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/enrichment/K1_cpdb_0.9_enrichment_with_metrics.tsv
# Rscript ${NF_WORKFLOW_DIR}/macsr_nf_dev/script/rds_to_tsv.r $input_rds $output_tsv

# Run specific workflows /test workflows

# nextflow run ${NF_WORKFLOW_DIR}/macsr_nf_dev/workflows/macs_nf_dev.nf -c "${NF_CONFIG}"
# nextflow run ${NF_WORKFLOW_DIR}/macsr_nf_dev/workflows/macs_nf_dev.nf -c "${NF_CONFIG}" -resume
#nextflow run ${NF_WORKFLOW_DIR}/macsr_nf_dev/workflows/macs_nf_dev_test_go_slim.nf -c "${NF_CONFIG}"
# nextflow run ${NF_WORKFLOW_DIR}/macsr_nf_dev/workflows/macs_nf_dev_test_go_slim_rank.nf -c "${NF_CONFIG}"

# TEST WORKFLOWS
# nextflow run "${NF_WORKFLOW_DIR}/macsr_nf_dev/workflows/macs_nf_dev.nf" -c "${NF_CONFIG}" -entry test_network_processing

# TEST bin scripts
# export NF_DATA_DIR=/Users/ash/Dropbox/bioinf/MACSMAF/datasets/d024
# export method='M1'
# export db='humanbase'
# export input_dir='input_files'
# ## use redirect: export output_file='network-modules-cpdb-humanbase-0.9.dat'
# ./${NF_WORKFLOW_DIR}/macsr_nf_dev/bin/process_network_modules.sh "$method" "$db"


# nextflow run ${NF_WORKFLOW_DIR}/macsr_nf_dev/workflows/macs_nf_dev.nf -entry test_network_processing -c "${NF_CONFIG}"

# # id conversion Feb2025
# export proj_root=~/git/macsmaf/macsr_nf/macsr_nf_dev
# export NF_CONFIG="${proj_root}/conf/base.config"
# nextflow run "${proj_root}/subworkflows/id_conversion/id_conversion_ad_hoc.nf" -c "${NF_CONFIG}"

# id_conversion NextFlow submodule testing:
# cd /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/subworkflows/id_conversion
# export NF_CONFIG=/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/conf/base.config
# nextflow run main.nf -c "${NF_CONFIG}"
