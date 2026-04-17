process RENAME_SAMPLES {

    tag "${meta.read_group}"

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
