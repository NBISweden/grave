process FREEBAYES {

    tag "${meta.id}"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/bamtools_bcftools_freebayes_htslib:0a559cef58513a6f' :
        'community.wave.seqera.io/library/bamtools_bcftools_freebayes_htslib:4a6a1795bbef9fd5' }"

    input:
    path ref_path_files
    tuple path(reference_fasta), path(fasta_index)
    tuple val(meta), path(bams), path(indexes)

    output:
    path("*.norm.vcf.gz"), emit: ch_freebayes_norm_vcf
    path("*.raw.vcf.gz"), optional: true, emit: ch_freebayes_raw_vcf
    tuple val(task.process), val('freebayes'), eval('freebayes --version | sed "s/version.*v//"'), topic: versions
    tuple val(task.process), val('htslib'), eval('bgzip --version | head -n 1 | sed "s/.* //"'), topic: versions
    tuple val(task.process), val('bcftools'), eval('bcftools version | head -n 1 | sed "s/.* //"'), topic: versions

    script:
    def args = task.ext.args ?: ''

    if (!params.multiple_references) // Assume single reference sample (this setting forced in 'linear' mode).
        """
        freebayes -f ${reference_fasta} \\
            --genotype-qualities \\
            --min-alternate-count ${params.minimumAlleleSupport} \\
            --min-alternate-fraction ${params.minFraction} \\
            --ploidy ${params.samplePloidy} \\
            --max-complex-gap ${params.maxComplexGap} \\
            ${bams} | \\
            bgzip --threads ${task.cpus} > \\
            ${meta.id}.raw.vcf.gz

        bcftools norm -f ${reference_fasta} ${meta.id}.raw.vcf.gz | bcftools sort | bgzip --threads ${task.cpus} > ${meta.id}.norm.vcf.gz

        # Clean up
        if [ "${params.keepRawVcf}" != "true" ]
            then
                rm ${meta.id}.raw.vcf.gz
        fi
        """

    else if (params.multiple_references)
        """
        for i in *.paths
            do
                PREFIX=`echo \$i | sed 's/\\.paths//'`
                freebayes -f \$PREFIX.fasta \\
                    --genotype-qualities \\
                    --min-alternate-count ${params.minimumAlleleSupport} \\
                    --min-alternate-fraction ${params.minFraction} \\
                    --ploidy ${params.samplePloidy} \\
                    --max-complex-gap ${params.maxComplexGap} \\
                    ${meta.id}.\$PREFIX.dedup.bam | \\
                    bgzip --threads ${task.cpus} > \\
                    ${meta.id}.\$PREFIX.raw.vcf.gz

                bcftools norm -f \$PREFIX.fasta ${meta.id}.\$PREFIX.raw.vcf.gz | bcftools sort | bgzip --threads ${task.cpus} > ${meta.id}.\$PREFIX.norm.vcf.gz

                if [ "${params.keepRawVcf}" != "true" ]
                    then
                        rm ${meta.id}.\$PREFIX.raw.vcf.gz
                fi
            done
        """

}
