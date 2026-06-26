process GPU_GIRAFFE {

    tag "${meta.read_group}"
    // TODO NOTE: on location of configs
    container 'nvcr.io/nvidia/clara/clara-parabricks:4.7.0-1'

    input:
    tuple val(meta), path(reads)
    tuple path(graph), path(indexes)

    //output:

    script:
    """
    pbrun giraffe
    """

}
