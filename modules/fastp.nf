process FASTP {

	// Directives

	debug false
	tag "$meta.id"
	label 'process_low'
	container FIXME:

	// I/O & script

	input:
	tuple val(meta), path(reads)

	script:
	if (meta.paired_end == true)
		"""
		echo $meta.paired_end
		"""

	else if (meta.paired_end == false)
		"""
		echo $meta.paired_end
		"""

	else
		error "Error due to uncertainty in the samplesheet - check if it's formatted correctly."

	// Stub for troubleshooting process

	stub:
	if (meta.paired_end == true)
		"""
		echo $meta.paired_end
		"""

	else if (meta.paired_end == false)
		"""
		echo $meta.paired_end
		"""

	else
		error "Error due to uncertainty in the samplesheet - check if it's formatted correctly."

}
