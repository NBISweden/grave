process PROCESSREF {

	// Directives
	debug false
	label 'process_single'
	container 'oras://community.wave.seqera.io/library/damageprofiler_kmc_vg:8b69f0006d7ee05d'

	// I/O & script

	input:
	path graph

	output:
	path 'pangenome-graph-stats.txt'
	path ("reference.fasta"), emit: ch_reference_fasta

	script:
	"""

	# Report reference file summary statistics

		echo "Pangenome graph file: ${graph}" > pangenome-graph-stats.txt
		vg stats -zlLHTA ${graph} >> pangenome-graph-stats.txt

	# Pull reference path as FASTA for mapdamage

		vg paths --reference-paths --extract-fasta -x ${graph} > reference.fasta

	"""

}
