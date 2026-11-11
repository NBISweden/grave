include { INDEX_DIST                 } from '../../../modules/local/vg/index_dist/main'
include { INDEX_RINDEX               } from '../../../modules/local/vg/index_ri/main'
include { INDEX_MINIMIZER            } from '../../../modules/local/vg/minimizer/main'
include { INDEX_HAPLOTYPES           } from '../../../modules/local/vg/haplotypes/main'
include { BWA_INDEX                  } from '../../../modules/nf-core/bwa/index/main'
include { GALN_INDEX                 } from '../../../modules/local/galn/index/main'
include { BWAMEM3_INDEX              } from '../../../modules/nf-core/bwamem3/index/main'
include { GRAPH_STATISTICS           } from '../../../modules/local/vg/stats/main'
include { SAMTOOLS_FAIDX             } from '../../../modules/nf-core/samtools/faidx/main'
include { GRAPH_EXTRACT              } from '../../../modules/local/vg/paths/main'
include { COMPUTE_SNARLS             } from '../../../modules/local/vg/snarls/main'

workflow REFERENCE_UTILITIES {

    take:
    workflow_steps
    gpu_giraffe
    gpu_bwa_aln
    reference_type
    reference_stats
    reference
    sample_types
    paths

    main:
    indexed_reference      = channel.empty()
    indexed_reference_mem3 = channel.empty()
    stats                  = channel.empty()
    reference_fastas       = channel.empty()
    snarls                 = channel.empty()

    // If indexing is requested, index appropriately based on the reference type
    if ( 'index' in workflow_steps) {
        // One index per sample type present (keyed on that type's parameters in the store)
        index_types = sample_types.flatMap { types -> types == 'both' ? ['ancient', 'modern'] : [types] }
        if ( reference_type == "unfiltered_graph" ) {
            INDEX_DIST (
                reference
            )
            INDEX_RINDEX (
                reference
            )
            INDEX_HAPLOTYPES (
                reference
                    .combine(INDEX_DIST.out.ch_dist)
                    .combine(INDEX_RINDEX.out.ch_ri)
                    .combine(index_types)
            )
            reference
                .combine(INDEX_HAPLOTYPES.out.ch_hapl.collect())
                .collect() // value channel so every library can reuse it
                .map { element -> [ref: element[0], indexes: element[1..-1]] }
                .set { indexed_reference }
        } else if ( reference_type == "filtered_graph" ) {
            INDEX_DIST (
                reference
            )
            INDEX_MINIMIZER (
                reference
                    .combine(INDEX_DIST.out.ch_dist)
                    .combine(index_types)
            )
            reference
                .combine(INDEX_DIST.out.ch_dist.mix(INDEX_MINIMIZER.out.ch_minimizer).collect())
                .collect() // value channel so every library can reuse it
                .map { element -> [ref: element[0], indexes: element[1..-1]] }
                .set { indexed_reference }
        } else if ( reference_type == "linear" ) {
            // Index for BWA aln only when ancient libraries are present
            reference
                .combine(sample_types)
                .filter { _ref, types -> types in ['ancient', 'both'] }
                .map { ref, _types -> ref }
                .set { aln_reference }
            if ( gpu_bwa_aln ) {
                GALN_INDEX (
                    aln_reference
                )
                bwa_index = GALN_INDEX.out.ch_bwa_index
            } else {
                BWA_INDEX (
                    aln_reference
                )
                bwa_index = BWA_INDEX.out.ch_bwa_index
            }
            reference
                .combine(bwa_index)
                .collect()
                .map { element ->
                    [ref: element[0], indexes: element[1..-1]]
                }
                .set { indexed_reference }
            // Index for BWA-MEM3 only when modern libraries are present
            reference
                .combine(sample_types)
                .filter { _ref, types -> types in ['modern', 'both'] }
                .map { ref, _types -> ref }
                .set { mem_reference }
            BWAMEM3_INDEX (
                mem_reference
            )
            reference
                .combine(BWAMEM3_INDEX.out.ch_bwamem3_index)
                .collect()
                .map { element ->
                    [ref: element[0], indexes: element[1..-1]]
                }
                .set { indexed_reference_mem3 }
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
    indexed_reference_mem3
    stats
    reference_fastas
    snarls

}
