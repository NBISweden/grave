process INDEX_HAPLOTYPES {

    tag "${graph.baseName}_graph"
    label 'process_high_memory'
    // NOTE: update version strings manually (due to use of storedir). GPU giraffe lags behind vg CPU baseline -> use the parabricks-compatible vg and a separate store
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        (params.gpu_giraffe ? 'oras://community.wave.seqera.io/library/vg:1.70.0--e551f543615b3bad' : 'oras://community.wave.seqera.io/library/vg:1.73.0--645b5a4f32c11ace') :
        (params.gpu_giraffe ? 'community.wave.seqera.io/library/vg:1.70.0--f0e005bd33f23d2f' : 'community.wave.seqera.io/library/vg:1.73.0--e9dad0f50dfcdf46') }"
    // One haplotype index per sample type, keyed on that type's k/w only, so changing the other type's parameters never triggers a rebuild
    storeDir {
        def tag = type == 'ancient' ? 'adna' : 'modern'
        def kmer = type == 'ancient' ? params.aDNAkmerLength : params.modernKmerLength
        def window = type == 'ancient' ? params.aDNAwindowLength : params.modernWindowLength
        graph.toRealPath().parent.resolve("${graph.baseName}_indexes${params.gpu_giraffe ? '_gpu' : ''}/hapl_${tag}_${kmer}-${window}${params.noNestedDistance ? '_no-nested-distance' : ''}")
    }

    input:
    tuple path (graph), path (dist), path (ri), val (type)

    output:
    path ("*.hapl"), emit: ch_hapl
    tuple val(task.process), val('vg'), val(params.gpu_giraffe ? '1.70.0' : '1.73.0'), topic: versions

    script:
    def basename = graph.baseName - '.gbz'
    def adna     = type == 'ancient'
    def tag      = adna ? 'adna' : 'modern'
    def kmer     = adna ? params.aDNAkmerLength : params.modernKmerLength
    def window   = adna ? params.aDNAwindowLength : params.modernWindowLength

    """
    # vg haplotypes finds ${basename}.dist and ${basename}.ri next to the graph
    vg haplotypes --threads ${task.cpus} --verbosity 2 --kmer-length ${kmer} --window-length ${window} --haplotype-output ${basename}.${tag}.hapl ${graph}
    """

}
