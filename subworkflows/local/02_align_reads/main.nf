include { GIRAFFE                  } from '../../../modules/local/vg/giraffe/main'
include { GPU_GIRAFFE              } from '../../../modules/local/parabricks/vg_giraffe/main'
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

    // Run alignment to pangenome graph
    if ( reference_type == "unfiltered_graph" || reference_type == "filtered_graph" ) {
        if ( gpu_giraffe ) {
            // Run GPU accelerated Giraffe
            GPU_GIRAFFE (
                fastp_reads,
                indexed_reference
            )
        } //else {
            // Run CPU Giraffe
            GIRAFFE (
                fastp_reads,
                indexed_reference
            )
        //}

        //TODO mix outputs from GPU and CPU Giraffe. Unsure if parabricks has the other tooling, or if GPU needs separate module for stats/filtering etc.

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

        GAM_TO_TAGGED_SORTED_BAM (
            reference,
            paths,
            mapped_gam
        )
        mapped_bam      = GAM_TO_TAGGED_SORTED_BAM.out.ch_surjected_bams
        alignment_stats = gam_stats.mix(GAM_TO_TAGGED_SORTED_BAM.out.ch_surjected_bam_stats)

    // Run in linear reference mode
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
