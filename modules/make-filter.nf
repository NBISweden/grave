process MAKEFILTER {

	// Directives

	debug false
	tag "${graph.baseName}_graph"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/vg:1.60.0--e90f97d844d42049'

	// I/O & script

	input:
	path (graph)
	val (types)

	output:
	path ("${graph.baseName}.*"), includeInputs: false, emit: ch_filter_indexes
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

	script:
	def basename = graph.baseName - '.gbz'

	"""

	# Create common indexes for all sample types

		vg index --threads ${task.cpus} --dist-name ${basename}.dist ${graph}

	# Type specific ".min" production

		if [ "${types}" == "ancient" ]
			then
				vg minimizer --threads ${task.cpus} --kmer-length ${params.aDNAkmerMinimizer} --window-length ${params.aDNAwindowMinimizer} --distance-index ${basename}.dist --output-name ${basename}.adna.min ${graph}
		elif [ "${types}" == "modern" ]
			then
				vg minimizer --threads ${task.cpus} --kmer-length ${params.modernKmerMinimizer} --window-length ${params.modernWindowMinimizer} --distance-index ${basename}.dist --output-name ${basename}.modern.min ${graph}
		elif [ "${types}" == "both" ]
			then
				vg minimizer --threads ${task.cpus} --kmer-length ${params.aDNAkmerMinimizer} --window-length ${params.aDNAwindowMinimizer} --distance-index ${basename}.dist --output-name ${basename}.adna.min ${graph}
				vg minimizer --threads ${task.cpus} --kmer-length ${params.modernKmerMinimizer} --window-length ${params.modernWindowMinimizer} --distance-index ${basename}.dist --output-name ${basename}.modern.min ${graph}
		fi

	"""

}
