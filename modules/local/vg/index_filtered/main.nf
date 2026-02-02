process INDEX_FILTERED_GRAPH {

    tag "${graph.baseName}_graph"
    label 'process_medium'
    // NOTE: update version string manually
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/vg:1.70.0--6aa72998bf6738ae' :
        'community.wave.seqera.io/library/vg:1.70.0--601cb9ffed863393' }"
    storeDir { graph.toRealPath().parent.resolve("${graph.baseName}_indexes/min_dist") }

    input:
    path (graph)
    val (types)

    output:
    path ("${graph.baseName}.????*"), emit: ch_filter_indexes
    // NOTE: update version string manually
    tuple val(task.process), val('vg'), val('1.70.0'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def basename = graph.baseName - '.gbz'

    """
    # Create common indexes for all sample types
    vg index --threads ${task.cpus} ${args} --dist-name ${basename}.dist ${graph}

    # Type specific ".min" production
    if [ "${types}" == "ancient" ]
        then
            vg minimizer --threads ${task.cpus} --kmer-length ${params.aDNAkmerMinimizer} --window-length ${params.aDNAwindowMinimizer} --distance-index ${basename}.dist --output-name ${basename}.adna.min ${graph}
    elif [ "${types}" == "modern" ]
        then
            vg minimizer --threads ${task.cpus} --kmer-length ${params.modernKmerMinimizer} --window-length ${params.modernWindowMinimizer} --distance-index ${basename}.dist --output-name ${basename}.modern.min ${graph}
    elif [ "${types}" == "both" ]
        then
            vg minimizer --threads ${task.cpus} --kmer-length ${params.aDNAkmerMinimizer} --window-length ${params.aDNAwindowMinimizer} --distance-index ${basename}.dist --output-name ${basename}.adna.min ${graph}
            vg minimizer --threads ${task.cpus} --kmer-length ${params.modernKmerMinimizer} --window-length ${params.modernWindowMinimizer} --distance-index ${basename}.dist --output-name ${basename}.modern.min ${graph}
    fi
    """

}
