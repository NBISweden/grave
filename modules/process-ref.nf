process PROCESSREF {

	// Directives

	debug false
	label 'process_single'
	container 'oras://community.wave.seqera.io/library/samtools_vg:d858a75dfe2e019e'
	publishDir path: 'output/graph_stats', mode: 'move', pattern: 'pangenome-graph-stats.txt'

	// I/O & script

	input:
	path graph

	output:
	path 'pangenome-graph-stats.txt'
	tuple path("reference.fasta"), path("reference.fasta.fai"), emit: ch_reference_fasta

	script:
	"""

	# Report reference file summary statistics

		echo "Pangenome graph file: ${graph}" > pangenome-graph-stats.txt
		vg stats -zlLHTA ${graph} >> pangenome-graph-stats.txt

	# Pull reference path as FASTA for mapdamage

		vg paths --reference-paths --extract-fasta -x ${graph} > reference.fasta

	# Index reference genome

		samtools faidx reference.fasta

	"""

}
