process DEDUPLICATE {

	// Directives

	debug false
	tag "${meta.id}"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/picard-slim:3.4.0--f911f8b2b8ec0b3f'

	// I/O & script

	input:
	path ref_path_files
	tuple val(meta), path(bams)

	output:
	tuple val(meta), path("${meta.id}*.dedup.bam"), emit: ch_deduplicated_bams
	path "*.dedup_metrics.txt", emit: ch_dedup_metrics
	tuple val(task.process), val('picard'), eval('picard MarkDuplicates --version 2>&1 | grep Version | sed "s/.*://"'), topic: versions

	script:
	def args = task.ext.args ?: ''

	if (!params.multiRef && meta.type == "ancient") // By default, assume all reads have known 5' and 3' endings and use both for deduplication
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

		"""

	else if (!params.multiRef && meta.type == "modern") // Use only 5' mapping positions
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

		"""

	else if (params.multiRef && meta.type == "ancient")
		"""

		# Find system Java max heap size & convert to GB

			MAX_HEAP_BYTES=\$(java -XX:+PrintFlagsFinal 2>/dev/null | grep MaxHeapSize | grep -v Soft | awk '{print \$4}') || true

			MAX_HEAP_GB=\$(expr \$MAX_HEAP_BYTES / 1024 / 1024 / 1024)

		# Loop over reference samples

			for i in *.paths

				do

					PREFIX=`echo \$i | sed 's/\\.paths//'`

					# Mark duplicates

						picard -Xms2g -Xmx\${MAX_HEAP_GB}g MarkDuplicates \
							--INPUT ${meta.id}.\$PREFIX.merge.bam \
							--OUTPUT ${meta.id}.\$PREFIX.dedup.bam \
							--METRICS_FILE ${meta.id}.\$PREFIX.dedup_metrics.txt \
							--TAGGING_POLICY ${params.duplicateTaggingPolicy} \
							--REMOVE_DUPLICATES ${params.removeDuplicates} \
							--VALIDATION_STRINGENCY STRICT \
							--ASSUME_SORT_ORDER coordinate \
							${args}

				done

		"""

	else if (params.multiRef && meta.type == "modern")
		"""

		# Find system Java max heap size & convert to GB

			MAX_HEAP_BYTES=\$(java -XX:+PrintFlagsFinal 2>/dev/null | grep MaxHeapSize | grep -v Soft | awk '{print \$4}') || true

			MAX_HEAP_GB=\$(expr \$MAX_HEAP_BYTES / 1024 / 1024 / 1024)

		# Loop over reference samples

			for i in *.paths

				do

					PREFIX=`echo \$i | sed 's/\\.paths//'`

					# Mark duplicates

						picard -Xms2g -Xmx\${MAX_HEAP_GB}g MarkDuplicates \
							--INPUT ${meta.id}.\$PREFIX.merge.bam \
							--OUTPUT ${meta.id}.\$PREFIX.dedup.bam \
							--METRICS_FILE ${meta.id}.\$PREFIX.dedup_metrics.txt \
							--TAGGING_POLICY ${params.duplicateTaggingPolicy} \
							--REMOVE_DUPLICATES ${params.removeDuplicates} \
							--VALIDATION_STRINGENCY STRICT \
							--ASSUME_SORT_ORDER coordinate

				done

		"""

}
