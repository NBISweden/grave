process REFSTATS {

	// Directives
	debug false
	label 'process_single'
	container 'oras://community.wave.seqera.io/library/vg:1.59.0--15a0439180ad1c60'

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
