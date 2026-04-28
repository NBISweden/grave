process BWA_ALN_SAMSE {

    tag "${meta.read_group}"
    // NOTE: time handled in conf/tool_resources.config
    label 'process_medium'
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/d7/d7e24dc1e4d93ca4d3a76a78d4c834a7be3985b0e1e56fddd61662e047863a8a/data' :
        'community.wave.seqera.io/library/bwa_htslib_samtools:83b50ff84ead50d0' }"

    input:
    tuple val(meta), path(reads)
    tuple path(reference), path(indexes)

    output:
    tuple val(meta), path("*.bam"), emit: ch_bam
    tuple val(meta), path("*_flagstat.txt"), emit: ch_flagstat
    tuple val(task.process), val('bwa'), eval('bwa 2>&1 | head -n 3 | tail -n 1 | sed "s/Version: //"'), topic: versions
    tuple val(task.process), val('samtools'), eval('samtools version | head -n 1 | sed "s/samtools //"'), topic: versions

    script:
    def args   = task.ext.args   ?: ''
    def args2   = task.ext.args2   ?: ''
    def prefix = task.ext.prefix ?: "${meta.read_group}"
    def read_group = meta.read_group ? "-r '@RG\\tID:${meta.read_group}\\tLB:${meta.library}\\tSM:${meta.id}'" : ""

    """
    INDEX_PREFIX=`find -L ./ -name "*.amb" | sed 's/\\.amb\$//'`

    bwa aln \\
        $args \\
        -t $task.cpus \\
         \$INDEX_PREFIX \\
        ${reads} | \\
    bwa samse \\
        $args2 \\
        $read_group \\
        \$INDEX_PREFIX \\
        - \\
        $reads | \\
    samtools view \\
        --exclude-flags 4 \\
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
