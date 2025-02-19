#!/usr/bin/env Rscript
# mod_parse.r
# 01 2025 p.ashford@ucl.ac.uk
# https://github.com/paulashford/macsmaf_nf

# Module functional enrichment and annotation
# Parse a HUGO gene combined cut-off module file, e.g. parse K1_string, or K1_cpdb etc
# 14 01 2025
# Refer: 
#   macsr_nf/macsr_nf_dev/subworkflows/mod_func_enrich/mfe_README.txt
#   macsr_nf/macsr_nf_dev/subworkflows/mod_func_enrich/modferan.r

# Load required packages
suppressPackageStartupMessages({
    library(tidyverse)
})

# Get root directory using Nextflow's environment variable
root_dir <- Sys.getenv("NXF_FILE_ROOT", unset = NA)
if (is.na(root_dir)) {
    stop("NXF_FILE_ROOT environment variable not set")
}

# Get debug setting
debug <- Sys.getenv("DEBUG", unset = "false")
debug <- tolower(debug) == "true"

# Source functions file
source(file.path(root_dir, 'subworkflows', 'mod_func_enrich', 'gprofiler_enrichment_functions.r'))

# Command line Args
args <- commandArgs(trailingOnly=TRUE)
if (length(args) != 3) {
    stop(
        "Three arguments must be supplied:\n",
        "1. mod_file: a HUGO gene combined cut-off module file (e.g. for K1_string)\n",
        "2. module_prefix: prefix module naming string (e.g. 'network_modules_')\n",
        "3. output_file: name of output RDS file\n",
        call. = FALSE
    )
}

mod_file <- args[1]
module_prefix <- args[2]
output_file <- args[3]

# Validate input file exists
if (!file.exists(mod_file)) {
    stop("Input file does not exist: ", mod_file)
}

if(debug) cat("DEBUG: Parsing module file:", mod_file, "\n")

# Parse module file
tib_parsed <- parse_module_file(
    filename = mod_file, 
    split_cut_off_values = TRUE, 
    module_prefix = module_prefix
)

if(debug) {
    cat("DEBUG: Parsed module data summary:\n")
    cat("  Number of rows:", nrow(tib_parsed), "\n")
    cat("  Number of unique modules:", length(unique(tib_parsed$module)), "\n")
}

# Save parsed modules
saveRDS(tib_parsed, file = output_file, version = 2)

# Save TSV version for convenience
tsv_file <- sub("\\.rds$", ".tsv", output_file)
write_delim(
    tib_parsed,
    file = tsv_file,
    delim = "\t"
)

# Add debug information about the saved object
if(debug) {
    
    # Print debug information
    cat("DEBUG: Saved RDS file info:\n")
    cat("  File:", output_file, "\n")
    cat("  Size:", file.size(output_file), "bytes\n")
    # cat("  Structure:\n")
    # str(tib_parsed)
}
