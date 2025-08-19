process MAKE_HAPL {

	// Directives

	debug false
	tag "${graph.baseName}_graph"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/vg:1.67.0--6a1814b7314a4bc7'
	storeDir { graph.toRealPath().parent.resolve("${graph.baseName}_indexes/hapl") }

	// I/O & script

	input:
	path (graph)
	val (types)

	output:
	path ("*.hapl"), emit: ch_hapl_indexes
	// PLANNED: enable topic channel once Nextflow bug resolved
	//tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

	script:
	def args = task.ext.args ?: ''
	def basename = graph.baseName - '.gbz'
	def distname = "${basename}.dist"
	def rindexname = "${basename}.ri"
	def ahaplname = "${basename}.adna.hapl"
	def mhaplname = "${basename}.modern.hapl"

	"""

	# Create common indexes for all sample types

		vg index --threads ${task.cpus} --dist-name ${distname} ${graph}
		vg gbwt --num-threads ${task.cpus} --r-index ${rindexname} --gbz-input ${graph}

	# Type specific ".hapl" production

		if [ "${types}" == "ancient" ]
			then
				vg haplotypes --threads ${task.cpus} --verbosity 2 --kmer-length ${params.aDNAkmerHaplSubSam} --window-length ${params.aDNAwindowHaplSubSam} --haplotype-output ${ahaplname} ${graph}
		elif [ "${types}" == "modern" ]
			then
				vg haplotypes --threads ${task.cpus} --verbosity 2 --kmer-length ${params.modernKmerHaplSubSam} --window-length ${params.modernWindowHaplSubSam} --haplotype-output ${mhaplname} ${graph}
		elif [ "${types}" == "both" ]
			then
				vg haplotypes --threads ${task.cpus} --verbosity 2 --kmer-length ${params.aDNAkmerHaplSubSam} --window-length ${params.aDNAwindowHaplSubSam} --haplotype-output ${ahaplname} ${graph}
				vg haplotypes --threads ${task.cpus} --verbosity 2 --kmer-length ${params.modernKmerHaplSubSam} --window-length ${params.modernWindowHaplSubSam} --haplotype-output ${mhaplname} ${graph}
		fi

	# Clean up

		rm ${distname} ${rindexname}

	"""

}
