include { MERGE } from '../../../modules/local/samtools/merge/main'

workflow MERGE_BAMS {

    take:
    paths
    mapped_bams

    main:
    // Group bams by sample
    sample_grouped_bams = mapped_bams
        // Extract grouping metadata (sample id & type)
        .map{ meta, bams -> [meta.subMap('id','type'), meta.subMap('read_group'), bams] }
        .groupTuple() // Group by sample
        .map{ meta, readgroup, bams -> [meta, readgroup, bams.flatten()] } // Flatten nested lists (multi ref)
    // Merge bams
    MERGE(
        paths,
        sample_grouped_bams
    )

    emit:
    merged_bams = MERGE.out.ch_merged_bams

}
