process INDEXREF {

	// Directives

	debug false
	storeDir './data'
	label 'process_medium'
	container

	// I/O & script

	input:
	path reference

	output:
	path *.index???

	"""
	index reference
	"""

}
