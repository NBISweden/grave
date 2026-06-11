process DEDUPLICATE {

    tag "${meta.id}"
    label 'process_medium'
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/picard-slim_samtools:6bcbd97a9beb7f4a' :
        'community.wave.seqera.io/library/picard-slim_samtools:988127ec6146bc80' }"

    input:
    path ref_path_files
    tuple val(meta), path(bams)

    output:
    tuple val(meta), path("${meta.id}*.dedup.bam"), path("${meta.id}*.dedup.bam.bai"), emit: ch_deduplicated_bams
    tuple val(meta), path("*.dedup.bam.flagstats"), emit: ch_dedup_flagstats
    path "*.dedup_metrics.txt", emit: ch_dedup_metrics
    tuple val(task.process), val('picard'), eval('picard MarkDuplicates --version 2>&1 | grep Version | sed "s/.*://"'), topic: versions

    script:
    def args = task.ext.args ?: ''

    if (!params.multiple_references && meta.type == "ancient") // By default, assume all reads have known 5' and 3' endings and use both for deduplication
        """
        # Find system Java max heap size & convert to GB
        MAX_HEAP_BYTES=\$(java -XX:+PrintFlagsFinal 2>/dev/null | grep MaxHeapSize | grep -v Soft | awk '{print \$4}') || true
        MAX_HEAP_GB=\$(expr \$MAX_HEAP_BYTES / 1024 / 1024 / 1024)

        # Mark duplicates
        picard -Xms2g -Xmx\${MAX_HEAP_GB}g MarkDuplicates \
            --INPUT ${meta.id}.merge.bam \
            --OUTPUT ${meta.id}.dedup.bam \
            --METRICS_FILE ${meta.id}.dedup_metrics.txt \
            --TAGGING_POLICY ${params.duplicateTaggingPolicy} \
            --REMOVE_DUPLICATES ${params.removeDuplicates} \
            --VALIDATION_STRINGENCY STRICT \
            --ASSUME_SORT_ORDER coordinate \
            ${args}

        # Index BAM
        samtools index --threads ${task.cpus} ${meta.id}.dedup.bam

        # Stats
        samtools flagstat ${meta.id}.dedup.bam > ${meta.id}.dedup.bam.flagstats
        """

    else if (!params.multiple_references && meta.type == "modern") // Use only 5' mapping positions
        """
        # Find system Java max heap size & convert to GB
        MAX_HEAP_BYTES=\$(java -XX:+PrintFlagsFinal 2>/dev/null | grep MaxHeapSize | grep -v Soft | awk '{print \$4}') || true
        MAX_HEAP_GB=\$(expr \$MAX_HEAP_BYTES / 1024 / 1024 / 1024)

        # Mark duplicates
        picard -Xms2g -Xmx\${MAX_HEAP_GB}g MarkDuplicates \
            --INPUT ${meta.id}.merge.bam \
            --OUTPUT ${meta.id}.dedup.bam \
            --METRICS_FILE ${meta.id}.dedup_metrics.txt \
            --TAGGING_POLICY ${params.duplicateTaggingPolicy} \
            --REMOVE_DUPLICATES ${params.removeDuplicates} \
            --VALIDATION_STRINGENCY STRICT \
            --ASSUME_SORT_ORDER coordinate

        # Index BAM
        samtools index --threads ${task.cpus} ${meta.id}.dedup.bam

        # Stats
        samtools flagstat ${meta.id}.dedup.bam > ${meta.id}.dedup.bam.flagstats
        """

    else if (params.multiple_references && meta.type == "ancient")
        """
        # Find system Java max heap size & convert to GB
        MAX_HEAP_BYTES=\$(java -XX:+PrintFlagsFinal 2>/dev/null | grep MaxHeapSize | grep -v Soft | awk '{print \$4}') || true
        MAX_HEAP_GB=\$(expr \$MAX_HEAP_BYTES / 1024 / 1024 / 1024)

        # Loop over reference samples
        for i in *.paths
            do
                PREFIX=`echo \$i | sed 's/\\.paths//'`
                picard -Xms2g -Xmx\${MAX_HEAP_GB}g MarkDuplicates \
                    --INPUT ${meta.id}.\$PREFIX.merge.bam \
                    --OUTPUT ${meta.id}.\$PREFIX.dedup.bam \
                    --METRICS_FILE ${meta.id}.\$PREFIX.dedup_metrics.txt \
                    --TAGGING_POLICY ${params.duplicateTaggingPolicy} \
                    --REMOVE_DUPLICATES ${params.removeDuplicates} \
                    --VALIDATION_STRINGENCY STRICT \
                    --ASSUME_SORT_ORDER coordinate \
                    ${args}

                samtools index --threads ${task.cpus} ${meta.id}.\$PREFIX.dedup.bam
                samtools flagstat ${meta.id}.\$PREFIX.dedup.bam > ${meta.id}.\$PREFIX.dedup.bam.flagstats
            done
        """

    else if (params.multiple_references && meta.type == "modern")
        """
        # Find system Java max heap size & convert to GB
        MAX_HEAP_BYTES=\$(java -XX:+PrintFlagsFinal 2>/dev/null | grep MaxHeapSize | grep -v Soft | awk '{print \$4}') || true
        MAX_HEAP_GB=\$(expr \$MAX_HEAP_BYTES / 1024 / 1024 / 1024)

        # Loop over reference samples
        for i in *.paths
            do
                PREFIX=`echo \$i | sed 's/\\.paths//'`
                picard -Xms2g -Xmx\${MAX_HEAP_GB}g MarkDuplicates \
                    --INPUT ${meta.id}.\$PREFIX.merge.bam \
                    --OUTPUT ${meta.id}.\$PREFIX.dedup.bam \
                    --METRICS_FILE ${meta.id}.\$PREFIX.dedup_metrics.txt \
                    --TAGGING_POLICY ${params.duplicateTaggingPolicy} \
                    --REMOVE_DUPLICATES ${params.removeDuplicates} \
                    --VALIDATION_STRINGENCY STRICT \
                    --ASSUME_SORT_ORDER coordinate

                samtools index --threads ${task.cpus} ${meta.id}.\$PREFIX.dedup.bam
                samtools flagstat ${meta.id}.\$PREFIX.dedup.bam > ${meta.id}.\$PREFIX.dedup.bam.flagstats
            done
        """

}
