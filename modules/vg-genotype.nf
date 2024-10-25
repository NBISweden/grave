process VGGENOTYPE {

	// For a mapped sample, calls/genotypes the variants present in the graph
	// Note, there is an experimental feature to also consider novel variants in the reads (vg augment)
	// But not currently advised: "you will get more accurate results by surjecting to BAM and using a linear variant caller like DeepVariant"

	// Directives

	debug false
	tag "$meta.id"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/vg:1.59.0--92074ade48692ef2'

	// I/O & script

	input:
	path graph
	tuple val(meta), path(mapped_gam)

	output:
	path "${meta.id}.vg-genotype.vcf"

	script:
	"""

	# Compute read support

		vg pack -t ${task.cpus} -x ${graph} -g ${mapped_gam} -o ${meta.id}.pack --expected-cov ${params.expectedCoverage} -Q 5

	# Compute snarls

		vg snarls -t ${task.cpus} ${graph} > ${meta.id}.snarls

	# Genotype against the graph

		vg call -t ${task.cpus} ${graph} -k ${meta.id}.pack -r ${meta.id}.snarls -s ${meta.id} --genotype-snarls --gbz --ploidy ${params.samplePloidy} > ${meta.id}.vg-genotype.vcf

	"""

}
