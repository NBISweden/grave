process PANMAP {

	// Directives

	debug true
	tag "$meta.id"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/kmc_vg:1f2db4fcec341609'

	// I/O & script

	input:
	tuple val(meta), path(reads)
	tuple path(reference), path(indexes)

	script:
	// Create a numeric variable with the available memory (i.e., strip off the trailing units)
	def memory = task.memory.toGiga()
	def basename = reference.baseName - '.gbz'

	if (meta.type == "ancient" && params.referenceMode == "haplo")
		"""

		# Generate kff index of the reads

			kmc -k21 -ci${params.kffKmerMinimum} -t${task.cpus} -m$memory -sm -fq -okff $reads $meta.id .

		# Generate the subsampled graph and index it

			vg haplotypes --threads ${task.cpus} --verbosity 2 --include-reference --diploid-sampling --haplotype-input ${indexes[0]} --kmer-input ${meta.id}.kff --gbz-output ${basename}.${meta.id}.gbz $reference
			vg index --threads ${task.cpus} --dist-name ${basename}.${meta.id}.dist ${basename}.${meta.id}.gbz
			vg minimizer --threads ${task.cpus} --kmer-length $params.aDNAkmerValue --window-length $params.aDNAminimiserValue --distance-index ${basename}.${meta.id}.dist --output-name ${basename}.${meta.id}.min ${basename}.${meta.id}.gbz

		# Map merged reads to graph (settings based on BWA aln)

			vg giraffe --progress --mismatch 3 --gap-open 11 --gap-extend 4 --max-fragment-length 301 --fastq-in $reads --gbz-name ${basename}.${meta.id}.gbz --dist-name ${basename}.${meta.id}.dist --minimizer-name ${basename}.${meta.id}.min --output-format SAM --threads ${task.cpus} > ${meta.id}.sam

		# Remove sample specific indexes

			rm *.$meta.id.* *.kff

		"""

	else if (meta.type == "modern" && params.referenceMode == "haplo")
		"""

		# Generate list of input read files

			echo -e "./${reads[0]}\n./${reads[1]}" > readfiles

		# Generate kff index of the reads

			kmc -k29 -ci${params.kffKmerMinimum} -t${task.cpus} -m$memory -sm -fq -okff @readfiles $meta.id .

		# Map paired-end reads (for modern reads the default Giraffe pipeline is appropriate, the mapping settings are equivalent to BWA mem)

			vg giraffe --progress --fastq-in ${reads[0]} --fastq-in ${reads[1]} --kff-name ${meta.id}.kff --gbz-name $reference --haplotype-name ${indexes[1]} --output-format SAM --threads ${task.cpus} > ${meta.id}.sam

		# Remove sample specific indexes

			rm *.$meta.id.* *.kff

		"""

	else if (meta.type == "ancient" && params.referenceMode == "filter")
		"""

		# Map merged reads (settings based on BWA aln)

			vg giraffe --progress --mismatch 3 --gap-open 11 --gap-extend 4 --max-fragment-length 301 --fastq-in $reads --gbz-name $reference --dist-name ${indexes[0]} --minimizer-name ${indexes[1]} --output-format SAM --threads ${task.cpus} > ${meta.id}.sam

		"""

	else if (meta.type == "modern" && params.referenceMode == "filter")
		"""

		# Map paired-end reads (default settings are equivalent to BWA mem)

			vg giraffe --progress --fastq-in ${reads[0]} --fastq-in ${reads[1]} --gbz-name $reference --dist-name ${indexes[0]} --minimizer-name ${indexes[2]} --output-format SAM --threads ${task.cpus} > ${meta.id}.sam

		"""

}
