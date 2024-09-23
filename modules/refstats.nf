process REFSTATS {

	// Directives
	debug false
	label 'process_single'
	container 'oras://community.wave.seqera.io/library/kmc_vg:1f2db4fcec341609'

	// I/O & script

	input:
	path graph

	output:
	path 'pangenome-graph-stats.txt'

	script:
	"""

	echo "Pangenome graph file: $graph" > pangenome-graph-stats.txt

	vg stats -zlLHTA $graph >> pangenome-graph-stats.txt

	"""

}
