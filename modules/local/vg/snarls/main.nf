process COMPUTE_SNARLS {

    tag "${graph.baseName}_graph"
    // NOTE: memory handled in conf/tool_resources.config
    label 'process_medium'
    // NOTE: update version string manually
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/vg:1.73.0--645b5a4f32c11ace' :
        'community.wave.seqera.io/library/vg:1.73.0--e9dad0f50dfcdf46' }"
    storeDir { graph.toRealPath().parent.resolve("${graph.baseName}_snarls") }

    input:
    path graph

    output:
    path "${graph}.snarls", emit: ch_snarls
    // NOTE: update version string manually
    tuple val(task.process), val('vg'), val('1.73.0'), topic: versions

    script:
    def args = task.ext.args ?: ''
    """
    # Compute graph snarls for genotyping tasks
    vg snarls -t ${task.cpus} --include-trivial ${graph} > ${graph}.snarls
    """

}
