process SAMTOOLS_FAIDX {

    tag "$reference"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.22.1--h96c455f_0' :
        'biocontainers/samtools:1.22.1--h96c455f_0' }"

    input:
    path (reference)
    val get_sizes

    output:
    path ("*.fai")         , emit: ch_fai
    tuple val(task.process), val('samtools'), eval('samtools version | head -n 1 | sed "s/samtools //"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def get_sizes_command = get_sizes ? "cut -f 1,2 ${reference}.fai > ${reference}.sizes" : ''
    """
    samtools \\
        faidx \\
        $reference \\
        $args

    ${get_sizes_command}
    """

}
