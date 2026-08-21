process SAMTOOLS_FILTER_GPU {

    // Receives BAM already surjected to reference paths, applies the same filters as the typical CPU workflow

    tag "${meta.read_group}"
    label 'process_medium'
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/samtools_vg:a6632ebd35c760c0' :
        'community.wave.seqera.io/library/samtools_vg:519b6ec44480b658' }"

    input:
    tuple val(meta), path(surjected_bam)

    output:
    tuple val(meta), path("${meta.read_group}*.mapped.*.bam"), env('ALIGNMENT_COUNT'), emit: ch_surjected_bam_counts
    tuple val(meta), path("*.bam.flagstats")                                         , emit: ch_surjected_bam_stats
    tuple val(task.process), val('samtools'), eval('samtools version | head -n 1 | sed "s/samtools //"'), topic: versions

    script:
    def args  = task.ext.args  ?: ''
    def args2 = task.ext.args2 ?: ''

    if (!params.multiple_references)
        """
        samtools view \\
            ${args} \\
            ${args2} \\
            --with-header \\
            --uncompressed \\
            ${surjected_bam} | \\
        samtools sort \\
            --threads ${task.cpus - 1} \\
            --output-fmt BAM \\
            - > \\
        ${meta.read_group}.mapped.MAPQ${params.minimumMapQFilter}.bam

        # Get stats
        samtools flagstat ${meta.read_group}.mapped.MAPQ${params.minimumMapQFilter}.bam > ${meta.read_group}.mapped.MAPQ${params.minimumMapQFilter}.bam.flagstats

        ALIGNMENT_COUNT=\$(head -n 1 ${meta.read_group}.mapped.MAPQ${params.minimumMapQFilter}.bam.flagstats | sed 's/ .*//')
        """

    else if (params.multiple_references)
        """

        """
}
