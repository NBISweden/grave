process FASTQC {

    tag "${meta.read_group}"
    label 'process_low'
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastqc:0.12.1--hdfd78af_0' :
        'biocontainers/fastqc:0.12.1--hdfd78af_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple path("*fastqc.zip"), path("*.html"), emit: ch_fastqc
    tuple val(task.process), val('fastqc'), eval('fastqc --version | sed "s/.* v//"'), topic: versions

    script:
    def args = task.ext.args ?: ''

    """
    fastqc --format fastq --threads ${task.cpus} ${reads} ${args}
    """

}
