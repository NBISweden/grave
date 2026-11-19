process GALN_ALN_SAMSE {

    tag "${meta.read_group}"
    // NOTE: time handled in conf/tool_resources.config
    label 'process_medium'
    label 'process_gpu'
    // NOTE: image must provide samtools alongside galn
    container 'ghcr.io/nbisweden/galn:latest'

    input:
    tuple val(meta)      , path(reads)
    tuple path(reference), path(indexes)

    output:
    tuple val(meta), path("*.bam"), emit: ch_bam
    tuple val(meta), path("*_flagstat.txt"), emit: ch_flagstat
    tuple val(task.process), val('galn'), eval('galn --version | sed "s/G-ALN //"'), topic: versions
    tuple val(task.process), val('samtools'), eval('samtools version | head -n 1 | sed "s/samtools //"'), topic: versions

    script:
    def args       = task.ext.args   ?: ''
    def args2      = task.ext.args2  ?: ''
    def prefix     = task.ext.prefix ?: "${meta.read_group}"
    def read_group = meta.read_group ? "-r '@RG\\tID:${meta.read_group}\\tLB:${meta.library}\\tSM:${meta.id}'" : ""

    // galn aln always uses all GPUs & CPU cores of the job (no -t), galn samse writes unsorted BAM to stdout (-l 0: uncompressed for piping)
    """
    INDEX_PREFIX=`find -L ./ -name "*.amb" | sed 's/\\.amb\$//'`

    export OMP_NUM_THREADS=${task.cpus}

    galn aln \\
        ${args} \\
        \$INDEX_PREFIX \\
        ${reads} | \\
    galn samse \\
        ${read_group} \\
        -l 0 \\
        \$INDEX_PREFIX \\
        - \\
        ${reads} | \\
    samtools view \\
        --exclude-flags 4 \\
        ${args2} \\
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
