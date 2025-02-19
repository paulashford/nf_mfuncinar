// subworkflow for g:Profiler functional enrichment
// 01 2025 p.ashford@ucl.ac.uk
// https://github.com/paulashford/macsmaf_nf

nextflow.enable.dsl=2

include { get_network_filenames } from './module_func_enrich.nf'
include { parse_modules } from './module_func_enrich.nf'
include { filter_modules } from './module_func_enrich.nf'
include { run_gprofiler } from './module_func_enrich.nf'
include { post_process_gprofiler_enrichment } from './module_func_enrich.nf'
include { add_tp_tn_fp_fn_mcc } from './module_func_enrich.nf'

workflow MOD_FUNC_ENRICH {
	take:
		ch_net_dbs_methods  // [method, db, path]
		net_file_prefix
		gprofiler_sources
		gprofiler_sig
		gprofiler_exclude_iea
		ch_net_cutoffs
	
	main:
		// Get network files
		network_files = get_network_filenames(
			ch_net_dbs_methods,
			net_file_prefix,
			ch_net_dbs_methods.map { it[2] }.first()
		)
		.view { files -> 
			params.debug ? "DEBUG: Network files - $files" : null
		}
		// // Convert output to a channel of files
		// network_file = network_files
		// 	.splitText()   
		// 	.map { it.trim() } 
		// 	.filter { it.length() > 0 } 
		// 	.map { file(it) }  
		// 	.ifEmpty { error "No module network files found matching pattern" }
		
		// Parse modules
		parsed_modules = parse_modules(
			network_files.splitText().map { it.trim() }.filter { it.length() > 0 }.map { file(it) },
			net_file_prefix,
			ch_net_dbs_methods.map { it[0] },  // method
			ch_net_dbs_methods.map { it[1] }   // db
		)
		.combine(ch_net_cutoffs)
		.map { method, db, modules, cutoff -> 
			[ method, db, cutoff, modules ]  // Ensure consistent order
		}
		.view { method, db, cutoff, modules ->
			// "DEBUG: Initial parse - Method: ${method}, DB: ${db}, Cutoff: ${cutoff}, Modules: ${modules}"
			params.debug ? "DEBUG: Initial parse - Method: ${method}, DB: ${db}, Cutoff: ${cutoff}, Modules: ${modules}" : null
		}

		// Filter modules by cutoff
		filtered_modules = filter_modules(parsed_modules)  // parsed_modules should already include cutoff
		.map { method, db, cutoff, modules -> 
			[ method, db, cutoff, modules ]  // Maintain order
		}
		.view { method, db, cutoff, modules ->
			params.debug ?  "DEBUG: Post filter_modules - Method: ${method}, DB: ${db}, Cutoff: ${cutoff}, Modules: ${modules}" : null
		}
		// Debug: Print inputs before running gprofiler
		if (params.debug) {
			println "DEBUG: gprofiler_sources = $gprofiler_sources"
			println "DEBUG: gprofiler_sig = $gprofiler_sig" 
			println "DEBUG: gprofiler_exclude_iea = $gprofiler_exclude_iea"
		}

		// Run g:Profiler with filtered modules
		gp_results = run_gprofiler(
			filtered_modules,  // [method, db, cutoff, modules]
			gprofiler_sources,
			gprofiler_sig,
			gprofiler_exclude_iea
		)
	
		// Post-process results maintaining cutoff
		processed_results = post_process_gprofiler_enrichment(
			gp_results  // [method, db, cutoff, enrichment]
		)

		// Add classification metrics and MCC
		processed_results = add_tp_tn_fp_fn_mcc(
			processed_results
		)

	emit:
		parsed_modules = parsed_modules
		filtered_modules = filtered_modules           // [method, db, cutoff, file]
		post_processed_enrichment = processed_results.processed_results  // [method, db, cutoff, file]
		post_processed_enrichment_tsv = processed_results.processed_results_tsv  // [method, db, cutoff, file]
		
}

