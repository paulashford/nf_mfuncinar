#!/usr/bin/env nextflow
nextflow.enable.dsl=2
// 01 2025 p.ashford@ucl.ac.uk
// https://github.com/paulashford/macsmaf_nf

// cd /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/workflows
// export NF_CONFIG=/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/conf/base.config
// nextflow run macs_nf_dev.nf -c "${NF_CONFIG}"

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// include { PASCAL_GWAS } from '../subworkflows/pascal_gwas'
include { NETWORK_PROCESSING } from '../subworkflows/network_processing'
include { GO_SLIM } from '../subworkflows/go_slim'
include { MOD_FUNC_ENRICH } from '../subworkflows/mod_func_enrich/main.nf'
include { RANK_ANNOT } from '../subworkflows/rank_annot'

// Activate virtual environment for all processes
// process.beforeScript = "source ${params.root_proj_dir}/venv/bin/activate"

// Add validation functions
def validateModFuncEnrichInputs(net_methods, net_dbs, net_cutoffs, modules_dir, file_prefix) {
    // Validate methods
    if (!net_methods) {
        error "Network methods cannot be null"
    }
    // Validate dbs
    if (!net_dbs) {
        error "Network dbs cannot be null"
    }
    // Validate cutoffs
    if (!net_cutoffs) {
        error "Network cutoffs cannot be null"
    }
    // Verify cutoffs strings can be parsed as valid numerics
    if (!net_cutoffs.every { it.toString().isNumber() }) {
        error "Network cutoffs must be valid numeric values"
    }

    // Validate directory paths
    if (!modules_dir) {
        error "Network modules directory path cannot be null"
    }
    if (!file(modules_dir).exists()) {
        error "Network modules directory does not exist: ${modules_dir}"
    }

    // Validate file prefix
    if (!file_prefix) {
        error "Network file prefix cannot be null"
    }
}

def validateGprofilerParams(sources, sig_threshold, exclude_iea) {
    // Validate sources
    if (!sources) {
        error "gprofiler_sources parameter is required"
    }

    // Validate significance threshold
    if (sig_threshold == null) {
        error "gprofiler_sig parameter is required"
    }
    if (!(sig_threshold instanceof Number)) {
        error "gprofiler_sig must be a number"
    }
    if (sig_threshold < 0 || sig_threshold > 1) {
        error "gprofiler_sig must be between 0 and 1"
    }

    // Validate IEA exclusion parameter
    if (exclude_iea == null) {
        error "gprofiler_exclude_iea parameter is required"
    }
    if (!(exclude_iea instanceof Boolean)) {
        error "gprofiler_exclude_iea must be a boolean"
    }
}

def validateOutputPaths(output_dir) {
    // Validate output directory
    if (!output_dir) {
        error "Output directory path cannot be null"
    }
    
    def output_path = file(output_dir)
    if (!output_path.exists()) {
        log.info "Creating output directory: ${output_dir}"
        if (!output_path.mkdirs()) {
            error "Failed to create output directory: ${output_dir}"
        }
    }
    if (!output_path.isDirectory()) {
        error "Output path exists but is not a directory: ${output_dir}"
    }
    if (!output_path.canWrite()) {
        error "Output directory is not writable: ${output_dir}"
    }
}

workflow {
    // Debug input parameters
    if (params.debug) {
        log.info """
        ==============================================
        MACSMAF NF-DEV PIPELINE
        ==============================================
        Network DBs      : ${params.net_dbs}
        Network Methods  : ${params.net_methods}
        Network Cutoffs  : ${params.net_cutoffs}
        """
    }

    // Validate inputs
    validateModFuncEnrichInputs(
        params.net_methods,
        params.net_dbs,
        params.net_cutoffs,
        params.nf_network_modules_dir,
        params.net_file_prefix
    )
    // Validate gprofiler parameters
    validateGprofilerParams(
        params.gprofiler_sources,
        params.gprofiler_sig,
        params.gprofiler_exclude_iea
    )

    // Create input channel for network processing
    // if params.preproc_net_modules == true, the modules supplied in nf_network_modules_dir are assumed to be original DREAM/Monet module,s
    // which will first be pre-processed and then stored in ${params.nf_out_dir}/pre_processed_networks
    ch_network_input = Channel.fromList(params.net_methods)
        .combine(Channel.fromList(params.net_dbs))
        .map { method, db -> 
            def module_dir = params.preproc_net_modules ? 
                "${params.nf_network_modules_dir}" :
                "${params.nf_out_dir}/pre_processed_networks"
            
            [method, db, module_dir]
        }
        .tap { ch_network_debug }

    // Add debug logging for network input channel
    if (params.debug) {
        ch_network_debug.view { method, db, module_dir ->
            """
            DEBUG: Network Input Channel:
            Method: ${method}
            Database: ${db}
            Module Directory: ${module_dir}
            """
        }
    }

    // Process networks first if needed
    if (params.preproc_net_modules) {
        log.info "Preprocessing networks first..."
        NETWORK_PROCESSING(ch_network_input)
        // Create a channel from the preprocessed networks with method and db info
        ch_preprocessed = NETWORK_PROCESSING.out.pre_processed_networks
            .map { method, db, module_dir -> 
                log.info "Network preprocessing complete for ${method}-${db}; pre-processed networks stored in ${module_dir}"
                [method, db, module_dir]
            }
    } else {
        ch_preprocessed = ch_network_input.map { method, db, module_dir ->
            log.info "Using existing preprocessed networks for ${method}-${db}; module directory: ${module_dir}"
            [method, db, module_dir]
        }
    }

    ch_network_cutoffs = Channel.fromList(params.net_cutoffs ?: [])
                                .ifEmpty { error "No cutoff values specified in params.net_cutoffs" }

    // Create mfe (module functional enrichment) input a combined channel with preprocessed directory and method/db pairs
    ch_mfe_input = ch_preprocessed
        .map { method, db, module_dir -> 
            [method, db, module_dir, "${params.net_file_prefix}${method}_${db}_parsed.dat"]
        }
        .tap { ch_mfe_debug }

    if (params.debug) {
        ch_mfe_debug.view { method, db, module_dir, filename ->
            """
            DEBUG: MFE input:
            Method: ${method}
            Database: ${db}
            Module Directory: ${module_dir}
            Filename: ${filename}
            """
        }
    }

    // Module functional enrichment workflow
    MOD_FUNC_ENRICH(
        ch_mfe_input,          // tuple(method, db, module_dir, mod_filename)
        ch_network_cutoffs,     // list of cutoff values moved to end
        params.net_file_prefix,
        params.gprofiler_sources,
        params.gprofiler_sig,
        params.gprofiler_exclude_iea
    )

    // Add GO_SLIM workflow using MOD_FUNC_ENRICH output
    GO_SLIM(
        MOD_FUNC_ENRICH.out.post_processed_enrichment,  // tuple(method, db, cutoff, file) with metrics
        params.go_slim_min_perc_rank ?: 0.25
    )

    // Add RANK_ANNOT workflow
    RANK_ANNOT(
        MOD_FUNC_ENRICH.out.post_processed_enrichment,  // tuple(method, db, cutoff, file) with metrics
        GO_SLIM.out.mapped_slim_results,                // tuple(method, db, cutoff, file) after mapping to slim
        MOD_FUNC_ENRICH.out.filtered_modules,          // tuple(method, db, cutoff, file) containing filtered gene lists
        params.max_term_size ?: 0.05
    )

    // Debug output
    if (params.debug) {
        ch_network_input.view { method, db, dir ->
            """
            DEBUG: Network Input Channel:
            Method: ${method}
            Database: ${db}
            Directory: ${dir}
            """
        }

        ch_mfe_input.view { method, db, dir, filename ->
            """
            DEBUG: MFE input:
            Method: ${method}
            Database: ${db}
            Module Directory: ${dir}
            Filename: ${filename}
            """
        }

        MOD_FUNC_ENRICH.out.post_processed_enrichment.view { tuple ->
            """
            DEBUG: Processed enrichment results:
            Method: ${tuple[0]}
            Database: ${tuple[1]}
            Cutoff: ${tuple[2]}
            File: ${tuple[3]}
            """
        }

        GO_SLIM.out.go_slim_results.view { tuple ->
            """
            DEBUG: GO Slim results:
            Method: ${tuple[0]}
            Database: ${tuple[1]}
            Cutoff: ${tuple[2]}
            File: ${tuple[3]}
            """
        }

        RANK_ANNOT.out.ranked_results.view { tuple ->
            """
            DEBUG: Ranked and annotated results:
            Method: ${tuple[0]}
            Database: ${tuple[1]}
            Cutoff: ${tuple[2]}
            File: ${tuple[3]}
            """
        }

        MOD_FUNC_ENRICH.out.parsed_modules.view { tuple ->
            """
            DEBUG: Parsed modules output:
            File: ${tuple}
            """
        }
    }

    // Output for checking and validation
    MOD_FUNC_ENRICH.out.parsed_modules
        .view { tuple -> 
            params.debug ? """
                DEBUG: Parsed modules output:
                  File: ${tuple}
                """ : null
        }

    MOD_FUNC_ENRICH.out.post_processed_enrichment
        .view { tuple -> 
            params.debug ? """
                DEBUG: Processed enrichment results:
                  File: ${tuple}
                """ : null
        }
}

// Test workflow for NETWORK_PROCESSING
workflow test_network_processing {
    // Create test input channel with method, db, and path to network files
    ch_test_input = Channel.of(
        tuple(
            'K1',                     // method
            'humanbase',              // db
            file("${params.nf_network_modules_dir}/K1")  // directory containing the network files
        )
    )

    // Run network processing
    NETWORK_PROCESSING(ch_test_input)
    
    // Debug output for network processing
    if (params.debug) {
        NETWORK_PROCESSING.out.pre_processed_networks
            .view { method, db, file -> 
                """
                DEBUG: Network Processing Output:
                Method: ${method}
                Database: ${db}
                File: ${file}
                """
            }
    }

    // g:Profiler parameters debug output
    if (params.debug) {
        log.info "DEBUG: gprofiler_sources = ${params.gprofiler_sources}"
        log.info "DEBUG: gprofiler_sig = ${params.gprofiler_sig}"
        log.info "DEBUG: gprofiler_exclude_iea = ${params.gprofiler_exclude_iea}"
    }
}

