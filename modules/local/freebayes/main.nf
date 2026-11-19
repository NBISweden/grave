process FREEBAYES_PARALLEL {

    tag "${meta.id}"
    // NOTE: cpus & memory handled in conf/tool_resources.config
    label 'process_high'
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/bamtools_bcftools_freebayes_htslib:0a559cef58513a6f' :
        'community.wave.seqera.io/library/bamtools_bcftools_freebayes_htslib:4a6a1795bbef9fd5' }"

    input:
    path ref_path_files
    tuple path(reference_fasta), path(fasta_index)
    tuple val(meta), path(bams), path(indexes)

    output:
    path("*.norm.vcf.gz"), emit: ch_freebayes_norm_vcf
    path("*.raw.vcf.gz"), optional: true, emit: ch_freebayes_raw_vcf
    tuple val(task.process), val('bamtools'), eval('bamtools --version | head -n 2 | tail -n 1 | sed "s/bamtools //"'), topic: versions
    tuple val(task.process), val('freebayes'), eval('freebayes --version | sed "s/version.*v//"'), topic: versions
    tuple val(task.process), val('htslib'), eval('bgzip --version | head -n 1 | sed "s/.* //"'), topic: versions
    tuple val(task.process), val('bcftools'), eval('bcftools version | head -n 1 | sed "s/.* //"'), topic: versions

    script:
    def run_freebayes = params.multiple_references ?
        """
        # Run FreeBayes workflow against each reference sample
        for i in *.paths
            do
                PREFIX=`echo \$i | sed 's/\\.paths//'`
                freebayes_workflow \$PREFIX.fasta \$PREFIX.fasta.fai ${meta.id}.\$PREFIX.dedup.bam ${meta.id}.\$PREFIX ${meta.id}.\$PREFIX.regions
            done
        """ :
        "freebayes_workflow ${reference_fasta} ${fasta_index} ${bams} ${meta.id} ${reference_fasta}.regions" // Assume single reference sample (this setting forced in 'linear' mode)
    """
    freebayes_workflow() {
        # Generate equal coverage regions for parallelization
        bamtools coverage -in \$3 | coverage_to_regions.py \$2 500 > \$5

        # Run FreeBayes
        freebayes-parallel \$5 \
            ${task.cpus} \
            --genotype-qualities \
            --fasta-reference \$1 \
            --min-alternate-count ${params.minimumAlleleSupport} \
            --min-alternate-fraction ${params.minFraction} \
            --ploidy ${params.samplePloidy} \
            --max-complex-gap ${params.maxComplexGap} \
            \$3 | \
            bgzip --threads ${task.cpus} > \
            \$4.raw.vcf.gz

        # Norm and sort
        bcftools norm -f \$1 \$4.raw.vcf.gz | bcftools sort | bgzip --threads ${task.cpus} > \$4.norm.vcf.gz

        # Clean up
        if [ "${params.keepRawVcf}" != "true" ]
            then
                rm \$4.raw.vcf.gz
        fi
        rm \$5
    }

    ${run_freebayes}
    """
}
