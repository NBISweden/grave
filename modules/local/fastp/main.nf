process FASTP {

    tag "${meta.read_group}"
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/52/527b18847a97451091dba07a886b24f17f742a861f9f6c9a6bfb79d4f1f3bf9d/data' :
        'community.wave.seqera.io/library/fastp:1.0.1--c8b87fe62dcc103c' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fastp*fq.gz"), emit: ch_fastp_reads
    tuple path("*.fastp.html.gz"), path("*.fastp.json"), emit: ch_fastp_report
    tuple val(task.process), val('fastp'), eval('fastp --version 2>&1 | sed "s/fastp //"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''

    if (meta.type == "ancient" && meta.merged == false)
        """
        # Merge and QC paired-end ancient DNA
        fastp \
            --in1 ${reads[0]} \
            --in2 ${reads[1]} \
            --merge \
            --merged_out ${meta.read_group}.fastp.fq.gz \
            --html ${meta.read_group}.fastp.html \
            --json ${meta.read_group}.fastp.json \
            --dup_calc_accuracy ${params.dupCalcAccuracy} \
            --overrepresentation_analysis \
            --length_required ${params.readDiscardLength} \
            --thread ${task.cpus} \
            ${args} \
            ${args2} \
            --detect_adapter_for_pe \
            --correction

        gzip ${meta.read_group}.fastp.html
        """

    else if (meta.type == "modern" && meta.merged == false)
        """
        # QC paired-end modern DNA
        fastp \
            --in1 ${reads[0]} \
            --in2 ${reads[1]} \
            --out1 ${meta.read_group}.fastp.1.fq.gz \
            --out2 ${meta.read_group}.fastp.2.fq.gz \
            --html ${meta.read_group}.fastp.html \
            --json ${meta.read_group}.fastp.json \
            --dup_calc_accuracy ${params.dupCalcAccuracy} \
            --overrepresentation_analysis \
            --length_required ${params.readDiscardLength} \
            --thread ${task.cpus} \
            ${args2} \
            --detect_adapter_for_pe \
            --correction

        gzip ${meta.read_group}.fastp.html
        """

    else if (meta.merged == true) // Same settings for ancient and modern
        """
        # QC merged reads
        fastp \
            --in1 ${reads[0]} \
            --out1 ${meta.read_group}.fastp.fq.gz \
            --html ${meta.read_group}.fastp.html \
            --json ${meta.read_group}.fastp.json \
            --dup_calc_accuracy ${params.dupCalcAccuracy} \
            --overrepresentation_analysis \
            --length_required ${params.readDiscardLength} \
            --thread ${task.cpus} \
            ${args2}

        gzip ${meta.read_group}.fastp.html
        """

}
