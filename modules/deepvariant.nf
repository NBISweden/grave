process DEEPVARIANT {

	// Directives

	debug true
	//TODO: tag "$meta.id"
	label 'process_high'
	container 'docker://google/deepvariant:1.6.1'

	// I/O & script

	//input:


	//TODO: output:

	script:
	"""

	/opt/deepvariant/bin/run_deepvariant --helpshort

	"""

}
