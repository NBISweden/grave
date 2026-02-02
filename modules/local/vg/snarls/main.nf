process COMPUTE_SNARLS {

    tag "${graph.baseName}_graph"
    label 'process_medium'
    // NOTE: update version string manually
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/vg:1.70.0--6aa72998bf6738ae' :
        'community.wave.seqera.io/library/vg:1.70.0--601cb9ffed863393' }"
    storeDir { graph.toRealPath().parent.resolve("${graph.baseName}_indexes/snarls") }

    input:
    path graph

    output:
    path "${graph}.snarls", emit: ch_snarls
    // NOTE: update version string manually
    tuple val(task.process), val('vg'), val('1.70.0'), topic: versions

    script:
    def args = task.ext.args ?: ''
    """
    # Compute graph snarls for genotyping tasks
    vg snarls -t ${task.cpus} --include-trivial ${graph} > ${graph}.snarls
    """

}
