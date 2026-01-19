process INDEX_UNFILTERED_GRAPH {

    tag "${graph.baseName}_graph"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/vg:1.70.0--6aa72998bf6738ae' :
        'community.wave.seqera.io/library/vg:1.70.0--601cb9ffed863393' }"
    storeDir { graph.toRealPath().parent.resolve("${graph.baseName}_indexes/hapl") }

    input:
    path (graph)
    val (types)

    output:
    path ("*.hapl"), emit: ch_hapl_indexes
    // PLANNED: enable topic channel once Nextflow bug resolved
    //tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

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
            vg haplotypes --threads ${task.cpus} --verbosity 2 --kmer-length ${params.aDNAkmerHaplSubSam} --window-length ${params.aDNAwindowHaplSubSam} --haplotype-output ${ahaplname} ${graph}
    elif [ "${types}" == "modern" ]
        then
            vg haplotypes --threads ${task.cpus} --verbosity 2 --kmer-length ${params.modernKmerHaplSubSam} --window-length ${params.modernWindowHaplSubSam} --haplotype-output ${mhaplname} ${graph}
    elif [ "${types}" == "both" ]
        then
            vg haplotypes --threads ${task.cpus} --verbosity 2 --kmer-length ${params.aDNAkmerHaplSubSam} --window-length ${params.aDNAwindowHaplSubSam} --haplotype-output ${ahaplname} ${graph}
            vg haplotypes --threads ${task.cpus} --verbosity 2 --kmer-length ${params.modernKmerHaplSubSam} --window-length ${params.modernWindowHaplSubSam} --haplotype-output ${mhaplname} ${graph}
    fi

    # Clean up
    rm ${distname} ${rindexname}
    """

}
