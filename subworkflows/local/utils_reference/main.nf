include { INDEX_UNFILTERED_GRAPH     } from '../../../modules/local/vg/index_unfiltered/main'
include { INDEX_UNFILTERED_GRAPH_GPU } from '../../../modules/local/vg/index_unfiltered/gpu'
include { INDEX_FILTERED_GRAPH       } from '../../../modules/local/vg/index_filtered/main'
include { INDEX_FILTERED_GRAPH_GPU   } from '../../../modules/local/vg/index_filtered/gpu'
include { BWA_INDEX                  } from '../../../modules/nf-core/bwa/index/main'
include { GRAPH_STATISTICS           } from '../../../modules/local/vg/stats/main'
include { SAMTOOLS_FAIDX             } from '../../../modules/nf-core/samtools/faidx/main'
include { GRAPH_EXTRACT              } from '../../../modules/local/vg/paths/main'
include { COMPUTE_SNARLS             } from '../../../modules/local/vg/snarls/main'

workflow REFERENCE_UTILITIES {

    take:
    workflow_steps
    gpu_giraffe
    reference_type
    reference_stats
    reference
    sample_types
    paths

    main:
    indexed_reference = channel.empty()
    stats             = channel.empty()
    reference_fastas  = channel.empty()
    snarls            = channel.empty()

    // If indexing is requested, index appropriately based on the reference type
    if ( 'index' in workflow_steps) {
        if ( reference_type == "unfiltered_graph" ) {
            // GPU accelerated giraffe version lags behind vg CPU baseline -> ensure compatible indexes by reverting vg to parabricks version
            if ( gpu_giraffe ) {
                INDEX_UNFILTERED_GRAPH_GPU (
                    reference,
                    sample_types
                )
                reference
                    .combine(INDEX_UNFILTERED_GRAPH_GPU.out.ch_hapl_indexes)
                    .collect()
                    .map { element ->
                        [ref: element[0], indexes: element[1..-1]]
                    }
                    .set { indexed_reference }
            } else {
                INDEX_UNFILTERED_GRAPH (
                    reference,
                    sample_types
                )
                reference
                    .combine(INDEX_UNFILTERED_GRAPH.out.ch_hapl_indexes)
                    .collect()
                    .map { element ->
                        [ref: element[0], indexes: element[1..-1]]
                    }
                    .set { indexed_reference }
            }
        } else if ( reference_type == "filtered_graph" ) {
            // GPU accelerated giraffe version lags behind vg CPU baseline -> ensure compatible indexes by reverting vg to parabricks version
            if ( gpu_giraffe ) {
                INDEX_FILTERED_GRAPH_GPU (
                    reference,
                    sample_types
                )
                reference
                    .combine(INDEX_FILTERED_GRAPH_GPU.out.ch_filter_indexes)
                    .collect()
                    .map { element ->
                        [ref: element[0], indexes: element[1..-1]]
                    }
                    .set { indexed_reference }
            } else {
                INDEX_FILTERED_GRAPH (
                    reference,
                    sample_types
                )
                reference
                    .combine(INDEX_FILTERED_GRAPH.out.ch_filter_indexes)
                    .collect()
                    .map { element ->
                        [ref: element[0], indexes: element[1..-1]]
                    }
                    .set { indexed_reference }
            }
        } else if ( reference_type == "linear" ) {
            // Index the reference
            BWA_INDEX (
                reference
            )
            reference
                .combine(BWA_INDEX.out.ch_bwa_index)
                .collect()
                .map { element ->
                    [ref: element[0], indexes: element[1..-1]]
                }
                .set { indexed_reference }
        }
    }

    // When reference is a graph, produce statistics
    if ( reference_type != "linear" && reference_stats == true ) {
        GRAPH_STATISTICS (
            reference
        )
        stats = GRAPH_STATISTICS.out.ch_graph_stats
    }

    // When reference is linear, produce fai index & statistics
    if ( reference_type == "linear" && reference_stats == true ) {
        SAMTOOLS_FAIDX (
            reference
        )
        stats   = SAMTOOLS_FAIDX.out.ch_fai
        ref_fai = SAMTOOLS_FAIDX.out.ch_ref_fai
    } else if ( reference_type == "linear" && reference_stats == false ) {
        SAMTOOLS_FAIDX (
            reference
        )
        ref_fai = SAMTOOLS_FAIDX.out.ch_ref_fai
    }

    // Get and assign reference fasta channel if it's required
    if ( workflow_steps.any { it in ['graph_genotype', 'reads_genotype', 'variant_call', 'profile_pmd'] } ) {
        if ( reference_type != "linear") {
            GRAPH_EXTRACT (
                reference,
                paths
            )
            reference_fastas = GRAPH_EXTRACT.out.ch_reference_fastas
        } else if ( reference_type == "linear") {
            reference_fastas = ref_fai
        }
    }

    // When reference is a graph, compute snarls if required by downstream modules
    if ( reference_type != "linear") {
        if ( workflow_steps.any { it in ['graph_genotype', 'reads_genotype'] } ) {
            COMPUTE_SNARLS (
                reference
            )
            snarls = COMPUTE_SNARLS.out.ch_snarls
        }
    }

    emit:
    indexed_reference
    stats
    reference_fastas
    snarls

}
