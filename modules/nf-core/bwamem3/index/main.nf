// Copyright (c) the nf-core community under an open-source MIT license.
// See https://github.com/nf-core/modules for full license, file patching instructions and upstream contributing.

process BWAMEM3_INDEX {

    tag "$fasta"
    // bwa-mem3 builds an FM-index with libsais; peak memory scales with the reference size (~280 MB per 10 MB of FASTA).
    cpus { 6 * task.attempt }
    memory { 280.MB * Math.ceil(fasta.size() / 10000000) * task.attempt }
    time { 8.h * task.attempt }
    conda "${moduleDir}/environment.yml"
    // NOTE: update version string manually
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/98/98b0f53f5aed4a3743c17acf6fe59bb0587228a320a6bbe01b3ff3e9ccf85d43/data'
        : 'community.wave.seqera.io/library/bwa-mem3:0.16.0--b56ccc800b165a7e'}"
    storeDir { fasta.toRealPath().parent.resolve("${fasta.baseName}_bwamem3_indexes") }

    input:
    path(fasta)

    output:
    path("${fasta}.*"), emit: ch_bwamem3_index
    // NOTE: update version string manually
    tuple val(task.process), val('bwamem3'), val('0.16.0'), topic: versions

    script:
    def args = task.ext.args ?: ''
    """
    bwa-mem3 \\
        index \\
        $args \\
        -t ${task.cpus} \\
        $fasta
    """

}
