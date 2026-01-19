process COMPUTE_SNARLS {

    tag "${graph.baseName}_graph"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/vg:1.70.0--6aa72998bf6738ae' :
        'community.wave.seqera.io/library/vg:1.70.0--601cb9ffed863393' }"
    storeDir { graph.toRealPath().parent.resolve("${graph.baseName}_indexes/snarls") }

    input:
    path graph

    output:
    path "${graph}.snarls", emit: ch_snarls
    // PLANNED: enable topic channel once Nextflow bug resolved
    //tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    """
    # Compute graph snarls for genotyping tasks
    vg snarls -t ${task.cpus} --include-trivial ${graph} > ${graph}.snarls
    """

}
