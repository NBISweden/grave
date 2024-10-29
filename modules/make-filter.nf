process MAKEFILTER {

	// Directives

	debug false
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/vg:1.59.0--92074ade48692ef2'

	// I/O & script

	input:
	path (graph)

	output:
	tuple path ("*.dist"), path ("*.adna.min"), path ("*.modern.min"), emit: ch_filter_indexes

	script:
	def basename = graph.baseName - '.gbz'
	"""

	# Produce distance index

		vg index --threads ${task.cpus} --dist-name ${basename}.dist ${graph}

	# Produce minimizer index appropriate for ancient samples

		vg minimizer --threads ${task.cpus} --kmer-length ${params.aDNAkmerMinimizer} --window-length ${params.aDNAwindowMinimizer} --distance-index ${basename}.dist --output-name ${basename}.adna.min ${graph}

	# Produce minimizer index appropriate for modern samples

		vg minimizer --threads ${task.cpus} --kmer-length ${params.modernKmerMinimizer} --window-length ${params.modernWindowMinimizer} --distance-index ${basename}.dist --output-name ${basename}.modern.min ${graph}

	"""

}
