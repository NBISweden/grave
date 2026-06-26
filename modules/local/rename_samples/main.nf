process RENAME_SAMPLES {

    tag "${meta.read_group}"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.22.1--h96c455f_0' :
        'biocontainers/samtools:1.22.1--h96c455f_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fq.gz"), emit: ch_renamed_reads

    script:
    def args = task.ext.args ?: ''

    if (meta.merged == false)
        """
        ln -s ${reads[0]} ${meta.read_group}_R1.fq.gz
        ln -s ${reads[1]} ${meta.read_group}_R2.fq.gz
        """

    else if (meta.merged == true)
        """
        ln -s ${reads[0]} ${meta.read_group}.fq.gz
        """

}
