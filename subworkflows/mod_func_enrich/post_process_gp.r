#!/usr/bin/env Rscript
# post_process_gp.r
# Post-process g:Profiler enrichment results using existing function

suppressPackageStartupMessages({
    library(tidyverse)
})

# Parse command line arguments
args <- commandArgs(trailingOnly=TRUE)
if (length(args) != 5) {
    stop(
        "Five arguments must be supplied:\n",
        "1. gprofiler_results: g:Profiler results file (RDS)\n",
        "2. method: network method (e.g. K1)\n",
        "3. db: network database (e.g. cpdb)\n",
        "4. cutoff: network cutoff value\n",
        "5. out_file: output filename\n",
        call. = FALSE
    )
}

# Assign arguments to named variables
gprofiler_results_file <- args[1]
method <- args[2]
db <- args[3]
cutoff <- args[4]
out_file <- args[5]

# Get root directory using Nextflow's environment variable
root_dir <- Sys.getenv("NXF_FILE_ROOT", unset = NA)
if (is.na(root_dir)) {
    stop("NXF_FILE_ROOT environment variable not set")
}

# Source functions file
source(file.path(root_dir, 'subworkflows', 'mod_func_enrich', 'gprofiler_enrichment_functions.r'))

# Get debug setting from environment variable
debug_mode <- as.logical(Sys.getenv("DEBUG", "FALSE"))

# Load and process results
if (file.exists(gprofiler_results_file)) {
    if(debug_mode) cat("Loading RDS file:", gprofiler_results_file, "\n")
    
    tryCatch({
        gp_results <- readRDS(gprofiler_results_file)
        if(debug_mode) cat("Successfully loaded g:Profiler results\n")
        
        # Use existing post-processing function with debug flag
        processed_results <- post_process_gprofiler_enrichment(gp_results, debug = debug_mode)
        
        # Add network metadata
        processed_results <- processed_results %>%
            mutate(
                network_method = method,
                network_db = db,
                network_cutoff = as.numeric(cutoff)
            ) %>%
            relocate(network_method, network_db, network_cutoff, .before = everything())
        
        # Save results
        saveRDS(processed_results, file = out_file)
        if(debug_mode) cat("Saved processed results to:", out_file, "\n")
        
    }, error = function(e) {
        if(debug_mode) cat("ERROR processing results:", e$message, "\n")
        stop(e)
    })
} else {
    stop("Input RDS file does not exist: ", gprofiler_results_file)
} 