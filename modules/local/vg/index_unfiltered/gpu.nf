process INDEX_UNFILTERED_GRAPH_GPU {

    tag "${graph.baseName}_graph"
    label 'process_high_memory'
    // NOTE: update version string manually (due to use of storedir)
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/vg:1.70.0--e551f543615b3bad' :
        'community.wave.seqera.io/library/vg:1.70.0--f0e005bd33f23d2f' }"
    storeDir { graph.toRealPath().parent.resolve("${graph.baseName}_gpu_indexes_${params.aDNAkmerLength}-${params.aDNAwindowLength}/hapl") }

    input:
    path (graph)
    val (types)

    output:
    path ("*.hapl"), emit: ch_hapl_indexes
    // NOTE: update version string manually (due to use of storedir)
    tuple val(task.process), val('vg'), val('1.70.0'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def basename = graph.baseName - '.gbz'
    def distname = "${basename}.dist"
    def rindexname = "${basename}.ri"
    def ahaplname = "${basename}.adna.hapl"
    def mhaplname = "${basename}.modern.hapl"

    """
    # Create common indexes for all sample types
    vg index --threads ${task.cpus} ${args} --dist-name ${distname} ${graph}
    vg gbwt --num-threads ${task.cpus} --r-index ${rindexname} --gbz-input ${graph}

    # Type specific ".hapl" production
    if [ "${types}" == "ancient" ]
        then
            vg haplotypes --threads ${task.cpus} --verbosity 2 --kmer-length ${params.aDNAkmerLength} --window-length ${params.aDNAwindowLength} --haplotype-output ${ahaplname} ${graph}
    elif [ "${types}" == "modern" ]
        then
            vg haplotypes --threads ${task.cpus} --verbosity 2 --kmer-length ${params.modernKmerLength} --window-length ${params.modernWindowLength} --haplotype-output ${mhaplname} ${graph}
    elif [ "${types}" == "both" ]
        then
            vg haplotypes --threads ${task.cpus} --verbosity 2 --kmer-length ${params.aDNAkmerLength} --window-length ${params.aDNAwindowLength} --haplotype-output ${ahaplname} ${graph}
            vg haplotypes --threads ${task.cpus} --verbosity 2 --kmer-length ${params.modernKmerLength} --window-length ${params.modernWindowLength} --haplotype-output ${mhaplname} ${graph}
    fi

    # Clean up
    rm ${distname} ${rindexname}
    """

}
