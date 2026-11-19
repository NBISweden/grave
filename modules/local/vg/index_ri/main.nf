process INDEX_RINDEX {

    tag "${graph.baseName}_graph"
    label 'process_high_memory'
    // NOTE: update version strings manually (due to use of storedir). GPU giraffe lags behind vg CPU baseline -> use the parabricks-compatible vg and a separate store
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        (params.gpu_giraffe ? 'oras://community.wave.seqera.io/library/vg:1.70.0--e551f543615b3bad' : 'oras://community.wave.seqera.io/library/vg:1.73.0--645b5a4f32c11ace') :
        (params.gpu_giraffe ? 'community.wave.seqera.io/library/vg:1.70.0--f0e005bd33f23d2f' : 'community.wave.seqera.io/library/vg:1.73.0--e9dad0f50dfcdf46') }"
    // R-index depends only on the graph
    storeDir { graph.toRealPath().parent.resolve("${graph.baseName}_indexes${params.gpu_giraffe ? '_gpu' : ''}/ri") }

    input:
    path (graph)

    output:
    path ("${graph.baseName}.ri"), emit: ch_ri
    tuple val(task.process), val('vg'), val(params.gpu_giraffe ? '1.70.0' : '1.73.0'), topic: versions

    script:
    def basename = graph.baseName - '.gbz'

    """
    vg gbwt --num-threads ${task.cpus} --r-index ${basename}.ri --gbz-input ${graph}
    """

}
