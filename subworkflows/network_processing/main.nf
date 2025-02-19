// This is the main workflow for the PPI network processing subworkflow.
// 23 01 2025 p.ashford@ucl.ac.uk
// https://github.com/paulashford/macsmaf_nf

// Network processing subworkflow
nextflow.enable.dsl=2

process PREPROC_NET_MODULES {
    debug true  // Add debug mode
    // Remove the old publishDir directive
    // publishDir "${params.nf_network_modules_dir}/pre_processed_networks", mode: 'copy'
    // Use the output directory instead
    publishDir "${params.nf_out_dir}/pre_processed_networks", mode: 'copy'

    input:
    tuple val(method), val(db), path(network_modules_dir)  

    output:
    tuple val(method), val(db), path("*.dat"), emit: pre_processed_networks

    script:
    def output_name = "network_modules_${method}_${db}.dat"
    """
    if [[ \$DEBUG == "true" ]]; then
        echo "DEBUG: Processing network modules for method=${method} db=${db}"
        echo "DEBUG: Input directory absolute path: \$(readlink -f ${network_modules_dir})"
        echo "DEBUG: Output directory: ${params.nf_out_dir}/pre_processed_networks"
    fi
    
    ${params.root_proj_dir}/bin/process_network_modules.sh \\
        "${method}" \\
        "${db}" \\
        "\$(readlink -f ${network_modules_dir})" > "${output_name}"

    if [[ \$DEBUG == "true" ]]; then
        echo "DEBUG: Script exit status: \$?"
    fi
    """
}

workflow NETWORK_PROCESSING {
    take:
    network_inputs     // tuple(method, db, path)

    main:
    if (params.preproc_net_modules) {
        PREPROC_NET_MODULES(
            network_inputs
        )
        pre_processed_networks = PREPROC_NET_MODULES.out.pre_processed_networks
    }else {
        // Modify path to include pre_processed_networks subfolder
        pre_processed_networks = network_inputs.map { method, db, path ->
            [method, db, file("${params.nf_network_modules_dir}/pre_processed_networks")]
        }
    }

    emit:
    pre_processed_networks
}

