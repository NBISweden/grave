// Copyright (c) the nf-core community under an open-source MIT license.
// See https://github.com/nf-core/modules for full license, file patching instructions and upstream contributing.

process BWAMEM3_MEM {

    tag "${meta.read_group}"
    label 'process_high'
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/ff/ffd9362ddd396e0eb431def1812e02a274552b162355b242d974af65fcf83167/data'
        : 'community.wave.seqera.io/library/bwa-mem3_htslib_samtools_findutils:f271e572b6aa004b'}"

    input:
    tuple val(meta)     , path(reads)
    tuple val(reference), path(indexes)

    output:
    tuple val(meta), path("*.bam"), emit: ch_bam
    tuple val(meta), path("*_flagstat.txt"), emit: ch_flagstat
    tuple val(task.process), val('bwamem3'), eval("bwa-mem3 version | sed -nE '1 s/^([0-9]+(\\.[0-9]+)+).*/\\1/p'"), topic: versions
    tuple val(task.process), val('samtools'), eval('samtools version | head -n 1 | sed "s/samtools //"'), topic: versions

    script:
    def args       = task.ext.args   ?: ''
    def prefix     = task.ext.prefix ?: "${meta.read_group}"
    def read_group = meta.read_group ? "-R '@RG\\tID:${meta.read_group}\\tLB:${meta.library}\\tSM:${meta.id}'" : ""

    """
    INDEX_PREFIX=`find -L ./ -name "*.amb" | sed 's/\\.amb\$//'`

    bwa-mem3 mem \\
        ${read_group} \\
        -t ${task.cpus} \\
        \$INDEX_PREFIX \\
        ${reads} | \\
    samtools view \\
        --exclude-flags 4 \\
        ${args} \\
        --with-header \\
        --uncompressed \\
        - | \\
    samtools sort \\
        --threads ${task.cpus - 1} \\
        -O bam \\
        - > ${prefix}.bam

    samtools flagstat ${prefix}.bam > ${prefix}_flagstat.txt
    """

}
