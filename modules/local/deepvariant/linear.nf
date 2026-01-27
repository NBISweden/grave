process LINEAR_DEEPVARIANT {

    tag "${meta.id}"
    label 'process_high'
    container 'docker.io/google/deepvariant:1.9.0'

    input:
    tuple path(reference_fasta), path(fasta_index)
    tuple val(meta), path(bams), path(indexes)

    output:
    tuple val(meta), path("*.vcf.gz"), emit: ch_raw_deepvariant_vcf
    tuple val(meta), path("*.html")  , emit: ch_deepvariant_html
    tuple val(task.process), val('deepvariant'), eval('/opt/deepvariant/bin/run_deepvariant --version 2>/dev/null | sed "s/.*version //"'), topic: versions

    script:
    def args = task.ext.args ?: ''

    """
    # Run DeepVariant
    /opt/deepvariant/bin/run_deepvariant \
        --num_shards ${task.cpus} \
        --sample_name ${meta.id} \
        --ref ${reference_fasta} \
        --reads ${bams} \
        --output_vcf ${meta.id}.raw.vcf.gz \
        --vcf_stats_report \
        --model_type ${params.deepVariantModelType}
    """

}
