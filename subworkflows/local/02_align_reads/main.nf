include { GIRAFFE                  } from '../../../modules/local/vg/giraffe/main'
include { GAM_TO_TAGGED_SORTED_BAM } from '../../../modules/local/vg/surject/main'

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
        error "ERROR: WORK IN PROGRESS for reference of type: ${reference_type}"
    }

    emit:
    mapped_gam      = mapped_gam
    raw_gam         = raw_gam
    alignment_stats = alignment_stats
    mapped_bam      = mapped_bam

}
