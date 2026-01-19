include { PANGENOME_MAP            } from '../../../modules/local/vg/giraffe/main'
include { GAM_TO_TAGGED_SORTED_BAM } from '../../../modules/local/vg/surject/main'

workflow ALIGN_READS {

    take:
    reference_type
    paths
    fastp_reads
    reference
    indexed_reference

    main:
    // Run alignment to pangenome graph
    if ( reference_type == "unfiltered_graph" || reference_type == "filtered_graph" ) {
        PANGENOME_MAP(
            fastp_reads,
            indexed_reference
        ) // GAM output
        GAM_TO_TAGGED_SORTED_BAM(
            reference,
            paths,
            PANGENOME_MAP.out.ch_mapped_gam
        ) // BAM output
    // Run in linear reference mode
    } else if ( reference_type == "linear" ) {
        error "ERROR: WORK IN PROGRESS for reference of type: ${reference_type}"
    }

    // Mix bams
    GAM_TO_TAGGED_SORTED_BAM.out.ch_surjected_bams
        // TODO .mix with linear ()
        .set { ch_mapped_bam }

    emit:
    mapped_bams = ch_mapped_bam

}
