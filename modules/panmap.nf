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

	// TODO: figure out which output format is most useful. Default is gam. What can that be used with? I think some of the other downstreams need bam?

	script:
	if (meta.type == "ancient" && params.referenceMode == "haplo")
	"""

	# Single-ended (merged) reads with two named reference files

	vg giraffe --fastq-in $reads --gbz-name $reference --haplotype-name ${indexes[0]} --dist-name ${indexes[1]} --minimizer-name ${indexes[2]} --output-format BAM --threads ${task.cpus} > ${meta.id}.bam

	"""

	else if (meta.type == "modern" && params.referenceMode == "haplo")
	"""

	# Paired-end reads with two named reference files
	
	vg giraffe --fastq-in ${reads[0]} --fastq-in ${reads[1]} --gbz-name $reference --haplotype-name ${indexes[0]} --dist-name ${indexes[1]} --minimizer-name ${indexes[2]} --output-format BAM --threads ${task.cpus} > ${meta.id}.bam

	"""

	else if (meta.type == "ancient" && params.referenceMode == "filter")
	"""

	# Single-ended (merged) reads with three named reference files

	vg giraffe --fastq-in $reads --gbz-name $reference --dist-name ${indexes[0]} --minimizer-name ${indexes[1]} --output-format BAM --threads ${task.cpus} > ${meta.id}.bam

	"""

	else if (meta.type == "modern" && params.referenceMode == "filter")
	"""
	
	# Paired-end reads with three named reference files

	vg giraffe --fastq-in ${reads[0]} --fastq-in ${reads[1]} --gbz-name $reference --dist-name ${indexes[0]} --minimizer-name ${indexes[1]} --output-format BAM --threads ${task.cpus} > ${meta.id}.bam
	
	"""

}
