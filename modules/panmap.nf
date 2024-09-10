process PANMAP {

	// Directives

	debug true
	tag "$meta.id"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/vg:1.59.0--15a0439180ad1c60'

	// I/O & script

	input:
	tuple val(meta), path(reads)
	tuple path(reference), path(indexes)

	// TODO:output:
	// TODO: REMOVE --progress from below, if we don't need this (keep for debug)
	// TODO: unsure if used correct notation for paired end reads, or if I should put --fastq-in twice (TEST LOCALLY)
	// TODO: look up what it said about running kff first for haplo mode? 
	// Will need to add --kff-name for that mode and add that into the haplo input tuple probably. 
	// TODO: compare behaviour with or without --sample (adding a name to the output files)
	// TODO: figure out which output format is most useful. Default is gam. What can that be used with? I think some of the other downstreams need bam?
	// TODO: add a param for output type?

	script:
	if (meta.type == "ancient" && params.referenceMode == "haplo")
	"""

	# Single-ended (merged) reads with two reference files

	vg giraffe --fastq-in $reads --gbz-name $reference --haplotype-name $indexes --sample $meta.id --output-format BAM --threads ${task.cpus} --progress

	"""

	else if (meta.type == "modern" && params.referenceMode == "haplo")
	"""

	# Paired-end reads with two reference files
	
	vg giraffe --fastq-in ${reads[0]} ${reads[1]} --gbz-name $reference --haplotype-name $indexes --sample $meta.id --output-format BAM --threads ${task.cpus} --progress

	"""

	else if (meta.type == "ancient" && params.referenceMode == "filter")
	"""

	# Single-ended (merged) reads with three reference files

	vg giraffe --fastq-in $reads --gbz-name $reference --dist-name ${indexes[0]} --minimizer-name ${indexes[1]} --sample $meta.id --output-format BAM --threads ${task.cpus} --progress 

	"""

	else if (meta.type == "modern" && params.referenceMode == "filter")
	"""
	
	# Paired-end reads with three reference files

	vg giraffe --fastq-in ${reads[0]} ${reads[1]} --gbz-name $reference --dist-name ${indexes[0]} --minimizer-name ${indexes[1]} --sample $meta.id --output-format BAM --threads ${task.cpus} --progress 
	
	"""

}
