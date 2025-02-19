#!/usr/bin/env nextflow
nextflow.enable.dsl=2
// 01 2025 p.ashford@ucl.ac.uk
// https://github.com/paulashford/macsmaf_nf

// module_func_enrich.nf

// This workflow performs functional enrichment analysis on modules extracted from a network.
// It includes processes for parsing modules, running enrichment tests, and adding metrics.

// get_network_filenames: for given netdb type (string, cpdb, ... ) and method (K1, ...) get matching networks 
// available in net_modules_dir. Use of glob and files() returns a list, so if multiple types of network for 
// a given netdb / method (e.g. each using different gene identifiers), then each will be processed through channel
process get_network_filenames {
	debug true
	input:
		val(netdb_method)
		val(net_file_prefix)
		val(net_modules_dir)

	output:
		path 'net_file_names'

	script:
	// When preproc_net_modules is true, look in the output directory
	def search_dir = params.preproc_net_modules ? 
		"${params.nf_out_dir}/pre_processed_networks" : 
		net_modules_dir
		
	"""
	if [[ \$DEBUG == "true" ]]; then
		echo "DEBUG: Searching in directory: ${search_dir}"
	fi

	for file in ${search_dir}/${net_file_prefix}${netdb_method[0]}_${netdb_method[1]}*.dat; do
		if [ -f "\$file" ]; then
			echo "\$file" >> net_file_names
		fi
	done
	if [ ! -s net_file_names ]; then
		echo "No matching files found for pattern: ${search_dir}/${net_file_prefix}${netdb_method[0]}_${netdb_method[1]}*.dat" >&2
		exit 1
	fi
	"""
}

process parse_modules {
	debug true
	publishDir "${params.nf_out_dir}/parsed_modules", mode: 'copy'

	input:
		path network_file
		val net_file_prefix
		val(method)
		val(db)

	output:
		tuple val(method), val(db), path("${method}_${db}_parsed_modules.rds")

	script:
	"""
	if [[ \$DEBUG == "true" ]]; then
		echo "DEBUG: Parsing modules for method=${method} db=${db}"
		echo "DEBUG: Input network file: ${network_file}"
		echo "DEBUG: Output filename: ${method}_${db}_parsed_modules.rds"
	fi

	Rscript "${params.root_proj_dir}/subworkflows/mod_func_enrich/mod_parse.r" \\
		"${network_file}" \\
		"${net_file_prefix}" \\
		"${method}_${db}_parsed_modules.rds"
	"""
}

// Filter modules by cutoff using the new dedicated function
process filter_modules {
	debug true
	
	input:
		tuple val(method), val(db), val(cutoff), path(modules)
	
	output:
		tuple val(method), val(db), val(cutoff), path("filtered_modules.rds")
	
	script:
	"""
	#!/usr/bin/env Rscript
	
	# Source functions
	source("${params.root_proj_dir}/subworkflows/mod_func_enrich/gprofiler_enrichment_functions.r")
	
	# Load and filter modules
	modules_data <- readRDS("${modules}")
	filtered_data <- filter_modules_by_cutoff(modules_data, ${cutoff})
	
	# Save filtered modules
	saveRDS(filtered_data, "filtered_modules.rds")
	"""
}


process run_gprofiler {
	debug true
	publishDir "${params.nf_out_dir}/enrichment", mode: 'copy'
	
	// Add error strategy to help debug issues
	errorStrategy 'retry'
	maxRetries 2

	input:
		tuple val(method), val(db), val(cutoff), path(parsed_modules)
		val(sources)
		val(signif)
		val(exclude_iea)

	output:
		tuple val(method), val(db), val(cutoff), path("${out_prefix}_gp_enrich.rds")

	script:
	out_prefix = "${method}_${db}_${cutoff}"
	"""
    if [ "${params.debug}" = "true" ]; then
		echo "DEBUG: Running g:Profiler enrichment"
		echo "DEBUG: Method: ${method}"
		echo "DEBUG: Database: ${db}"
		echo "DEBUG: Cutoff: ${cutoff}"
		echo "DEBUG: Input file: ${parsed_modules}"
		echo "DEBUG: Output file: ${out_prefix}_gp_enrich.rds"
	fi

	Rscript "${params.root_proj_dir}/subworkflows/mod_func_enrich/run_gp.r" \\
		"${parsed_modules}" \\
		"${cutoff}" \\
		"${sources}" \\
		"${signif}" \\
        "${exclude_iea.toString().toLowerCase()}" \\
		"${out_prefix}_gp_enrich.rds"

	# Verify output file was created and has content
	if [ ! -s "${out_prefix}_gp_enrich.rds" ]; then
		echo "WARNING: (run_gprofiler/run_gp.r) Output file empty or not created - Method: ${method}; Database: ${db}; Cutoff: ${cutoff}"
		echo "WARNING: (run_gprofiler/run_gp.r) Input file: ${parsed_modules}; Output file: ${out_prefix}_gp_enrich.rds"
	fi
	"""
}

process post_process_gprofiler_enrichment {
	debug true
	publishDir "${params.nf_out_dir}/enrichment", mode: 'copy'

	input:
		tuple val(method), val(db), val(cutoff), path(gprofiler_results)

	output:
		tuple val(method), val(db), val(cutoff), path("${out_prefix}_processed_enrichment.rds"), emit: processed_results

	script:
	out_prefix = "${method}_${db}_${cutoff}"
	"""
	# First check if input file is empty
	if [ ! -s ${gprofiler_results} ]; then
		echo "WARNING: Empty g:Profiler results file - skipping post-processing"
		touch ${out_prefix}_processed_enrichment.rds
		exit 0
	fi

	Rscript ${params.root_proj_dir}/subworkflows/mod_func_enrich/post_process_gp.r \\
		${gprofiler_results} \\
		${method} \\
		${db} \\
		${cutoff} \\
		${out_prefix}_processed_enrichment.rds
	"""
}

process add_tp_tn_fp_fn_mcc {
	debug true
	publishDir "${params.nf_enrichment_dir}", mode: 'copy'

	input:
		tuple val(method), val(db), val(cutoff), path(processed_enrichment)

	output:
		tuple val(method), val(db), val(cutoff), path("${out_prefix}_enrichment_with_metrics.rds"), emit: processed_results
		tuple val(method), val(db), val(cutoff), path("${out_prefix}_enrichment_with_metrics.tsv"), emit: processed_results_tsv

	script:
	out_prefix = "${method}_${db}_${cutoff}"
	"""
	# First check if input file is empty
	if [ ! -s ${processed_enrichment} ]; then
		echo "WARNING: Empty processed enrichment file - skipping metrics calculation"
		touch ${out_prefix}_enrichment_with_metrics.rds
		touch ${out_prefix}_enrichment_with_metrics.tsv
		exit 0
	fi
	
	Rscript ${params.root_proj_dir}/subworkflows/mod_func_enrich/add_metrics.r \
		${processed_enrichment} \
		"${out_prefix}_enrichment_with_metrics.rds" \
		"${out_prefix}_enrichment_with_metrics.tsv"
	"""
}