process GPU_GIRAFFE {

    tag "${meta.read_group}"
    // NOTE: all resources handled in conf/tool_resources.config
    container 'nvcr.io/nvidia/clara/clara-parabricks:4.7.1-1'

    input:
    tuple val(meta), path(reads)
    tuple path(graph), path(indexes)

    output:
    tuple val(meta), path("${meta.read_group}*.bam"), emit: ch_bams
    tuple val(task.process), val('parabricks'), eval("pbrun --version | grep pbrun | sed 's/.*: //'"), topic: versions
    tuple val(task.process), val('gpu_giraffe'), eval("pbrun giraffe --version | grep VG-giraffe | sed 's/.*\t//'"), topic: versions

    script:
    def args  = task.ext.args  ?: ''
    def args2 = task.ext.args2 ?: ''
    def args3 = task.ext.args3 ?: ''

    if (meta.type == "ancient" && params.reference_type == "unfiltered_graph") // Ancient samples merged
        """
        pbrun giraffe \\
            ${args} \\
            ${args2} \\
            ${args3} \\
            --num-gpus ${task.accelerator.request} \\
            --align-only \\
            --no-markdups \\
            --in-se-fq ${reads} \\
            --gbz-name ${graph} \\
            --dist-name *.dist \\
            --minimizer-name *.withzip.min \\
            --zipcodes-name *.zipcodes \\
            --read-group ${meta.read_group} \\
            --read-group-library ${meta.library} \\
            --sample ${meta.id} \\
            --out-bam ${meta.read_group}.bam
        """

    else if (meta.type == "ancient" && params.reference_type == "filtered_graph") // Ancient samples merged
        """
        pbrun giraffe \\
            ${args} \\
            ${args2} \\
            ${args3} \\
            --num-gpus ${task.accelerator.request} \\
            --align-only \\
            --no-markdups \\
            --in-se-fq ${reads} \\
            --gbz-name ${graph} \\
            --dist-name *.dist \\
            --minimizer-name *.adna.withzip.min \\
            --zipcodes-name *.adna.zipcodes \\
            --read-group ${meta.read_group} \\
            --read-group-library ${meta.library} \\
            --sample ${meta.id} \\
            --out-bam ${meta.read_group}.bam
        """

    else if (meta.type == "modern" && params.reference_type == "unfiltered_graph" && meta.merged == false) // Arrives paired
        """
        pbrun giraffe \\
            ${args} \\
            ${args2} \\
            ${args3} \\
            --num-gpus ${task.accelerator.request} \\
            --align-only \\
            --no-markdups \\
            --in-fq ${reads[0]} ${reads[1]} \\
            --gbz-name ${graph} \\
            --dist-name *.dist \\
            --minimizer-name *.withzip.min \\
            --zipcodes-name *.zipcodes \\
            --read-group ${meta.read_group} \\
            --read-group-library ${meta.library} \\
            --sample ${meta.id} \\
            --out-bam ${meta.read_group}.bam
        """

    else if (meta.type == "modern" && params.reference_type == "filtered_graph" && meta.merged == false) // Arrives paired
        """
        pbrun giraffe \\
            ${args} \\
            ${args2} \\
            ${args3} \\
            --num-gpus ${task.accelerator.request} \\
            --align-only \\
            --no-markdups \\
            --in-fq ${reads[0]} ${reads[1]} \\
            --gbz-name ${graph} \\
            --dist-name *.dist \\
            --minimizer-name *.modern.withzip.min \\
            --zipcodes-name *.modern.zipcodes \\
            --read-group ${meta.read_group} \\
            --read-group-library ${meta.library} \\
            --sample ${meta.id} \\
            --out-bam ${meta.read_group}.bam
        """

    else if (meta.type == "modern" && params.reference_type == "unfiltered_graph" && meta.merged == true) // Arrives merged
        """
        pbrun giraffe \\
            ${args} \\
            ${args2} \\
            ${args3} \\
            --num-gpus ${task.accelerator.request} \\
            --align-only \\
            --no-markdups \\
            --in-se-fq ${reads} \\
            --gbz-name ${graph} \\
            --dist-name *.dist \\
            --minimizer-name *.withzip.min \\
            --zipcodes-name *.zipcodes \\
            --read-group ${meta.read_group} \\
            --read-group-library ${meta.library} \\
            --sample ${meta.id} \\
            --out-bam ${meta.read_group}.bam
        """

    else if (meta.type == "modern" && params.reference_type == "filtered_graph" && meta.merged == true) // Arrives merged
        """
        pbrun giraffe \\
            ${args} \\
            ${args2} \\
            ${args3} \\
            --num-gpus ${task.accelerator.request} \\
            --align-only \\
            --no-markdups \\
            --in-se-fq ${reads} \\
            --gbz-name ${graph} \\
            --dist-name *.dist \\
            --minimizer-name *.modern.withzip.min \\
            --zipcodes-name *.modern.zipcodes \\
            --read-group ${meta.read_group} \\
            --read-group-library ${meta.library} \\
            --sample ${meta.id} \\
            --out-bam ${meta.read_group}.bam
        """

}
