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
	echo $meta.type
	echo $reads
	echo $reference
	echo $indexes

	"""

	else if (meta.type == "modern")
	"""
	# TODO: paired end mapping settings

	echo $meta.type
	echo ${reads[0]}
	echo ${reads[1]}
	echo $reference
	echo $indexes

	"""

}
