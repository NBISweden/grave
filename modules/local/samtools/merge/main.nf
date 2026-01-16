process MERGE {

    // Directives

    debug false
    tag "${meta.id}"
    label 'process_medium'
    container 'oras://community.wave.seqera.io/library/samtools:1.22.1--9a10f06c24cdf05f'

    // I/O & script

    input:
    path ref_path_files
    tuple val(meta), val(readgroups), path(bams)

    output:
    tuple val(meta), path("${meta.id}*.merge.bam"), emit: ch_merged_bams
    tuple val(task.process), val('samtools'), eval('samtools version | head -n 1 | sed "s/samtools //"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def readgroupList = readgroups.collect{ it.repeat }.join(' ')
    def readgroupCount = readgroups.size()

    if (!params.multiple_references)
        """

        # Skip if only one BAM. Merge if multiple BAMS.

            if (( ${readgroupCount} == 1 )); then
                echo "Only one BAM file for sample ${meta.id}, skipping merge"
                mv ${bams} ${meta.id}.merge.bam
            else
                echo "Merging ${readgroupCount} BAM files for sample ${meta.id}"
                samtools merge --threads ${task.cpus} -p -o ${meta.id}.merge.bam ${bams}
            fi

        """

    else if (params.multiple_references)
        """

        # Loop over each surjection target

            for i in *.paths
                do
                    PREFIX=`echo \$i | sed 's/\\.paths//'`

                    # Skip single BAM files
                    if (( ${readgroupCount} == 1 )); then
                        echo "Only one BAM file per surjection target for sample ${meta.id}, skipping merge"
                        mv ${meta.id}.*.\$PREFIX.bam ${meta.id}.\$PREFIX.merge.bam

                    # Merge multiple BAM files
                    else
                        echo "Merging ${readgroupCount} BAM files per surjection target for sample ${meta.id}"
                        samtools merge --threads ${task.cpus} -p -o ${meta.id}.\$PREFIX.merge.bam ${meta.id}.*.\$PREFIX.bam
                    fi

                done

        """

}
