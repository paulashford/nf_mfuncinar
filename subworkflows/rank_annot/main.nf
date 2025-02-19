#!/usr/bin/env nextflow
// 01 2025 p.ashford@ucl.ac.uk
// https://github.com/paulashford/macsmaf_nf

process RANK_ANNOTATE {
    publishDir "${params.nf_enrichment_dir}/rank_annotated", mode: 'copy'
    
    input:
    tuple val(method), val(db), val(cutoff), path(enrichment_file), path(goslim_file), path(modules_file)
    val(max_term_size)

    output:
    tuple val(method), val(db), val(cutoff), path("*_ranked_annotated.tsv"), emit: ranked_results
    tuple val(method), val(db), val(cutoff), path("*_topk_aggregated.tsv"), emit: aggregated_results
    tuple val(method), val(db), val(cutoff), path("*_rank1_aggregated.tsv"), emit: rank1_results
    tuple val(method), val(db), val(cutoff), path("*_rank_agg_final.tsv"), emit: final_results
    
    script:
    """
    Rscript ${params.root_proj_dir}/subworkflows/rank_annot/rank_annot.r \
        --enrichment_file ${enrichment_file} \
        --goslim_file ${goslim_file} \
        --modules_file ${modules_file} \
        --output_file "${method}_${db}_${cutoff}_ranked_annotated.tsv" \
        --max_term_size ${max_term_size} \
        --perc_rank_cutoff 0.25
    """
}

workflow RANK_ANNOT {
    take:
    enrichment_results  // tuple(method, db, cutoff, file)
    goslim_results      // tuple(method, db, cutoff, file)
    modules_results     // tuple(method, db, cutoff, file)
    max_term_size      

    main:
    // Join channels by method, db, and cutoff, allowing for missing combinations
    combined_inputs = enrichment_results
        .join(goslim_results, by: [0,1,2], failOnMismatch: false)  // join by method, db, cutoff
        .join(modules_results, by: [0,1,2], failOnMismatch: false)  // join by method, db, cutoff
        .filter { it.every { elem -> elem != null } }  // Remove any combinations with null values
        .map { method, db, cutoff, enrich_file, goslim_file, modules_file ->
            if (params.debug) {
                log.info """
                    DEBUG: Processing combination:
                    Method: ${method}
                    DB: ${db}
                    Cutoff: ${cutoff}
                    Enrichment file: ${enrich_file}
                    GO Slim file: ${goslim_file}
                    Modules file: ${modules_file}
                """
            }
            tuple(method, db, cutoff, enrich_file, goslim_file, modules_file)
        }

    // Run RANK_ANNOTATE only with valid combinations
    RANK_ANNOTATE(
        combined_inputs,
        max_term_size
    )

    emit:
    ranked_results = RANK_ANNOTATE.out.ranked_results
    aggregated_results = RANK_ANNOTATE.out.aggregated_results
    rank1_results = RANK_ANNOTATE.out.rank1_results
    final_results = RANK_ANNOTATE.out.final_results
}
