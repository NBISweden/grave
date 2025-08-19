process FASTQ_MERGE_DEDUP {

	// Directives

	debug false
	tag "${meta.id}"
	label 'process_low'
	container 'oras://community.wave.seqera.io/library/fastp:0.24.0--0397de619771c7ae'

	// I/O & script

	input:
	tuple val(meta), path(fastqs)

	output:
	tuple val(meta), path("*.smFastp*fq.gz"), emit: ch_sample_fastqs
	path "*.smFastp.html.gz", optional: true, emit: ch_sample_fastp_report
	path "skipped-samples.txt", optional: true, emit: ch_skipped_samples
	tuple val(task.process), val('fastp'), eval('fastp --version 2>&1 | sed "s/fastp //"'), topic: versions

	script:
	def args = task.ext.args ?: ''

	if (meta.type == "ancient" && meta.merged == false && !params.discardUnmerged) // Receiving 3 files per library
		"""

		# Get number of libraries

			LIBRARY_COUNT=`ls -1 *.fastp.fq.gz | wc -l`

		# Concatenate the merged and unmerged reads per library

			for (( i=1; i<=LIBRARY_COUNT; i++ ))

				do

					cat ${meta.id}.\$i.fastp.fq.gz ${meta.id}.\$i.fastp.um1.fq.gz ${meta.id}.\$i.fastp.um2.fq.gz > ${meta.id}.\$i.cat.fastp.fq.gz

				done

		# Cat per sample and deduplicate

			# Single library: nothing to do (deduplicated by FASTP). Rename file & direct user to the FASTP report.

				if (( LIBRARY_COUNT == 1 ))

					then

					mv *.cat.fastp.fq.gz ${meta.id}.smFastp.fq.gz

					echo "Sample '${meta.id}' had one library, so deduplication has already been run. See the report at 'results/quality_reports/fastp-library-level/${meta.id}.*.fastp.html.gz'" > skipped-samples.txt

			# Multiple libraries: cat and deduplicate again

				elif (( LIBRARY_COUNT > 1 ))

					then

						cat *.cat.fastp.fq.gz > ${meta.id}.doubleCat.fq.gz

						fastp --in1 ${meta.id}.doubleCat.fq.gz --out1 ${meta.id}.smFastp.fq.gz --html ${meta.id}.smFastp.html --dedup --dup_calc_accuracy ${params.dupCalcAccuracy} --overrepresentation_analysis --thread ${task.cpus}

						rm *cat.fastp.fq.gz ${meta.id}.doubleCat.fq.gz fastp.json

						gzip ${meta.id}.smFastp.html

				fi

		"""

	else if (meta.type == "ancient" && meta.merged == false && params.discardUnmerged) // Receiving 1 file per library
		"""

		# Get number of libraries

			LIBRARY_COUNT=`ls -1 *.fastp.fq.gz | wc -l`

		# Cat and deduplicate

			# Single library: nothing to do (deduplicated by FASTP). Rename file & direct user to the FASTP report.

				if (( LIBRARY_COUNT == 1 ))

					then

					mv ${fastqs} ${meta.id}.smFastp.fq.gz

					echo "Sample '${meta.id}' had one library, so deduplication has already been run. See the report at 'results/quality_reports/fastp-library-level/${meta.id}.*.fastp.html.gz'" > skipped-samples.txt

			# Multiple libraries: cat and deduplicate again

				elif (( LIBRARY_COUNT > 1 ))

					then

						cat ${fastqs} > ${meta.id}.cat.fq.gz

						fastp --in1 ${meta.id}.cat.fq.gz --out1 ${meta.id}.smFastp.fq.gz --html ${meta.id}.smFastp.html --dedup --dup_calc_accuracy ${params.dupCalcAccuracy} --overrepresentation_analysis --thread ${task.cpus}

						rm ${meta.id}.cat.fq.gz fastp.json

						gzip ${meta.id}.smFastp.html

				fi

		"""

	else if (meta.type == "modern" && meta.merged == false) // Receiving two files per library
		"""

		# Get number of libraries

			LIBRARY_COUNT=`ls -1 *.fastp.1.fq.gz | wc -l`
		
		# Cat and deduplicate

			# Single library: nothing to do (deduplicated by FASTP). Rename file & direct user to the FASTP report.

				if (( LIBRARY_COUNT == 1 ))

					then

						mv ${fastqs[0]} ${meta.id}.smFastp.1.fq.gz

						mv ${fastqs[1]} ${meta.id}.smFastp.2.fq.gz

						echo "Sample '${meta.id}' had one library, so deduplication has already been run. See the report at 'results/quality_reports/fastp-library-level/${meta.id}.*.fastp.html.gz'" > skipped-samples.txt

			# Multiple libraries: cat and deduplicate again

				elif (( LIBRARY_COUNT > 1 ))

					then

						cat ${fastqs[0]} > ${meta.id}.cat.1.fq.gz

						cat ${fastqs[1]} > ${meta.id}.cat.2.fq.gz

						fastp --in1 ${meta.id}.cat.1.fq.gz --in2 ${meta.id}.cat.2.fq.gz --out1 ${meta.id}.smFastp.1.fq.gz --out2 ${meta.id}.smFastp.2.fq.gz --html ${meta.id}.smFastp.html --dedup --dup_calc_accuracy ${params.dupCalcAccuracy} --overrepresentation_analysis --thread ${task.cpus}

						rm ${meta.id}.cat.1.fq.gz ${meta.id}.cat.2.fq.gz fastp.json

						gzip ${meta.id}.smFastp.html

				fi

		"""

	else if (meta.merged == true) // All pre-merged reads, receiving one file per library
		"""

		# Get number of libraries

			LIBRARY_COUNT=`ls -1 *.fastp.fq.gz | wc -l`

		# Cat and deduplicate

			# Single library: nothing to do (deduplicated by FASTP). Rename file & direct user to the FASTP report.

				if (( LIBRARY_COUNT == 1 ))

					then

					mv ${fastqs} ${meta.id}.smFastp.fq.gz

					echo "Sample '${meta.id}' had one library, so deduplication has already been run. See the report at 'results/quality_reports/fastp-library-level/${meta.id}.*.fastp.html.gz'" > skipped-samples.txt

			# Multiple libraries: cat and deduplicate again

				elif (( LIBRARY_COUNT > 1 ))

					then

						cat ${fastqs} > ${meta.id}.cat.fq.gz

						fastp --in1 ${meta.id}.cat.fq.gz --out1 ${meta.id}.smFastp.fq.gz --html ${meta.id}.smFastp.html --dedup --dup_calc_accuracy ${params.dupCalcAccuracy} --overrepresentation_analysis --thread ${task.cpus}

						rm ${meta.id}.cat.fq.gz fastp.json

						gzip ${meta.id}.smFastp.html

				fi

		"""

}
