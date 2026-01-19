include { DEDUPLICATE } from '../../../modules/local/deduplicate/main'

workflow DEDUPLICATE_BAM {

    take:
    paths
    merged_bams

    main:
    // Deduplicate BAMs
    DEDUPLICATE(
        paths,
        merged_bams
    )

    emit:
    deduplicated_bams = DEDUPLICATE.out.ch_deduplicated_bams
    deduplication_metrics = DEDUPLICATE.out.ch_dedup_metrics

}
