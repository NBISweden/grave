process MAKEFILTER {

	// Directives

	debug true
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/kmc_vg:1f2db4fcec341609'

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

		vg minimizer --threads ${task.cpus} --kmer-length $params.aDNAkmerValue --window-length $params.aDNAminimiserValue --distance-index ${basename}.dist --output-name ${basename}.adna.min $graph

	# Produce minimizer index appropriate for modern samples

		vg minimizer --threads ${task.cpus} --kmer-length 29 --window-length 11 --distance-index ${basename}.dist --output-name ${basename}.modern.min $graph

	"""

}
