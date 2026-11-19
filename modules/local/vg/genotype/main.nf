process GENOTYPE_READS {

    tag "${meta.id}"
    // NOTE: time & memory handled in conf/tool_resources.config
    label 'process_medium'
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
            'oras://community.wave.seqera.io/library/bcftools_htslib_samtools_vcfbub_vg:f474eaae146f7cf0' :
            'community.wave.seqera.io/library/bcftools_htslib_samtools_vcfbub_vg:7f95ea15fb262fe1' }"

    input:
    path graph
    path snarls
    path ref_path_files
    tuple path(reference_fasta), path(index)
    tuple val(meta), path(gams)

    output:
    path "*.filtered.vcf.gz", emit: ch_vg_genotype_filtered_vcf
    path "*.raw.vcf.gz", optional: true, emit: ch_vg_genotype_raw_vcf
    tuple val(task.process), val('bcftools'), eval('bcftools version | head -n 1 | sed "s/.* //"'), topic: versions
    tuple val(task.process), val('htslib'), eval('tabix --version | head -n 1 | sed "s/.* //"'), topic: versions
    tuple val(task.process), val('samtools'), eval('samtools version | head -n 1 | sed "s/samtools //"'), topic: versions
    tuple val(task.process), val('vcfbub'), eval('vcfbub --version | sed "s/.* //"'), topic: versions
    tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

    script:
    def gamFiles = gams instanceof Collection ? gams : [gams]
    def gamCount = gamFiles.size()

    def run_genotype = params.multiple_references ?
        """
        # Loop through each reference sample
        for i in *.paths
            do
                PREFIX=`echo \$i | sed 's/\\.paths//'`
                genotype \$PREFIX.fasta ${meta.id}.\$PREFIX "--ref-sample \$PREFIX"
            done
        """ :
        "genotype ${reference_fasta} ${meta.id} ''" // Default: genotype against all reference paths in the graph
    """
    genotype() {
        # References will have PanSN format, raw VCFs produced by vg call won't. Convert references to align with VCF naming & reindex
        sed -i 's/.*#/>/g' \$1
        rm \$1.fai && samtools faidx \$1

        # Genotype against the reference paths in the graph (a specific reference sample, if requested)
        vg call -t ${task.cpus} ${graph} --pack ${meta.id}.filtered.pack \$3 --min-support ${params.minimumAlleleSupport},${params.minimumSiteSupport} --baseline-error ${params.baselineErrorSmallVariants},${params.baselineErrorLargeVariants} --snarls ${snarls} --sample ${meta.id} --genotype-snarls --all-snarls --gbz-translation --gbz --ploidy ${params.samplePloidy} | bgzip --threads ${task.cpus} > \$2.raw.vcf.gz

        # Index raw VCF
        tabix -p vcf \$2.raw.vcf.gz

        # Pop bubbles
        vcfbub --input \$2.raw.vcf.gz --max-level ${params.maxNestLevel} --max-ref-length ${params.maxRefLength} | bcftools norm -f \$1 | bcftools sort | bgzip --threads ${task.cpus} > \$2.filtered.vcf.gz

        # Clean up
        if [ "${params.keepRawVcf}" != "true" ]
            then
                rm \$2.raw.vcf.gz \$2.raw.vcf.gz.tbi
            else
                rm \$2.raw.vcf.gz.tbi
        fi
        rm \$1*
    }

    # Concatenate GAMs if multiple libraries per sample
    if (( ${gamCount} == 1 )); then
        echo "Only one GAM file for sample ${meta.id}, skipping merge"
        mv ${gams} ${meta.id}.merged.gam
    else
        echo "Merging ${gamCount} GAM files for sample ${meta.id}"
        cat ${gams} > ${meta.id}.merged.gam
    fi

    # Compute read support
    vg pack -t ${task.cpus} -x ${graph} -g ${meta.id}.merged.gam -o ${meta.id}.filtered.pack -Q 5

    # Remove merged GAM for disk economy (unless symlink, i.e., only one input GAM)
    if [ -f ${meta.id}.merged.gam ] && [ ! -L ${meta.id}.merged.gam ]; then
        rm ${meta.id}.merged.gam
    fi

    ${run_genotype}

    rm *.filtered.pack
    """
}
