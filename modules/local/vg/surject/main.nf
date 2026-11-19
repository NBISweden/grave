process GAM_TO_TAGGED_SORTED_BAM {

    // Projects GAM mappings to BAM against reference paths. If no user path files provided, uses vg defaults. If paths provided, each set is surjected to separately.

    tag "${meta.read_group}"
    label 'process_medium'
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/samtools_vg:a6632ebd35c760c0' :
        'community.wave.seqera.io/library/samtools_vg:519b6ec44480b658' }"

    input:
    path graph
    path ref_path_files
    tuple val(meta), path(mapped_gam)

    output:
    tuple val(meta), path("${meta.read_group}*.bam"), emit: ch_surjected_bams
    tuple val(meta), path("*.bam.flagstats")        , emit: ch_surjected_bam_stats
    tuple val(task.process), val('vg')      , eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions
    tuple val(task.process), val('samtools'), eval('samtools version | head -n 1 | sed "s/samtools //"')       , topic: versions

    script:
    def args = task.ext.args ?: ''
    def interleaved = meta.type == 'modern' && !meta.merged ? '--interleaved' : '' // Modern unmerged GAMs are interleaved
    def run_surject = params.multiple_references ?
        """
        # Surject to each user provided list of reference paths
        for i in *.paths
            do
                PREFIX=`echo \$i | sed 's/\\.paths//'`
                surject ${meta.read_group}.\$PREFIX --into-paths \$i
            done
        """ :
        "surject ${meta.read_group}"
    """
    surject() {
        OUT=\$1
        shift

        # Surject GAM, add read group tags, remove unsurjected (if requested), coordinate sort
        vg surject \\
            -t ${task.cpus} \\
            -x ${graph} \\
            ${interleaved} \\
            --bam-output \\
            "\$@" \\
            ${mapped_gam} | \\
        samtools addreplacerg \\
            --threads ${task.cpus} \\
            -u \\
            --output-fmt BAM \\
            -r '@RG\\tID:${meta.read_group}\\tLB:${meta.library}\\tSM:${meta.id}' \\
            - | \\
        samtools view \\
            ${args} \\
            --with-header \\
            --uncompressed \\
            - | \\
        samtools sort \\
            --threads ${task.cpus} \\
            --output-fmt BAM \\
            - > \\
        \$OUT.bam

        # Get stats on what survived surjection
        samtools flagstat \$OUT.bam > \$OUT.bam.flagstats
    }

    ${run_surject}
    """
}
