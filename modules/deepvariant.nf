process DEEPVARIANT {

	// Directives

	debug false
	//TODO: tag "$meta.id"
	label 'process_high'
	container 'docker://google/deepvariant:1.6.1'

	// I/O & script

	//input:


	//TODO: output:

	script:
	"""

	echo "This will be a DeepVariant process"
	
		# /opt/deepvariant/bin/run_deepvariant --helpshort

	"""

}
