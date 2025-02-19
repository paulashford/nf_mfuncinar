#!/usr/bin/env Rscript
# rank_annot.r
# 20 01 2025
# Rank and annotate enrichment results
#	1) Combine enrcihment and GO SLIM results
#	2) Rank enrichment results
#	3) Annotate enrichment results
#	4) Save results

# Load required libraries
library(tidyverse)
library(data.table)
library(optparse)

# Get root directory using Nextflow's environment variable
root_dir <- Sys.getenv("NXF_FILE_ROOT", unset = NA)
if (is.na(root_dir)) {
    stop("NXF_FILE_ROOT environment variable not set")
}

# Source stats functions(which local to rank_annot/, not mod_func_enrich/)
source(file.path(root_dir, 'subworkflows', 'rank_annot', 'stats_functions.R'))

# Get debug setting from environment variable
debug <- Sys.getenv("DEBUG", unset = "false")
debug <- tolower(debug) == "true"

# Filter out very general terms and rank enrichment results
filter_cut_off_rank_enrichment <- function(enrichment_results, max_term_size = 0.05, perc_rank_cutoff = 0.25) {
	enrichment_results <- enrichment_results %>%
		# filter out very general terms
		group_by(source) %>%
		filter(term_size < (max_term_size * effective_domain_size)) %>%
		# add ranks
		group_by(network_method, network_db, network_cutoff, experiment_info, module) %>%
		mutate(perc_rank = percent_rank(p_value)) %>%
		mutate(cumelative_dist = cume_dist(p_value))
	
	# filter out based on percentile rank cutoff
	enrichment_results <- enrichment_results %>%
		filter(perc_rank <= perc_rank_cutoff)
	
	return(enrichment_results)
}

# Standardise module column names and types
standardise_module_column <- function(enrichment_results) {
	if ("func_module_number" %in% colnames(enrichment_results)) {
		enrichment_results <- enrichment_results %>%
			mutate(func_module_number = as.numeric(func_module_number)) %>%
			rename(module = func_module_number)
	} else if (!"module" %in% colnames(enrichment_results)) {
		stop("Enrichment results must have either 'func_module_number' or 'module' column")
	} else {
		enrichment_results <- enrichment_results %>%
			mutate(module = as.numeric(module))
	}
	return(enrichment_results)
}

# Add p-value ranking within groups
add_pval_rank <- function(enrichment_results) {
	enrichment_results <- enrichment_results %>%
		group_by(network_method, network_db, network_cutoff, experiment_info, module) %>%
		mutate(pval_rank = rank(p_value, ties.method = "average")) %>%
		arrange(network_method, network_db, network_cutoff, experiment_info, module, pval_rank)
	return(enrichment_results)
}

# Combine enrichment results with GO slim results
comb_slim <- function(enrichment_results, goslims_results) {
	# enforce numeric module numbers
	enrichment_results <- enrichment_results %>%
		mutate(module = as.numeric(module))
	goslims_results <- goslims_results %>%
		mutate(func_module_number = as.numeric(func_module_number))
	
	# Perform the join
	comb_slim <- left_join(
		enrichment_results,
		goslims_results,
		by = c("module" = "func_module_number"),
		na_matches = 'never',
		keep = FALSE
	)
	return(comb_slim)
}

# Aggregate results by top-k lists
# aggregate_by_topk_lists <- function(enrichment_results, sources = c("GO:BP", "KEGG", "REAC"), agg_type = "MC3") {
# 	log_info("Aggregating top-k lists with sources: {paste(sources, collapse=', ')} and type: {agg_type}")
	
# 	# Get top k terms for each module
# 	topk_lists <- enrichment_results %>%
# 		group_by(module, source) %>%
# 		slice_min(order_by = p_value, n = 10) %>%
# 		ungroup()
	
# 	# Count occurrences of each term across modules
# 	term_counts <- topk_lists %>%
# 		group_by(term_id, term_name, source) %>%
# 		summarise(
# 			n_modules = n_distinct(module),
# 			modules = paste(sort(unique(module)), collapse = ";"),
# 			mean_rank = mean(pval_rank),
# 			.groups = "drop"
# 		) %>%
# 		filter(n_modules >= 2) %>%
# 		arrange(source, desc(n_modules), mean_rank)
	
# 	log_info("Found {nrow(term_counts)} terms appearing in at least 2 modules")
	
# 	return(term_counts)
# }

option_list <- list(
	make_option("--enrichment_file", type="character", help="Path to enrichment results file"),
	make_option("--goslim_file", type="character", help="Path to GO SLIM results file"),
	make_option("--modules_file", type="character", help="Path to modules file with gene lists"),
	make_option("--output_file", type="character", help="Output file path"),
	make_option("--max_term_size", type="numeric", default=0.05, help="Maximum term size as fraction of effective domain [default=0.05]"),
	make_option("--perc_rank_cutoff", type="numeric", default=0.25, help="Percentile rank cutoff [default=0.25]"),
	make_option("--agg_type", type="character", default="MC3", help="TopKLists aggregation type [default=MC3]"),
	make_option("--sources", type="character", default="GO:BP,KEGG,REAC", 
				help="Comma-separated list of sources to aggregate [default=GO:BP,KEGG,REAC]")
)

opt <- parse_args(OptionParser(option_list=option_list))

main <- function() {
	# Read input files
	enrichment_results <- readRDS(opt$enrichment_file)
	goslim_results <- read_tsv(opt$goslim_file)
	modules_data <- readRDS(opt$modules_file)
	
	# Print column names for debugging
	if(debug) {
		cat("DEBUG: Enrichment results columns:", paste(colnames(enrichment_results), collapse=", "), "\n")
		cat("DEBUG: GO slim results columns:", paste(colnames(goslim_results), collapse=", "), "\n")
		cat("DEBUG: Modules data columns:", paste(colnames(modules_data), collapse=", "), "\n")
	}
	
	# Extract cutoff from enrichment results
	cutoff <- unique(enrichment_results$network_cutoff)
	if (length(cutoff) != 1) {
		stop("Expected exactly one cutoff value in enrichment results")
	}
	
	# Standardise module column early
	enrichment_results <- standardise_module_column(enrichment_results)
	
	# Convert list column to semicolon-separated strings, filtering by cutoff
	gene_lists <- modules_data %>%
		filter(cut_off_value == cutoff) %>%
		rowwise() %>%
		mutate(genes = paste(unlist(genelist), collapse = ";")) %>%
		select(module_number, genes) %>%
		mutate(module_number = as.numeric(module_number))
	
	# Add p-value rankings
	enrichment_results <- add_pval_rank(enrichment_results)
	
	# Combine enrichment with GO SLIM results first
	combined_results <- comb_slim(enrichment_results, goslim_results)
	
	# Then add gene lists, matching on module number
	combined_results <- combined_results %>%
		left_join(gene_lists, by = c("module" = "module_number"))
	
	# Filter and rank results
	ranked_results <- filter_cut_off_rank_enrichment(
		combined_results, 
		max_term_size = opt$max_term_size,
		perc_rank_cutoff = opt$perc_rank_cutoff
	)
	
	# Parse sources for aggregation
	sources <- strsplit(opt$sources, ",")[[1]]
	
	# Run TopKLists aggregation
	cat("INFO: Running TopKLists aggregation with type", opt$agg_type, "\n")
	aggregated_results <- aggregate_by_topk_lists(
		ranked_results,
		sources = sources,
		agg_type = opt$agg_type
	)

	# Remove rows if not a rank 1 term...
	aggregated_results_rank1 	<- filter(aggregated_results, 
									(term_id == top_go) | (term_id == top_kegg) | (term_id == top_reac) 
								)	

	# Add the topklist rank1 to the main resultls
	rank_agg_final 	<- inner_join( 	ranked_results,
										select(aggregated_results_rank1, -c( p_value, mcc, term_name ) ),
										by = c( "network_method" = "network_method",
												"network_db" = "network_db",
												"network_cutoff" = "network_cutoff",
												"experiment_info" = "experiment_info",
												"module" = "module", 
												"source" = "source",
												"term_id" = "term_id"
											)
							)

	# Write results with debug info
	if(debug) cat("DEBUG: Writing ranked results to", opt$output_file, "\n")
	write_tsv(ranked_results, opt$output_file)
	
	# Write aggregated results - use consistent naming pattern for Nextflow
	agg_output <- sub("_ranked_annotated.tsv$", "_topk_aggregated.tsv", opt$output_file)
	if(debug) cat("DEBUG: Writing aggregated results to", agg_output, "\n")
	write_tsv(aggregated_results, agg_output)
	
	# Write rank1 results
	rank1_output <- sub("_ranked_annotated.tsv$", "_rank1_aggregated.tsv", opt$output_file)
	if(debug) cat("DEBUG: Writing rank1 results to", rank1_output, "\n")
	write_tsv(aggregated_results_rank1, rank1_output)
	
	# Write final aggregated results
	final_output <- sub("_ranked_annotated.tsv$", "_rank_agg_final.tsv", opt$output_file)
	if(debug) cat("DEBUG: Writing final aggregated results to", final_output, "\n")
	write_tsv(rank_agg_final, final_output)
	
	if(debug) cat("DEBUG: Rank annotation process completed\n")
}

# Run main function with error handling
tryCatch({
	main()
}, error = function(e) {
	cat("ERROR:", conditionMessage(e), "\n")
	quit(status = 1)
})