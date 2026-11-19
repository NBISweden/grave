process PROCESS_DEEPVARIANT {

    tag "${meta.id}"
    label 'process_low'
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
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
    def run_norm = params.multiple_references ?
        """
        # Loop through each reference sample
        for i in *.paths
            do
                PREFIX=`echo \$i | sed 's/\\.paths//'`
                norm \$PREFIX.fasta ${meta.id}.\$PREFIX.raw.vcf.gz ${meta.id}.\$PREFIX.norm.vcf.gz
            done
        """ :
        "norm ${reference_fasta} ${deepvariant_vcf} ${meta.id}.norm.vcf.gz" // Assume single reference sample
    """
    norm() {
        # Normalise and sort (no bubbles to pop in DeepVariant VC)
        bcftools norm -f \$1 \$2 | bcftools sort | bgzip --threads ${task.cpus} > \$3

        # Clean up
        if [ "${params.keepRawVcf}" != "true" ]
            then
                rm \$2
        fi
    }

    ${run_norm}
    """
}
