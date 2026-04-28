process GRAPH_DEEPVARIANT {

    tag "${meta.id}"
    // NOTE: memory handled in conf/tool_resources.config
    label 'process_high'
    container 'docker.io/google/deepvariant:pangenome_aware_deepvariant-1.9.0'

    input:
    path graph
    path ref_path_files
    tuple path(reference_fasta), path(fasta_index)
    tuple val(meta), path(bams), path(indexes)

    output:
    tuple val(meta), path("*.vcf.gz"), emit: ch_raw_deepvariant_vcf
    tuple val(meta), path("*.html")  , emit: ch_deepvariant_html
    tuple val(task.process), val('pangenome_aware_deepvariant'), eval('/opt/deepvariant/bin/run_pangenome_aware_deepvariant --version --model_type=WGS --ref=dummy --reads=dummy --pangenome=dummy --output_vcf=dummy 2>/dev/null | sed "s/.*version //"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def basename = graph.baseName - '.gbz'

    if (!params.multiple_references)	// Assume single reference sample
        """
        # Run DeepVariant
        /opt/deepvariant/bin/run_pangenome_aware_deepvariant \
            --num_shards ${task.cpus} \
            --sample_name_reads ${meta.id} \
            --ref ${reference_fasta} \
            --pangenome ${graph} \
            --reads ${bams} \
            --output_vcf ${meta.id}.raw.vcf.gz \
            --vcf_stats_report \
            --model_type ${params.deepVariantModelType}
        """

    else if (params.multiple_references)
        """
        # Run DeepVariant against each reference sample
        for i in *.paths
            do
                PREFIX=`echo \$i | sed 's/\\.paths//'`
                /opt/deepvariant/bin/run_pangenome_aware_deepvariant \
                    --num_shards ${task.cpus} \
                    --sample_name_reads ${meta.id} \
                    --ref \$PREFIX.fasta \
                    --pangenome ${graph} \
                    --reads ${meta.id}.\$PREFIX.dedup.bam \
                    --output_vcf ${meta.id}.\$PREFIX.raw.vcf.gz \
                    --vcf_stats_report \
                    --model_type ${params.deepVariantModelType}
            done
        """

}
