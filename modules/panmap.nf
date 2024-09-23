process PANMAP {

	// Directives

	debug false
	tag "$meta.id"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/kmc_vg:1f2db4fcec341609'

	// I/O & script

	input:
	tuple val(meta), path(reads)
	tuple path(reference), path(indexes)

	// TODO: figure out which output format is most useful. Default is gam. What can that be used with? I think some of the other downstreams need bam?

	script:
	// Trim memory parameter (strip trailing units)
	def memory = task.memory.toGiga()

	if (meta.type == "ancient" && params.referenceMode == "haplo")
	"""

	# Generate kff index

	kmc -k29 -t${task.cpus} -m$memory -sm -fq -okff $reads $meta.id .

	# Map merged reads

	vg giraffe --fastq-in $reads --kff-name ${meta.id}.kff --gbz-name $reference --haplotype-name $indexes --output-format BAM --threads ${task.cpus} > ${meta.id}.bam

	"""

	else if (meta.type == "modern" && params.referenceMode == "haplo")
	"""

	# Generate list of input read files

	echo -e "./${reads[0]}\n./${reads[1]}" > readfiles

	# Generate kff index

	kmc -k29 -t${task.cpus} -m$memory -sm -fq -okff @readfiles $meta.id .

	# Map paired-end reads

	vg giraffe --fastq-in ${reads[0]} --fastq-in ${reads[1]} --kff-name ${meta.id}.kff --gbz-name $reference --haplotype-name $indexes --output-format BAM --threads ${task.cpus} > ${meta.id}.bam

	"""

	else if (meta.type == "ancient" && params.referenceMode == "filter")
	"""

	# Map merged reads

	vg giraffe --fastq-in $reads --gbz-name $reference --dist-name ${indexes[0]} --minimizer-name ${indexes[1]} --output-format BAM --threads ${task.cpus} > ${meta.id}.bam

	"""

	else if (meta.type == "modern" && params.referenceMode == "filter")
	"""

	# Map paired-end reads

	vg giraffe --fastq-in ${reads[0]} --fastq-in ${reads[1]} --gbz-name $reference --dist-name ${indexes[0]} --minimizer-name ${indexes[1]} --output-format BAM --threads ${task.cpus} > ${meta.id}.bam

	"""

}
