process SAMTOOLS_FAIDX {

    tag "$reference"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.22.1--h96c455f_0' :
        'biocontainers/samtools:1.22.1--h96c455f_0' }"

    input:
    path (reference)

    output:
    path ("*.fai")                        , emit: ch_fai
    tuple path (reference), path ("*.fai"), emit: ch_ref_fai
    tuple val(task.process), val('samtools'), eval('samtools version | head -n 1 | sed "s/samtools //"'), topic: versions

    script:
    def args = task.ext.args ?: ''

    """
    samtools \\
        faidx \\
        $reference \\
        $args
    """

}
