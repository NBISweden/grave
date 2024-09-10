process PANMAP {

	// Directives

	debug true
	tag "$meta.id"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/vg:1.56.0--b6e929d535c346ca'

	// I/O & script

	input:
	tuple val(meta), path(reads)
	tuple path(reference), path(indexes)

	//output:
	//

	script:
	if (meta.type == "ancient")
	"""

	# TODO: aDNA settings = short and merged (single ended data)
	echo $reads
	echo $reference
	echo $indexes

	"""

	else if (meta.type == "modern")
	"""
	# TODO: paired end mapping settings

	echo ${reads[1]}
	echo ${reads[2]}
	echo $reference
	echo $indexes

	"""

}
