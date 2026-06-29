process GPU_GIRAFFE {

    tag "${meta.read_group}"
    // NOTE: all resources handled in conf/tool_resources.config
    container 'nvcr.io/nvidia/clara/clara-parabricks:4.7.0-1'

    input:
    tuple val(meta), path(reads)
    tuple path(graph), path(indexes)

    //output:

    script:
    def args = task.ext.args ?: ''

    if (meta.type == "ancient" && params.reference_type == "unfiltered_graph") // Ancient samples merged
        """
        pbrun giraffe
        """

    else if (meta.type == "ancient" && params.reference_type == "filtered_graph") // Ancient samples merged
        """
        pbrun giraffe \\
            ${args} \\
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
        pbrun giraffe
        """

    else if (meta.type == "modern" && params.reference_type == "filtered_graph" && meta.merged == false) // Arrives paired
        """
        pbrun giraffe \\
            ${args} \\
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
        pbrun giraffe
        """

    else if (meta.type == "modern" && params.reference_type == "filtered_graph" && meta.merged == true) // Arrives merged
        """
        pbrun giraffe \\
            ${args} \\
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
