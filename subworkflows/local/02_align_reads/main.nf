include { GIRAFFE                  } from '../../../modules/local/vg/giraffe/main'
include { GAM_TO_TAGGED_SORTED_BAM } from '../../../modules/local/vg/surject/main'
include { BWA_ALN_SAMSE            } from '../../../modules/nf-core/bwa/aln/main'
include { BWA_MEM                  } from '../../../modules/nf-core/bwa/mem/main'

workflow ALIGN_READS {

    take:
    reference_type
    paths
    fastp_reads
    reference
    indexed_reference

    main:
    mapped_gam = channel.empty()
    raw_gam    = channel.empty()
    alignment_stats = channel.empty()
    mapped_bam = channel.empty()

    // Run alignment to pangenome graph
    if ( reference_type == "unfiltered_graph" || reference_type == "filtered_graph" ) {
        GIRAFFE (
            fastp_reads,
            indexed_reference
        )
        mapped_gam      = GIRAFFE.out.ch_mapped_gam
        raw_gam         = GIRAFFE.out.ch_raw_gam
        alignment_stats = GIRAFFE.out.ch_alignment_stats
        GAM_TO_TAGGED_SORTED_BAM (
            reference,
            paths,
            mapped_gam
        )
        mapped_bam = GAM_TO_TAGGED_SORTED_BAM.out.ch_surjected_bams
    // Run in linear reference mode
    } else if ( reference_type == "linear" ) {
        // Split samples by type
        fastp_reads
            .branch { meta, reads ->
                ancient: meta.type == "ancient"
                modern:  meta.type == "modern"
                return tuple( meta, reads )
            }
            .set { reads }
        // Run BWA aln and samse for ancient samples (always pre-merged)
        BWA_ALN_SAMSE (
            reads.ancient,
            indexed_reference
        )
        // Run BWA mem for modern samples
        BWA_MEM (
            reads.modern,
            indexed_reference,
        )
        // Mix outputs
        mapped_bam = BWA_ALN_SAMSE.out.ch_bam.mix(BWA_MEM.out.ch_bam)
        alignment_stats = BWA_ALN_SAMSE.out.ch_flagstat.mix(BWA_MEM.out.ch_flagstat)
    }

    emit:
    mapped_gam      = mapped_gam
    raw_gam         = raw_gam
    alignment_stats = alignment_stats
    mapped_bam      = mapped_bam

}
