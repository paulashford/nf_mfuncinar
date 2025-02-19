#!/usr/bin/env Rscript
# run_gp.r
# Module functional enrichment and annotation using g:Profiler
# Performs enrichment analysis on pre-processed module data
# 14 01 2025
# refer: 
#	macsr_nf/macsr_nf_dev/subworkflows/mod_func_enrich/mfe_README.txt
# 	macsr_nf/macsr_nf_dev/subworkflows/mod_func_enrich/modferan.r

suppressPackageStartupMessages({
    library(tidyverse)
    library(gprofiler2)  # Add explicit library load
})

# Get debug setting
debug <- Sys.getenv("DEBUG", unset = "false")
debug <- tolower(debug) == "true"

# Parse command line arguments
args <- commandArgs(trailingOnly=TRUE)
if (length(args) != 6) {
    stop(
        "Six arguments must be supplied:\n",
        "1. pre_proc_mod_file: pre-processed module file (RDS)\n", 
        "2. filter_cut_off: network cut-off value to filter on\n",
        "3. sources: gProfiler databases to use\n",
        "4. signif_level: significance level\n",
        "5. exclude_iea: exclude IEA terms\n",
        "6. out_file: output filename\n",
        call. = FALSE
    )
}

# Assign arguments to named variables
pre_proc_mod_file <- args[1]
filter_cut_off <- args[2]
sources <- args[3]
signif_level <- as.numeric(args[4])
exclude_iea <- as.logical(args[5])
out_file <- args[6]

# Validate inputs
if (!file.exists(pre_proc_mod_file)) {
    stop("Input file does not exist: ", pre_proc_mod_file)
}

if (is.na(signif_level) || signif_level <= 0 || signif_level > 1) {
    stop("Significance level must be between 0 and 1")
}

# Get root directory using Nextflow's environment variable
root_dir <- Sys.getenv("NXF_FILE_ROOT", unset = NA)
if (is.na(root_dir)) {
    stop("NXF_FILE_ROOT environment variable not set")
}

# Source functions file
source(file.path(root_dir, 'subworkflows', 'mod_func_enrich', 'gprofiler_enrichment_functions.r'))

# Load and process module data
if (file.exists(pre_proc_mod_file)) {
    cat("Loading RDS file:", pre_proc_mod_file, "\n")
    cat("File size:", file.size(pre_proc_mod_file), "bytes\n")
    
    tryCatch({
        tib_parsed <- readRDS(pre_proc_mod_file)
        cat("Successfully loaded RDS file\n")
    }, error = function(e) {
        stop("Failed to read RDS file: ", e$message, "\n",
             "File path: ", pre_proc_mod_file, "\n",
             "File exists: ", file.exists(pre_proc_mod_file))
    })
} else {
    stop("Input RDS file does not exist: ", pre_proc_mod_file)
}

# Add debug output before gprofiler query
if(debug) {
    print("DEBUG: Converting module tibble to gprofiler query")
    print(paste("DEBUG: Filter cutoff value:", filter_cut_off))
    print(paste("DEBUG: Input tibble dimensions:", nrow(tib_parsed), "x", ncol(tib_parsed)))
}

gp_qry <- convert_module_tibble_to_gp_query(tib_parsed, filter_cut_off = filter_cut_off)

# Check if query is empty and exit gracefully
if (length(gp_qry) == 0) {
    if(debug) cat("WARNING: No valid modules to process - skipping g:Profiler analysis\n")
    file.create(out_file)
    quit(status = 0)
}

# Add debug output after conversion
if(debug) {
    print("DEBUG: Conversion complete")
    print(paste("DEBUG: Number of queries generated:", length(gp_qry)))
}

# Add batch size parameter and progress tracking
BATCH_SIZE <- 50
total_queries <- length(gp_qry)
total_batches <- ceiling(total_queries / BATCH_SIZE)

# Initialize empty list for results
all_results <- list()

# Process in batches with error handling
for (batch in 1:total_batches) {
    start_idx <- ((batch - 1) * BATCH_SIZE) + 1
    end_idx <- min(batch * BATCH_SIZE, total_queries)
    
    cat(sprintf("\nProcessing batch %d of %d (modules %d to %d)\n", 
                batch, total_batches, start_idx, end_idx))
    
    # Get current batch of queries
    batch_queries <- gp_qry[start_idx:end_idx]
    
    # Process each query in the batch with error handling
    batch_results <- tryCatch({
        run_gprofiler_enrichment(
            batch_queries,
            sig_level = signif_level,
            sources = strsplit(sources, ",")[[1]], 
            exclude_go_iea = exclude_iea,
            multq = FALSE 
        )
    }, error = function(e) {
        cat(sprintf("ERROR in batch %d: %s\n", batch, e$message))
        return(NULL)
    })
    
    if (!is.null(batch_results)) {
        all_results[[batch]] <- batch_results
        cat(sprintf("Batch %d completed successfully\n", batch))
    }
}

# Combine results
if (length(all_results) > 0) {
    # Combine all batch results
    gp_enrich <- do.call(rbind, lapply(all_results, function(x) x$result))
    
    # Save results
    saveRDS(gp_enrich, file = out_file)
    cat(sprintf("\nSaved results to %s\n", out_file))
    
    # Debug output
    if (Sys.getenv("DEBUG") == "true") {
        write_delim(
            gp_enrich,
            file = paste0(out_file, ".tsv"),
            delim = "\t"
        )
    }
} else {
    cat("WARNING: No enrichment results were generated\n")
    # Create empty output file
    saveRDS(data.frame(), file = out_file)
}
# Print summary statistics
cat("\nSummary:\n")
cat(sprintf("Total queries processed: %d\n", total_queries))
cat(sprintf("Successful batches: %d of %d\n", length(all_results), total_batches))

