process GRAPH_STATISTICS {

    tag "${graph.baseName}_graph"
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/vg:1.70.0--6aa72998bf6738ae' :
        'community.wave.seqera.io/library/vg:1.70.0--601cb9ffed863393' }"

    input:
    path graph

    output:
    path "*_graph-*.txt*", emit: ch_graph_stats
    tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def basename = graph.baseName - '.gbz'

    """
    # Report graph summary statistics
    echo "Pangenome graph file:" > ${basename}_graph-stats.txt && echo ${graph} >> ${basename}_graph-stats.txt && echo >> ${basename}_graph-stats.txt
    echo "Graph statistics:" >> ${basename}_graph-stats.txt && vg stats --threads ${task.cpus} -zlLHTA ${graph} >> ${basename}_graph-stats.txt && echo >> ${basename}_graph-stats.txt

    # Report graph metadata to separate file
    vg paths --metadata -x ${graph} > ${basename}_graph-metadata.txt
    gzip ${basename}_graph-metadata.txt
    """

}
