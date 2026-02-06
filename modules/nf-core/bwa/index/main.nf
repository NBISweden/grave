process BWA_INDEX {

    tag "$fasta"
    label 'process_medium'
    conda "${moduleDir}/environment.yml"
    // NOTE: update version string manually
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/d7/d7e24dc1e4d93ca4d3a76a78d4c834a7be3985b0e1e56fddd61662e047863a8a/data' :
        'community.wave.seqera.io/library/bwa_htslib_samtools:83b50ff84ead50d0' }"
    storeDir { fasta.toRealPath().parent.resolve("${fasta.baseName}_indexes") }

    input:
    path(fasta)

    output:
    path("${fasta}.*"), emit: ch_bwa_index
    // NOTE: update version string manually
    tuple val(task.process), val('bwa'), val('0.7.19-r1273'), topic: versions

    script:
    def prefix = task.ext.prefix ?: "${fasta}"
    def args   = task.ext.args ?: ''
    """
    bwa \\
        index \\
        $args \\
        $fasta
    """

}
