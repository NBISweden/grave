process COMPUTE_SNARLS {

	// Directives

	debug false
	tag "${graph.baseName}_graph"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/vg:1.63.1--77c63f4a6f8f9d7a'
	storeDir { graph.toRealPath().parent.resolve("${graph.baseName}_indexes/snarls") }

	// I/O & script

	input:
	path graph

	output:
	path "${graph}.snarls", emit: ch_snarls
	// PLANNED: enable topic channel once Nextflow bug resolved
	//tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

	when:
	params.graphDeconstruct == true || params.vgGenotype == true

	script:
	def args = task.ext.args ?: ''
	"""

	# Compute graph snarls for genotyping tasks

		vg snarls -t ${task.cpus} --include-trivial ${graph} > ${graph}.snarls

	"""

}
