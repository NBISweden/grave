process FASTQMERGEDEDUP {

	// Merge FASTQs per sample and deduplicate

	// Directives

	debug true
	tag "${meta.id}"
	label 'process_low'
	container 'oras://community.wave.seqera.io/library/fastp:0.24.0--0397de619771c7ae'
	publishDir path: 'quality_reports/fastp-sample-level', mode: 'copy', pattern: "*.smFastp.html"

	// I/O & script

	input:
	tuple val(meta), path(fastqs)

	output:
	tuple val(meta), path("*.smFastp*fq.gz"), emit: ch_sample_fastqs // Emit fastp processed sample-level FASTQs
	path "*.smFastp.html"
	path "skipped-samples.txt", emit: ch_skipped_samples
	tuple val(task.process), val('fastp'), eval('fastp --version 2>&1 | sed "s/fastp //"'), topic: versions

	script:
	if (meta.type == "ancient" || meta.merged == true) // For ancient and merged modern reads, expect one file per library from FASTP
		"""

		# Count the libraries per sample

			fq_count=\$(ls -1 *.fastp.fq.gz 2>/dev/null | wc -l)

		# Merge and deduplicate 

			# Single library: nothing to do (deduped by FASTP). Rename file, report sample, & direct user to FASTP report.

			if (( fq_count == 1 ))

				then

					mv ${fastqs} ${meta.id}.smFastp.fq.gz

					echo "${meta.id} has one library, and deduplication was already done. See the report at 'output/quality_reports/fastp-library-level/${meta.id}.${meta.repeat}.fastp.html'" >> skipped-samples.txt

			# Multiple libraries: merge and deduplicate again

			elif (( fq_count > 1 ))

				then

					cat ${fastqs} >> ${meta.id}.cat.fq.gz

					fastp --in1 ${meta.id}.cat.fq.gz --out1 ${meta.id}.smFastp.fq.gz --html ${meta.id}.smFastp.html --dedup --dup_calc_accuracy ${params.dupCalcAccuracy} --overrepresentation_analysis --thread ${task.cpus}

					rm ${meta.id}.cat.fq.gz

			fi

		"""

	else if (meta.type == "modern" && meta.merged == false) // Expecting two files per library
		"""

		# Count the libraries per sample

			fq_count=\$(ls -1 *.fastp.1.fq.gz 2>/dev/null | wc -l)
		
		# Merge and deduplicate

			# Single library: nothing to do (deduped by FASTP). Rename files, report sample, & direct user to FASTP report.

			if (( fq_count == 1 ))

				then

					mv ${fastqs[0]} ${meta.id}.smFastp.1.fq.gz

					mv ${fastqs[1]} ${meta.id}.smFastp.2.fq.gz

					echo "${meta.id} has one library, and deduplication was already done. See the report at 'output/quality_reports/fastp-library-level/${meta.id}.${meta.repeat}.fastp.html'" >> skipped-samples.txt

			# Multiple libraries: merge and deduplicate again

			elif (( fq_count > 1 ))

				then

					cat ${fastqs[0]} >> ${meta.id}.cat.1.fq.gz

					cat ${fastqs[1]} >> ${meta.id}.cat.2.fq.gz

					fastp --in1 ${meta.id}.cat.1.fq.gz --in2 ${meta.id}.cat.2.fq.gz --out1 ${meta.id}.smFastp.1.fq.gz --out2 ${meta.id}.smFastp.2.fq.gz --html ${meta.id}.smFastp.html --dedup --dup_calc_accuracy ${params.dupCalcAccuracy} --overrepresentation_analysis --thread ${task.cpus}

					rm ${meta.id}.cat.1.fq.gz

					rm ${meta.id}.cat.2.fq.gz

			fi

		"""

}
