process BAM_DEDUP {

	// BAM deduplication

	// Directives

	debug false
	tag "${meta.id}"
	label 'process_low'
	container 'oras://community.wave.seqera.io/library/picard-slim:3.4.0--f911f8b2b8ec0b3f'

	// I/O & script

	input:
	path ref_path_files
	tuple val(meta), path(surjected_bams)

	output:
	tuple val(meta), path("${meta.id}*.sort.dedup.bam"), path ("${meta.id}*.sort.dedup.bam.bai"), emit: ch_sample_dedup_indexed_bams
	path "*.dedup_metrics.txt", emit: ch_dedup_metrics
	tuple val(task.process), val('picard'), eval('picard SortSam 2>&1 | grep "Version:" | sed "s/Version://"'), topic: versions //FIXME: check output

	script:
	def args = task.ext.args ?: ''

	if (!params.multiRef && meta.type == "ancient") // One reference assembly, ancient sample, default is to assume all reads have known 5' and 3' endings and use both for deduplication
		"""

		# Find system Java max heap size & convert to GB

			MAX_HEAP_BYTES=\$(java -XX:+PrintFlagsFinal 2>/dev/null | grep MaxHeapSize | grep -v Soft | awk '{print \$4}') || true

			MAX_HEAP_GB=\$(expr \$MAX_HEAP_BYTES / 1024 / 1024 / 1024)

		# Sort BAM

			picard -Xms2g -Xmx\${MAX_HEAP_GB}g SortSam \
				--INPUT ${meta.id}.bam \
				--OUTPUT ${meta.id}.sort.bam \
				--SORT_ORDER queryname

		# Mark duplicates

			picard -Xms2g -Xmx\${MAX_HEAP_GB}g MarkDuplicates \
				--INPUT ${meta.id}.sort.bam \
				--OUTPUT ${meta.id}.sort.dedup.bam \
				--METRICS_FILE ${meta.id}.dedup_metrics.txt \
				${args} \
				--TAGGING_POLICY ${params.duplicateTaggingPolicy} \
				--REMOVE_DUPLICATES ${params.removeDuplicates} \
				--VALIDATION_STRINGENCY LENIENT \
				--ASSUME_SORT_ORDER queryname

		# Clean up intermediate files

			rm ${meta.id}.sort.bam

		"""

else if (!params.multiRef && meta.type == "modern") // One reference assembly, modern sample, default is to use only 5' end
		"""

		# Find system Java max heap size & convert to GB

			MAX_HEAP_BYTES=\$(java -XX:+PrintFlagsFinal 2>/dev/null | grep MaxHeapSize | grep -v Soft | awk '{print \$4}') || true

			MAX_HEAP_GB=\$(expr \$MAX_HEAP_BYTES / 1024 / 1024 / 1024)

		# Sort BAM

			picard -Xms2g -Xmx\${MAX_HEAP_GB}g SortSam \
				--INPUT ${meta.id}.bam \
				--OUTPUT ${meta.id}.sort.bam \
				--SORT_ORDER queryname

		# Mark duplicates

			picard -Xms2g -Xmx\${MAX_HEAP_GB}g MarkDuplicates \
				--INPUT ${meta.id}.sort.bam \
				--OUTPUT ${meta.id}.sort.dedup.bam \
				--METRICS_FILE ${meta.id}.dedup_metrics.txt \
				--TAGGING_POLICY ${params.duplicateTaggingPolicy} \
				--REMOVE_DUPLICATES ${params.removeDuplicates} \
				--VALIDATION_STRINGENCY STRICT \
				--ASSUME_SORT_ORDER queryname

		# Clean up intermediate files

			rm ${meta.id}.sort.bam

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

					# Sort BAM

						picard -Xms2g -Xmx\${MAX_HEAP_GB}g SortSam \
							--INPUT ${meta.id}.\$PREFIX.bam \
							--OUTPUT ${meta.id}.\$PREFIX.sort.bam \
							--SORT_ORDER queryname

					# Mark duplicates

						picard -Xms2g -Xmx\${MAX_HEAP_GB}g MarkDuplicates \
							--INPUT ${meta.id}.\$PREFIX.sort.bam \
							--OUTPUT ${meta.id}.\$PREFIX.sort.dedup.bam \
							--METRICS_FILE ${meta.id}.\$PREFIX.dedup_metrics.txt \
							${args} \
							--TAGGING_POLICY ${params.duplicateTaggingPolicy} \
							--REMOVE_DUPLICATES ${params.removeDuplicates} \
							--VALIDATION_STRINGENCY LENIENT \
							--ASSUME_SORT_ORDER queryname

					# Clean up intermediate files

						rm ${meta.id}.\$PREFIX.sort.bam

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

					# Sort BAM

						picard -Xms2g -Xmx\${MAX_HEAP_GB}g SortSam \
							--INPUT ${meta.id}.\$PREFIX.bam \
							--OUTPUT ${meta.id}.\$PREFIX.sort.bam \
							--SORT_ORDER queryname

					# Mark duplicates

						picard -Xms2g -Xmx\${MAX_HEAP_GB}g MarkDuplicates \
							--INPUT ${meta.id}.\$PREFIX.sort.bam \
							--OUTPUT ${meta.id}.\$PREFIX.sort.dedup.bam \
							--METRICS_FILE ${meta.id}.\$PREFIX.dedup_metrics.txt \
							--TAGGING_POLICY ${params.duplicateTaggingPolicy} \
							--REMOVE_DUPLICATES ${params.removeDuplicates} \
							--VALIDATION_STRINGENCY STRICT \
							--ASSUME_SORT_ORDER queryname

					# Clean up intermediate files

						rm ${meta.id}.\$PREFIX.sort.bam

				done

		"""

}
