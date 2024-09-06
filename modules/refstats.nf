process REFSTATS {

	// Directives
	debug false
	label 'process_single'
	container 'oras://community.wave.seqera.io/library/vg:1.56.0--b6e929d535c346ca'

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
