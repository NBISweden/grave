include { GENOTYPE_GRAPH } from '../../../modules/local/vg/deconstruct/main'
include { GENOTYPE_READS } from '../../../modules/local/vg/genotype/main'

workflow GENOTYPE {

    take:
    workflow_steps
    reference
    snarls
    paths
    reference_fastas
    mapped_gam

    main:
    graph_filtered_vcf = channel.empty()
    graph_raw_vcf      = channel.empty()
    reads_filtered_vcf = channel.empty()
    reads_raw_vcf      = channel.empty()

    // Genotype variants found in the graph
    if ( 'graph_genotype' in workflow_steps ) {
        GENOTYPE_GRAPH (
            reference,
            snarls,
            paths,
            reference_fastas
        )
        graph_filtered_vcf = GENOTYPE_GRAPH.out.ch_vg_deconstruct_filtered_vcf
        graph_raw_vcf      = GENOTYPE_GRAPH.out.ch_vg_deconstruct_raw_vcf
    }

    // Genotype reads against the graph
    if ( 'reads_genotype' in workflow_steps ) {
        GENOTYPE_READS (
            reference,
            snarls,
            paths,
            reference_fastas,
            mapped_gam
                .map { meta, gam -> [meta.subMap('id'), gam] }
                .groupTuple()
        )
        reads_filtered_vcf = GENOTYPE_READS.out.ch_vg_genotype_filtered_vcf
        reads_raw_vcf      = GENOTYPE_READS.out.ch_vg_genotype_raw_vcf
    }

    emit:
    graph_filtered_vcf
    graph_raw_vcf
    reads_filtered_vcf
    reads_raw_vcf

}
