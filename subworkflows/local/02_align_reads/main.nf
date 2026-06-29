//include { GPU_PREPROCESS           } from '../../../modules/local/vg/gpu_preprocess/main'
include { GPU_GIRAFFE              } from '../../../modules/local/parabricks/vg_giraffe/main'
include { SAMTOOLS_FILTER_GPU      } from '../../../modules/local/samtools/filter_gpu/main'
include { GIRAFFE                  } from '../../../modules/local/vg/giraffe/main'
include { GAM_TO_TAGGED_SORTED_BAM } from '../../../modules/local/vg/surject/main'
include { BWA_ALN_SAMSE            } from '../../../modules/nf-core/bwa/aln/main'
include { BWA_MEM                  } from '../../../modules/nf-core/bwa/mem/main'

workflow ALIGN_READS {

    take:
    gpu_giraffe
    reference_type
    paths
    fastp_reads
    reference
    indexed_reference

    main:
    mapped_gam       = channel.empty()
    failed_libraries = channel.empty()
    raw_gam          = channel.empty()
    alignment_stats  = channel.empty()
    mapped_bam       = channel.empty()

    // Input reference is a pangenome graph
    if ( reference_type == "unfiltered_graph" || reference_type == "filtered_graph" ) {
        // User requested GPU accelerated giraffe
        if ( gpu_giraffe ) {
            // Unfiltered graphs require preprocessing with the same vg version used in parabricks
            if ( reference_type == "unfiltered_graph" ) {
                // // Create unfiltered graph indexes
                // GPU_PREPROCESS (
                //     fastp_reads,
                //     indexed_reference
                // )
                // // Run giraffe
                // GPU_GIRAFFE (
                //     // Inputs
                // )
            // Filtered graph indexes are already computed
            } else if ( reference_type == "filtered_graph" ) {
                // Run giraffe
                GPU_GIRAFFE (
                    fastp_reads,
                    indexed_reference
                )
                // Apply alignment filters to BAM output
                SAMTOOLS_FILTER_GPU (
                    GPU_GIRAFFE.out.ch_bams
                )
                // Branch passed/failed libraries
                SAMTOOLS_FILTER_GPU.out.ch_surjected_bam_counts
                    .branch { meta, bam, alignment_count ->
                        passed: alignment_count.toInteger() > 0
                            return [ meta, bam ]
                        failed: alignment_count.toInteger() == 0
                            return [ meta, bam ]
                    }
                    .set { branched_bam }
                mapped_bam       = branched_bam.passed
                failed_libraries = branched_bam.failed
                alignment_stats  = SAMTOOLS_FILTER_GPU.out.ch_surjected_bam_stats
            }
        // Running base giraffe (default, uses CPUs)
        } else {
            // Run giraffe
            GIRAFFE (
                fastp_reads,
                indexed_reference
            )
            // Branch passed/failed libraries to separate channels
            GIRAFFE.out.ch_gam_counts
                .branch { meta, gam, alignment_count ->
                    passed: alignment_count.toInteger() > 0
                        return [ meta, gam ]
                    failed: alignment_count.toInteger() == 0
                        return [ meta, gam ]
                }
                .set { branched_gam }
            mapped_gam       = branched_gam.passed
            failed_libraries = branched_gam.failed
            raw_gam          = GIRAFFE.out.ch_raw_gam
            gam_stats        = GIRAFFE.out.ch_gam_stats
            // Surject GAM to BAM, add read groups, apply BAM filters
            GAM_TO_TAGGED_SORTED_BAM (
                reference,
                paths,
                mapped_gam
            )
            mapped_bam      = GAM_TO_TAGGED_SORTED_BAM.out.ch_surjected_bams
            alignment_stats = gam_stats.mix(GAM_TO_TAGGED_SORTED_BAM.out.ch_surjected_bam_stats)
        }
    // Input reference is a linear assembly
    } else if ( reference_type == "linear" ) {
        // Split libraries by type
        fastp_reads
            .branch { meta, reads ->
                ancient: meta.type == "ancient"
                modern:  meta.type == "modern"
                return tuple( meta, reads )
            }
            .set { reads }
        // Run BWA aln and samse for ancient libraries (always pre-merged)
        BWA_ALN_SAMSE (
            reads.ancient,
            indexed_reference
        )
        // Run BWA mem for modern libraries
        BWA_MEM (
            reads.modern,
            indexed_reference,
        )
        // Mix outputs
        mapped_bam      = BWA_ALN_SAMSE.out.ch_bam.mix(BWA_MEM.out.ch_bam)
        alignment_stats = BWA_ALN_SAMSE.out.ch_flagstat.mix(BWA_MEM.out.ch_flagstat)
    }

    emit:
    mapped_gam       = mapped_gam
    failed_libraries = failed_libraries
    raw_gam          = raw_gam
    alignment_stats  = alignment_stats
    mapped_bam       = mapped_bam

}
