process PROCESSGRAPH {

	// Directives

	debug false
	label 'process_single'
	container 'oras://community.wave.seqera.io/library/samtools_vg:d858a75dfe2e019e'
	publishDir path: 'output/statistics/graph', mode: 'move', pattern: "*_graph-stats.txt"

	// I/O & script

	input:
	path graph

	output:
	path "*_graph-stats.txt"
	tuple path("reference.fasta"), path("reference.fasta.fai"), emit: ch_reference_fasta

	script:
	def basename = graph.baseName - '.gbz'

	"""

	# Report reference file summary statistics

		echo "Pangenome graph file: ${graph}" > ${basename}_graph-stats.txt
		vg stats -zlLHTA ${graph} >> ${basename}_graph-stats.txt

	# Pull reference path as FASTA for mapdamage

		vg paths --reference-paths --extract-fasta -x ${graph} > reference.fasta

	# Index reference genome

		samtools faidx reference.fasta

	"""

}
