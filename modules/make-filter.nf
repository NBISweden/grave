process MAKEFILTER {

	// Directives

	debug true
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/kmc_mapdamage2_vg:a0bb91ce944be926'

	// I/O & script

	input:
	path (graph)

	output:
	tuple path ("*.dist"), path ("*.adna.min"), path ("*.modern.min"), emit: ch_filter_indexes

	script:
	def basename = graph.baseName - '.gbz'
	"""

	# Produce distance index

		vg index --threads ${task.cpus} --dist-name ${basename}.dist $graph

	# Produce minimizer index appropriate for ancient samples

		vg minimizer --threads ${task.cpus} --kmer-length ${params.aDNAkmerMinimizer} --window-length ${params.aDNAwindowMinimizer} --distance-index ${basename}.dist --output-name ${basename}.adna.min $graph

	# Produce minimizer index appropriate for modern samples

		vg minimizer --threads ${task.cpus} --kmer-length ${params.modernKmerMinimizer} --window-length ${params.modernWindowMinimizer} --distance-index ${basename}.dist --output-name ${basename}.modern.min $graph

	"""

}
