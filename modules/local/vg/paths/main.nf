process GRAPH_EXTRACT {

    tag "${graph.baseName}_graph"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/samtools_vg:a6632ebd35c760c0' :
        'community.wave.seqera.io/library/samtools_vg:519b6ec44480b658' }"

    input:
    path graph
    path ref_path_files

    output:
    tuple path("*.fasta"), path("*.fasta.fai"), emit: ch_reference_fastas
    tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions
    tuple val(task.process), val('samtools'), eval('samtools version | head -n 1 | sed "s/samtools //"'), topic: versions

    script:
    def args = task.ext.args ?: ''

    if (!params.multiple_references) // Single reference sample, extract all reference paths
    """
    # Extract reference sample paths as FASTA
    vg paths --reference-paths --extract-fasta -x ${graph} > reference.fasta
    # Index reference FASTA
    samtools faidx reference.fasta
    """

    else if (params.multiple_references) // Multiple reference samples, extract reference paths for each
    """
    # Extract provided reference paths as FASTA
    for i in *.paths
        do
            PREFIX=`echo \$i | sed 's/\\.paths//'`
            vg paths --paths-file \$i --extract-fasta -x ${graph} > \$PREFIX.fasta
        done
    # Index reference FASTAs
    for i in *.fasta
        do
            samtools faidx \$i
        done
    """

}
