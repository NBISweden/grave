process MAKEFILTER {

	// Directives

	debug false
	tag "${graph.baseName}_graph"
	label 'process_low'
	container 'oras://community.wave.seqera.io/library/vg:1.60.0--e90f97d844d42049'

	// I/O & script

	input:
	path (graph)

	output:
	tuple path ("*.dist"), path ("*.adna.min"), path ("*.modern.min"), emit: ch_filter_indexes
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

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
