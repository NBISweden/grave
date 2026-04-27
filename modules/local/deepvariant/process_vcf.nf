process PROCESS_DEEPVARIANT {

    tag "${meta.id}"
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'oras://community.wave.seqera.io/library/bcftools_htslib_samtools_vcfbub_vg:f474eaae146f7cf0' :
            'community.wave.seqera.io/library/bcftools_htslib_samtools_vcfbub_vg:7f95ea15fb262fe1' }"

    input:
    path ref_path_files
    tuple path(reference_fasta), path(index)
    tuple val(meta), path(deepvariant_vcf)

    output:
    path "*.norm.vcf.gz", emit: ch_deepvariant_norm_vcf
    path "*.raw.vcf.gz", optional: true, emit: ch_deepvariant_raw_vcf
    tuple val(task.process), val('bcftools'), eval('bcftools version | head -n 1 | sed "s/.* //"'), topic: versions
    tuple val(task.process), val('htslib'), eval('bgzip --version | head -n 1 | sed "s/.* //"'), topic: versions

    script:
    def args = task.ext.args ?: ''

    if (!params.multiple_references)	// Assume single reference sample
        """
        # Normalise and sort (no bubbles to pop in DeepVariant VC)
        bcftools norm -f ${reference_fasta} ${deepvariant_vcf} | bcftools sort | bgzip --threads ${task.cpus} > ${meta.id}.norm.vcf.gz

        # Clean up
        if [ "${params.keepRawVcf}" != "true" ]
            then
                rm ${deepvariant_vcf}
        fi
        """

    else if (params.multiple_references)
        """
        # Loop through each reference sample
        for i in *.paths
            do
                PREFIX=`echo \$i | sed 's/\\.paths//'`
                # Normalise and sort (no bubbles to pop in DeepVariant VC)
                bcftools norm -f \$PREFIX.fasta ${meta.id}.\$PREFIX.raw.vcf.gz | bcftools sort | bgzip --threads ${task.cpus} > ${meta.id}.\$PREFIX.norm.vcf.gz

                # Clean up
                if [ "${params.keepRawVcf}" != "true" ]
                    then
                        rm ${meta.id}.\$PREFIX.raw.vcf.gz
                fi
            done
        """

}
