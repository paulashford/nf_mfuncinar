#!/usr/bin/env Rscript
# gprofiler_enrichment_functions.r
# 01 2025 p.ashford@ucl.ac.uk
# https://github.com/paulashford/macsmaf_nf

# Programmatic use of g:Profiler parsing / enrichment functions
# based on: experiments/e019/gprofiler-multi/gprofiler_functions.R
# 24 05 2023
# 19 12 2024 : handle combined modules file which includes all cut-off values; update to later tidyverse syntax (separate -> separate_wider_delim etc)
# Read module file and convert to named list format appropriate for using directly in gost
parse_module_file <- function( filename, split_cut_off_values = FALSE, module_prefix = "" ){
	require(readr)
	require(tidyr)
	require(dplyr)
	require(purrr)
	require(stringr)

	# read Monet module file into characterlines as character vector (don"t want df/dt/tibble yet as unequal num genes per module - ie not relational/"tidy")
	modules <- read_lines( file.path(filename) )

	# conv vec into tibble...
	modules_tib <- tibble(modules)
	
	# example row in col 'modules': 	 "network-modules-K1-humanbase-0.2.dat_188\tZCCHC10\tSTAC3"
	modules_tib <- modules_tib %>%
		# Separate modules into 2 cols: net_mod, genes (using too_many = "merge" handles the genes together without trying to split them on tabs)
		separate_wider_delim( cols = "modules", names = c("net_mod", "genes"), delim = "\t", too_few = "debug", too_many = "merge" ) %>%
		# separate the module info and the module number
		separate_wider_delim( cols = "net_mod", names = c("network_label", "module_number"), delim = "_", too_few = "debug", too_many = "merge" )
		
		# default cut-off set to 0.0 - ie assuming no filter applied
		modules_tib <- modules_tib %>%
			mutate( cut_off_value = '0.0' ) %>%
			relocate( cut_off_value, .before = module_number )
		# if we have a combined modules file with all cut-offs, split the cut-off from module info (greedy regexp ".*" here will split on last delim)	
		if (split_cut_off_values == TRUE){
			modules_tib <- modules_tib %>%
				separate_wider_regex( network_label, c( network_type = ".*", "-", cut_off = ".*" ), cols_remove = FALSE ) %>%
				# remove the literal ".dat"
				mutate( cut_off_value = str_replace( cut_off, fixed(".dat"), "" ) ) %>%
				select( - cut_off )
		} else{
			modules_tib <- modules_tib %>%
				mutate( network_type = str_replace( network_label, fixed(".dat"), "" ) ) %>%
				relocate( network_type, .before = network_label )
		}
		# Add string prefix to module number and reorder cols
		# if no prefix, use the network_label
		if (module_prefix != ""){
			modules_tib <- modules_tib %>%
				mutate( module = map_chr( module_number, function(x) paste0(module_prefix, x) ) ) %>%
				relocate(module, .before = genes)
		} else {
			modules_tib <- modules_tib %>%
				mutate( module = paste0(network_label, '-', module_number) ) %>%
				mutate( module = str_replace( module, fixed(".dat"), "-module" ) ) %>%
				mutate( module = str_replace( module, fixed("network-modules-"), "" ) ) %>%
				relocate(module, .before = genes)
			# modules_tib <- mutate( modules_tib, module = module_number )
		}

		# modules_tib <- modules_tib %>%
		# 	mutate( module_label = str_replace( network_label, fixed(".dat"), "" ) ) %>%
		# 	mutate( module_label = str_replace( module_label, fixed(".dat"), "" ) ) %>%

	# Convert gene list to space sep for readability
	modules_tib <- modules_tib %>%
		rowwise() %>%
		mutate( gl = paste0( gsub( "\t", " ", genes ) ) ) %>%
		select(-genes)

	# pivot the genes in gl col to rows (tried to do direct col action eval into list but no luck...)
	modlong <- modules_tib %>%
		separate_rows( gl, sep=" " ) %>%	
		group_by( network_label, module )

	# Nest genelists within module groups
	modnest <- modlong %>%
		nest( genes = gl)

	# for each row move nested tibbles into lists
	modlist <- modnest %>%
		rowwise() %>%
		mutate( genelist = list( tibble::deframe( genes ) ) )

	# returns tibble - for g:Profiler-suitable named list 
	# pass tibble to convert_module_tibble_to_gp_query(...)
	return( select(modlist, -genes) )

}

filter_modules_by_cutoff <- function(tib_modules, cutoff) {
	library(dplyr)
	tib_modules$cut_off_value <- as.numeric(tib_modules$cut_off_value)	
	
	# Convert cutoff to numeric if it's a string
	if (is.character(cutoff)) {
		numeric_cutoff <- as.numeric(cutoff)	
	} else {
		numeric_cutoff <- as.numeric(cutoff)
	}

	# Filter modules by cutoff
	tib_modules <- tib_modules %>%
		filter(cut_off_value == numeric_cutoff)

	return(tib_modules)
}

# Convert output from parse_module_file(...) from 
# tibble -> named lists suitable for g:Profiler query submission;
# network cut-off filter is optional and applied to tibble before returning named list
convert_module_tibble_to_gp_query <- function(tib_modules, filter_cut_off = 'none', label_cols = c("network_type", "module"), gene_list = "genelist") {
	library(dplyr)
	
	# Get debug setting from environment variable
	debug <- Sys.getenv("DEBUG", unset = "false")
	debug <- tolower(debug) == "true"
	
	# Add debug output for input values
	if(debug) {
		print(paste("DEBUG: Input cutoff type:", typeof(filter_cut_off)))
		print(paste("DEBUG: Available cutoffs in data:", paste(unique(tib_modules$cut_off_value), collapse=", ")))
	}
	
	# Filter the data if a cutoff is specified
	if (filter_cut_off != 'none') {
		# Convert filter_cut_off to numeric for comparison
		numeric_cutoff <- as.numeric(filter_cut_off)
		if (is.na(numeric_cutoff)) {
			warning("Invalid cutoff value: ", filter_cut_off)
			return(list())
		}
		
		# Filter using numeric comparison
		tib_modules <- tib_modules %>%
			filter(as.numeric(cut_off_value) == numeric_cutoff)
		
		# Debug output after filtering
		if(debug) print(paste("DEBUG: Rows after filtering:", nrow(tib_modules)))
		
		# Return empty list if no matches found
		if (nrow(tib_modules) == 0) {
			warning(paste("No modules found for cutoff value:", filter_cut_off))
			return(list())
		}
	}
	
	# get named list with names of each genelist being the module and return
	result <- setNames(tib_modules$genelist, tib_modules$module)
	
	# Debug output for result
	if(debug) print(paste("DEBUG: Number of modules in result:", length(result)))
	
	return(result)
}

b <- function(df, cols){
    eval(substitute(cols), df)
}

# gprofiler gost wrapper includes boilerplate params for our purposes
# Note multi_query = TRUE, doesn"t quite do what expected as it will summarise all modules into top terms [see https://cran.r-project.org/web/packages/gprofiler2/vignettes/gprofiler2.html]
# 	whereas we want enriched terms grouped by modules - provided pass named list of modules into query this is what is done in this wrapper
# g:Profiler API base URL
# 	PRODUCTION SERVER: api_base_url='https://biit.cs.ut.ee/gprofiler'
# 	BETA SERVER: api_base_url='https://biit.cs.ut.ee/gprofiler_beta'
run_gprofiler_enrichment <- function(query, 
										sig_level=0.01, 
										sources=c( "GO:MF","GO:CC","GO:BP","KEGG","REAC","HPA","CORUM","HP","WP" ),
										exclude_go_iea=TRUE,
										multq=FALSE,
										batch_size=50,  # New parameter for batch processing
										max_retries=3,   # New parameter for retries
										api_base_url='https://biit.cs.ut.ee/gprofiler'
										){
	require(gprofiler2)
	require(dplyr)
	
	# Get debug setting from environment variable
	debug <- Sys.getenv("DEBUG", unset = "FALSE")
	debug <- tolower(debug) == "true"
	
	# g:Profiler API base URL
	nxf_api_base_url <- Sys.getenv("NXF_GPROFILER_API_URL", unset = NA)
	if (!is.na(nxf_api_base_url)) {
		api_base_url <- nxf_api_base_url
	}

	if(debug) print(paste0("DEBUG: Config g:profiler URL ", api_base_url))
	set_base_url(api_base_url)	

	if(debug) print(paste0("DEBUG: Running g:profiler for ", length(query), " modules..."))
	
	# Split query into batches
	query_names <- names(query)
	total_batches <- ceiling(length(query) / batch_size)
	all_results <- list()
	
	for(i in seq_len(total_batches)) {
		start_idx <- ((i-1) * batch_size) + 1
		end_idx <- min(i * batch_size, length(query))
		batch_query <- query[start_idx:end_idx]
		
		if(debug) print(paste0("DEBUG: Processing batch ", i, " of ", total_batches, 
					" (modules ", start_idx, " to ", end_idx, ")"))
		
		# Retry logic
		for(retry in 1:max_retries) {
			tryCatch({
				batch_result <- gost(
					query = batch_query,
					organism = "hsapiens", 
					ordered_query = FALSE, 
					multi_query = multq, 
					significant = TRUE, 
					exclude_iea = exclude_go_iea, 
					measure_underrepresentation = FALSE, 
					evcodes = FALSE, 
					user_threshold = sig_level, 
					correction_method = "g_SCS", 
					domain_scope = "annotated", 
					custom_bg = NULL, 
					numeric_ns = "", 
					sources = sources,
					as_short_link = FALSE
				)
				
				if(!is.null(batch_result)) {
					all_results[[i]] <- batch_result
					break  # Success - exit retry loop
				}
			}, error = function(e) {
				if(retry < max_retries) {
					if(debug) warning(paste0("DEBUG: Attempt ", retry, " failed. Retrying... Error: ", e$message))
					Sys.sleep(5)  # Wait 5 seconds before retrying
				} else {
					stop(paste0("All retry attempts failed for batch ", i, ". Error: ", e$message))
				}
			})
		}
	}
	
	# Combine results
	if(length(all_results) == 0) {
		stop("No results were obtained from g:Profiler")
	}
	
	# Combine all results into one
	combined_result <- all_results[[1]]
	if(length(all_results) > 1) {
		for(i in 2:length(all_results)) {
			if(!is.null(all_results[[i]]$result)) {
				combined_result$result <- rbind(combined_result$result, all_results[[i]]$result)
			}
		}
	}
	
	return(combined_result)
}

# Create empty result with correct structure
create_empty_result <- function() {
    tibble(
        source = character(),
        term_name = character(),
        term_id = character(),
        p_value = numeric(),
        term_size = integer(),
        query_size = integer(),
        intersection_size = integer(),
        precision = numeric(),
        recall = numeric(),
        effective_domain_size = integer(),
        source_order = integer(),
        parents = character(),
        experiment_info = character(),
        func_module_number = integer(),
        perc_rank = numeric(),
        cumelative_dist = numeric()
    )
}

# Post-process gprofiler results data.frame (gp_enrich$result) columns, plus filtering
# 	max_term: maximum GO:BP (or other source) term size, to filter out very generic terms assessed as total fraction of effective domain size
# 	gpresults: output from g:Profiler R API, which returns a long-form table, which just needs module number/experiment splitting out.
# 		(Previously (see e017/proccess_gprofiler.R) used output from web-version/multi-module-run; resultant file was very wide and needed pivoting appropriately.)
post_process_gprofiler_enrichment <- function(gpresults, max_term = 0.05, debug = FALSE) {
    require(tidyr)
    require(dplyr)

    # Input validation
    if (is.null(gpresults)) {
        if(debug) warning("Input gpresults is NULL - returning empty result")
        return(create_empty_result())
    }

    if (length(gpresults) == 0 || nrow(gpresults) == 0) {
        if(debug) warning("Empty gpresults - returning empty result")
        return(create_empty_result())
    }

    # Debug input structure
    if(debug) {
        cat("DEBUG: Input structure:\n")
        str(head(gpresults))
    }

    tryCatch({
        gpr <- gpresults %>%
            # column naming
            rename(experiment_info = query) %>%
            # Split on last underscore to get module number
            separate_wider_regex(experiment_info, 
                            c(experiment_info = ".*", "_", func_module_number = "\\d+"), 
                            cols_remove = TRUE) %>%
            # Convert func_module_number to numeric for proper sorting
            mutate(func_module_number = as.numeric(func_module_number))
        
        # Max term size grouped by source (GO:BP, REAC etc)
        gpr <- gpr %>%
            group_by(source) %>%
            filter(term_size < (max_term * effective_domain_size)) %>%
            # sort
            arrange(func_module_number, p_value)

        # add rankings - ensure we're still grouped properly
        gpr <- gpr %>%
            group_by(source, func_module_number) %>%
            mutate(
                perc_rank = percent_rank(p_value),
                cumelative_dist = cume_dist(p_value)
            ) %>%
            ungroup()  # Make sure to ungroup at the end

        # Validate output structure
        if (!all(c("perc_rank", "cumelative_dist") %in% colnames(gpr))) {
            if(debug) warning("Rankings columns not properly created")
            return(create_empty_result())
        }

        return(gpr)

    }, error = function(e) {
        if(debug) warning("Error in post-processing: ", e$message)
        return(create_empty_result())
    })
}

# Calculate Matthews Correlation Coefficient
calc_mcc <- function(tp, fn, fp, tn) { 
	require(mltools)
	cm <- matrix(c(tp, fn, fp, tn), nrow=2) 
	matthews_c <- mcc(confusionM = cm)
	return(as.numeric(matthews_c))
}

#  Add TP, FP etc confusion matrix and Matthew's Correlation Coefficient (MCC) to g:profiler output
add_tp_tn_fp_fn_mcc <- function(gpresults, inc_mcc = TRUE) {
	require(tidyr)
	require(dplyr)
	gpresults <- gpresults %>%
		ungroup() %>%
		# P (all positives)
		mutate(P = term_size) %>%
		# N (all negatives) [using total population = P + N,  hence N = total population - P]
		mutate(N = effective_domain_size - P) %>%
		# TP
		mutate(tp = intersection_size) %>%
		# FP
		mutate(fp = query_size - intersection_size) %>%
		# FN
		mutate(fn = term_size - intersection_size) %>%
		# TN
		mutate(tn = N - fp) %>%
		# validation (should equal effective domain size)
		mutate(tot_pop_valid = tp + fp + fn + tn)

	# mcc
	if (inc_mcc == TRUE) {
		gpresults <- gpresults %>%
			rowwise() %>%
			mutate(MCC = calc_mcc(tp, fn, fp, tn))
	}

	return(gpresults)
}

# return module num and concatenated GO terms for top ranked GO:BP funcs
# used for input to GOAtools for slims
# moved -> macsr_nf/macsr_nf_dev/script/go_slim.r
# get_top_go_terms_by_module <- function( gpr, min_perc_rank=0.25 ){...}

#  Pivot the g:Profiler enrichment table to long form 
#  From e017 as func: proc_enrich() - note this isn't required in command line gprofiler runs (eg e019)
#  These are the 3 names_to to capture (from 15/02/23 update; previously only using adjusted_p_value)
#   	adjusted_p_value__e017_R1_mod_2 = col_double(),
#   	query_size__e017_R1_mod_2 = col_double(),
#   	intersection_size__e017_R1_mod_2 = col_double(),
pivot_gp_long <- function( root_dir, enrich_file, pfilt = 0.01, split_exp_module_field = FALSE ){
	require(readr)
	require(tidyr)
	require(dplyr)

    # data frame R1 or M1
    df_mult <- read_delim( file.path( root_dir, enrich_file ), delim = "," )

    # Pivot:  "adjusted_p_value", "query_size", "intersection_size" for each GO/Reac etc term's gene-set in the rows
    df_long <- df_mult %>%
                select( c( "source", "term_name", "term_id", "term_size", "effective_domain_size" ) | starts_with( "adjusted_p_value" ) | starts_with( "query_size" ) | starts_with( "intersection_size" ) ) %>%
                pivot_longer( !c( "source", "term_name", "term_id", "term_size", "effective_domain_size" ), 
                    names_to = c( ".value", "module_info" ),
                    names_sep = "__",
                    values_drop_na = FALSE ) %>%
				# filter by p-value
				filter( adjusted_p_value < pfilt )
    
    # Split exper info into 2 fields (expID, module)
	if ( split_exp_module_field ){
		df_long <- df_long %>%
			separate( 	module_info,
						sep = "_mod_", 
						into = c( "experiment_info", "func_module_number" ), 
						remove =  TRUE, 
						convert = TRUE, 
						extra = "warn", 
						fill = "warn" )
	}

	# df_long <- arrange( df_long, func_module_number, adjusted_p_value )
	# If want to print all rows...
	# print.data.frame(df_long)
	return(df_long)
}

# from /Users/ash/Dropbox/bioinf/MACSMAF/experiments/e017/process_modules.R
proc.modules <- function( root_dir, mod_file, type = 'none' ){
	print('use process_modules.R')
}
