process PROCESSGRAPH {

	// Directives

	debug false
	tag "${graph.baseName}_graph"
	label 'process_single'
	container 'oras://community.wave.seqera.io/library/samtools_vg:765866d937aa49c6'
	publishDir path: 'output/statistics/graph', mode: 'move', pattern: "*_graph-stats.txt"

	// I/O & script

	input:
	path graph

	output:
	path "*_graph-stats.txt"
	tuple path("reference.fasta"), path("reference.fasta.fai"), emit: ch_reference_fasta
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions
	tuple val(task.process), val('samtools'), eval('samtools version | head -n 1 | sed "s/samtools //"'), topic: versions

	script:
	def basename = graph.baseName - '.gbz'

	"""

	# Report reference file summary statistics

		echo "Pangenome graph file:" > ${basename}_graph-stats.txt && echo ${graph} >> ${basename}_graph-stats.txt && echo >> ${basename}_graph-stats.txt
		echo "Graph statistics:" >> ${basename}_graph-stats.txt && vg stats -zlLHTA ${graph} >> ${basename}_graph-stats.txt && echo >> ${basename}_graph-stats.txt
		echo "Graph metadata:" >> ${basename}_graph-stats.txt && vg paths --metadata -x ${graph} >> ${basename}_graph-stats.txt && echo >> ${basename}_graph-stats.txt

	# Pull reference path as FASTA for mapdamage

		vg paths --reference-paths --extract-fasta -x ${graph} > reference.fasta

	# Index reference genome

		samtools faidx reference.fasta

	"""

}
