process GALN_INDEX {

    tag "$fasta"
    label 'process_medium'
    label 'process_gpu'
    // NOTE: update version string manually
    container 'ghcr.io/nbisweden/galn:latest'
    // G-ALN indexes are byte-identical to bwa index, so share the BWA_INDEX store location
    storeDir { fasta.toRealPath().parent.resolve("${fasta.baseName}_indexes") }

    input:
    path(fasta)

    output:
    path("${fasta}.*"), emit: ch_bwa_index
    // NOTE: update version string manually
    tuple val(task.process), val('galn'), val('0.2.7'), topic: versions

    script:
    def args = task.ext.args ?: ''
    """
    galn \\
        index \\
        $args \\
        -p $fasta \\
        $fasta
    """

}
