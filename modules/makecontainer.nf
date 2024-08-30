process MAKECONTAINER {

	// Directives
	debug true
	label 'process_medium'
	publishDir params.containerDir, mode: 'move'

	// I/O & script

	input:
	path cactus_def

	output:
	file "cactus.sif"

	script:
	"""

	apptainer build cactus.sif $cactus_def

	"""

}
