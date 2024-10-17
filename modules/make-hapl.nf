process MAKEHAPL {

	// Directives

	debug false
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/kmc_mapdamage2_vg:a0bb91ce944be926'

	// I/O & script

	input:
	path (graph)

	output:
	tuple path ("*.adna.hapl"), path ("*.modern.hapl"), emit: ch_hapl_indexes

	script:
	def basename = graph.baseName - '.gbz'
    def distname = "${basename}.dist"
	def rindexname = "${basename}.ri"
	def ahaplname = "${basename}.adna.hapl"
	def mhaplname = "${basename}.modern.hapl"
	"""

	# Produce ".hapl" index appropriate for ancient samples

		vg index --threads ${task.cpus} --dist-name $distname $graph
		vg gbwt --num-threads ${task.cpus} --r-index $rindexname --gbz-input $graph
		vg haplotypes --threads ${task.cpus} --verbosity 2 --kmer-length ${params.aDNAkmerHaplSubSam} --window-length ${params.aDNAwindowHaplSubSam} --haplotype-output $ahaplname $graph

	# Produce ".hapl" index appropriate for modern samples (giraffe defaults)

		vg haplotypes --threads ${task.cpus} --verbosity 2 --kmer-length ${params.modernKmerHaplSubSam} --window-length ${params.modernWindowHaplSubSam} --haplotype-output $mhaplname $graph

	"""

}
