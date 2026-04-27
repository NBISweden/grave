process INDEX_FILTERED_GRAPH {

    tag "${graph.baseName}_graph"
    label 'process_high_memory'
    // NOTE: update version string manually (due to use of storedir)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/vg:1.73.0--645b5a4f32c11ace' :
        'community.wave.seqera.io/library/vg:1.73.0--e9dad0f50dfcdf46' }"
    storeDir { graph.toRealPath().parent.resolve("${graph.baseName}_indexes/min_dist") }

    input:
    path (graph)
    val (types)

    output:
    path ("${graph.baseName}.????*"), emit: ch_filter_indexes
    // NOTE: update version string manually (due to use of storedir)
    tuple val(task.process), val('vg'), val('1.73.0'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def basename = graph.baseName - '.gbz'

    """
    # Create common indexes for all sample types
    vg index --threads ${task.cpus} ${args} --dist-name ${basename}.dist ${graph}

    # Type specific ".min" production
    if [ "${types}" == "ancient" ]
        then
            vg minimizer --threads ${task.cpus} --kmer-length ${params.aDNAkmerLength} --window-length ${params.aDNAwindowLength} --distance-index ${basename}.dist --output-name ${basename}.adna.withzip.min --zipcode-name ${basename}.adna.zipcodes ${graph}
    elif [ "${types}" == "modern" ]
        then
            vg minimizer --threads ${task.cpus} --kmer-length ${params.modernKmerLength} --window-length ${params.modernWindowLength} --distance-index ${basename}.dist --output-name ${basename}.modern.withzip.min --zipcode-name ${basename}.modern.zipcodes ${graph}
    elif [ "${types}" == "both" ]
        then
            vg minimizer --threads ${task.cpus} --kmer-length ${params.aDNAkmerLength} --window-length ${params.aDNAwindowLength} --distance-index ${basename}.dist --output-name ${basename}.adna.withzip.min --zipcode-name ${basename}.adna.zipcodes ${graph}
            vg minimizer --threads ${task.cpus} --kmer-length ${params.modernKmerLength} --window-length ${params.modernWindowLength} --distance-index ${basename}.dist --output-name ${basename}.modern.withzip.min --zipcode-name ${basename}.modern.zipcodes ${graph}
    fi
    """

}
