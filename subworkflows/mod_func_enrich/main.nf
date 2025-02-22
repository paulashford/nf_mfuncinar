// subworkflow for g:Profiler functional enrichment
// 01 2025 p.ashford@ucl.ac.uk
// https://github.com/paulashford/macsmaf_nf

nextflow.enable.dsl=2

// include { get_network_filenames } from './module_func_enrich.nf'
include { parse_modules } from './module_func_enrich.nf'
include { filter_modules } from './module_func_enrich.nf'
include { run_gprofiler } from './module_func_enrich.nf'
include { post_process_gprofiler_enrichment } from './module_func_enrich.nf'
include { add_tp_tn_fp_fn_mcc } from './module_func_enrich.nf'

workflow MOD_FUNC_ENRICH {
	take:
		ch_net_dbs_methods  // tuple(method, db, module_dir, mod_filename)
		ch_net_cutoffs
		net_file_prefix
		gprofiler_sources
		gprofiler_sig
		gprofiler_exclude_iea
		
	main:
		if (params.debug) {
			ch_net_dbs_methods.view { method, db, module_dir, mod_filename ->
				"DEBUG: MFE channel input: Method: ${method}, DB: ${db}, Module Directory: ${module_dir}, Module Filename: ${mod_filename}"
			}
		}

		// Parse modules with correct parameter order
		ch_parsed_modules = parse_modules(
				ch_net_dbs_methods.map { _method, _db, module_dir, mod_filename -> file("${module_dir}/${mod_filename}") },  // network_file
				net_file_prefix,
				ch_net_dbs_methods.map { method, _db, _module_dir, mod_filename -> method },  // method
				ch_net_dbs_methods.map { _method, db, _module_dir, mod_filename -> db }     // db
			)
			// create a channel of network methods and dbs combined with cut-offs
			.combine(ch_net_cutoffs)
			.map { method, db, mod_filename, cutoff ->
				[method, db, cutoff, mod_filename]
			}
			.tap { ch_parsed_modules_debug }
		
		if (params.debug) {
			ch_parsed_modules_debug.view { method, db, cutoff, mod_filename ->
				"DEBUG: MFE ch_parsed_modules: Method: ${method}, DB: ${db}, Cutoff: ${cutoff}, Module Filename: ${mod_filename}"
			}
		}

		// Filter modules by cutoff
		ch_filtered_modules = filter_modules(ch_parsed_modules)
			.map { method, db, cutoff, mod_filename -> 
				[ method, db, cutoff, mod_filename ]
			}
			.tap { ch_filtered_modules_debug }

		if (params.debug) {
			ch_filtered_modules_debug.view { method, db, cutoff, mod_filename ->
				"DEBUG: MFE ch_filtered_modules: Method: ${method}, DB: ${db}, Cutoff: ${cutoff}, Module Filename: ${mod_filename}"
			}
		}
		
		// 	try {
		// 		def hasContent = modules.exists() && modules.size() > 0
		// 		if (hasContent) {
		// 			def result = ["Rscript", "-e", """
		// 				df <- readRDS('${modules}')
		// 				network_label <- unique(df\$network_label)
		// 				expected_label <- paste0('network-modules-${method}-${db}-${cutoff}')
		// 				if (length(network_label) > 0 && network_label == expected_label) {
		// 					cat('TRUE')
		// 				} else {
		// 					cat('FALSE')
		// 				}
		// 				"""].execute().text.trim()
		// 			hasContent = result == "TRUE"
		// 		}
		// 		if (!hasContent && params.debug) {
		// 			println "DEBUG: Skipping empty/invalid module file for Method: ${method}, DB: ${db}, Cutoff: ${cutoff}"
		// 		}
		// 		return hasContent
		// 	} catch (Exception e) {
		// 		if (params.debug) {
		// 			println "DEBUG: Error processing file for Method: ${method}, DB: ${db}, Cutoff: ${cutoff} - ${e.message}"
		// 		}
		// 		return false
		// 	}
		// }
		// Debug: Print inputs before running gprofiler
		if (params.debug) {
			println "DEBUG: gprofiler_sources = $gprofiler_sources"
			println "DEBUG: gprofiler_sig = $gprofiler_sig" 
			println "DEBUG: gprofiler_exclude_iea = $gprofiler_exclude_iea"
		}

		// Run g:Profiler with filtered modules
		gp_results = run_gprofiler(
			ch_filtered_modules,  // [method, db, cutoff, modules]
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
		parsed_modules = ch_parsed_modules
		filtered_modules = ch_filtered_modules
		post_processed_enrichment = processed_results.processed_results  // [method, db, cutoff, file]
		post_processed_enrichment_tsv = processed_results.processed_results_tsv  // [method, db, cutoff, file]
		
}

