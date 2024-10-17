process PROCESSREF {

	// Directives
	debug false
	label 'process_single'
	container 'oras://community.wave.seqera.io/library/kmc_mapdamage2_vg:a0bb91ce944be926'

	// I/O & script

	input:
	path graph

	output:
	path 'pangenome-graph-stats.txt'
	path ("reference.fasta"), emit: ch_reference_fasta

	script:
	"""

	# Report reference file summary statistics

		echo "Pangenome graph file: $graph" > pangenome-graph-stats.txt
		vg stats -zlLHTA $graph >> pangenome-graph-stats.txt

	# Pull reference path as FASTA for mapdamage

		vg paths --reference-paths --extract-fasta -x $graph > reference.fasta

	"""

}
