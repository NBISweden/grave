process MAKEHAPL {

	// Directives

	debug false
	tag "${graph.baseName}_graph"
	label 'process_low'
	container 'oras://community.wave.seqera.io/library/vg:1.60.0--e90f97d844d42049'

	// I/O & script

	input:
	path (graph)

	output:
	tuple path ("*.adna.hapl"), path ("*.modern.hapl"), emit: ch_hapl_indexes
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

	script:
	def basename = graph.baseName - '.gbz'
	def distname = "${basename}.dist"
	def rindexname = "${basename}.ri"
	def ahaplname = "${basename}.adna.hapl"
	def mhaplname = "${basename}.modern.hapl"

	"""

	# Produce ".hapl" index appropriate for ancient samples

		vg index --threads ${task.cpus} --dist-name ${distname} ${graph}
		vg gbwt --num-threads ${task.cpus} --r-index ${rindexname} --gbz-input ${graph}
		vg haplotypes --threads ${task.cpus} --verbosity 2 --kmer-length ${params.aDNAkmerHaplSubSam} --window-length ${params.aDNAwindowHaplSubSam} --haplotype-output ${ahaplname} ${graph}

	# Produce ".hapl" index appropriate for modern samples (giraffe defaults)

		vg haplotypes --threads ${task.cpus} --verbosity 2 --kmer-length ${params.modernKmerHaplSubSam} --window-length ${params.modernWindowHaplSubSam} --haplotype-output ${mhaplname} ${graph}

	"""

}
