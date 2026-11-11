process INDEX_DIST {

    tag "${graph.baseName}_graph"
    label 'process_high_memory'
    // NOTE: update version strings manually (due to use of storedir). GPU giraffe lags behind vg CPU baseline -> use the parabricks-compatible vg and a separate store
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        (params.gpu_giraffe ? 'oras://community.wave.seqera.io/library/vg:1.70.0--e551f543615b3bad' : 'oras://community.wave.seqera.io/library/vg:1.73.0--645b5a4f32c11ace') :
        (params.gpu_giraffe ? 'community.wave.seqera.io/library/vg:1.70.0--f0e005bd33f23d2f' : 'community.wave.seqera.io/library/vg:1.73.0--e9dad0f50dfcdf46') }"
    // Distance index depends only on the graph and nested-distance setting
    storeDir { graph.toRealPath().parent.resolve("${graph.baseName}_indexes${params.gpu_giraffe ? '_gpu' : ''}/dist${params.noNestedDistance ? '_no-nested-distance' : ''}") }

    input:
    path (graph)

    output:
    path ("${graph.baseName}.dist"), emit: ch_dist
    tuple val(task.process), val('vg'), val(params.gpu_giraffe ? '1.70.0' : '1.73.0'), topic: versions

    script:
    def args     = task.ext.args ?: ''
    def basename = graph.baseName - '.gbz'

    """
    vg index --threads ${task.cpus} ${args} --dist-name ${basename}.dist ${graph}
    """

}
