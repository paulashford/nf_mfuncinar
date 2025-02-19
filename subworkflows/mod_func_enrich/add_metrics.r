#!/usr/bin/env Rscript
# add_metrics.r
# 01 2025 p.ashford@ucl.ac.uk
# https://github.com/paulashford/macsmaf_nf

# Add classification metrics and MCC to g:Profiler enrichment results
# 17 01 2025
# Called from main.nf; uses add_tp_tn_fp_fn_mcc from gprofiler_enrichment_functions.r

# Load required libraries
library(tidyverse)

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3) {
    stop("Required arguments: input_file output_rds output_tsv")
}

input_file <- args[1]
output_rds <- args[2]
output_tsv <- args[3]

# Get root directory using Nextflow's environment variable
root_dir <- Sys.getenv("NXF_FILE_ROOT", unset = NA)
if (is.na(root_dir)) {
    stop("NXF_FILE_ROOT environment variable not set")
}

# Source functions file
source(file.path(root_dir, "subworkflows", "mod_func_enrich", "gprofiler_enrichment_functions.r"))

# Read the input data
enrichment_data <- readRDS(input_file)

# Add the metrics using the existing function from gprofiler_enrichment_functions.r
enrichment_with_metrics <- add_tp_tn_fp_fn_mcc(enrichment_data, inc_mcc = TRUE)

# Save the results in both formats
saveRDS(enrichment_with_metrics, file = output_rds)
write_tsv(enrichment_with_metrics, file = output_tsv) 