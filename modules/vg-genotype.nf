process VGGENOTYPE {

	// Genotypes the variants present in the graph for a mapped sample
	// N.B.: an experimental feature can also consider novel variants in the reads (vg augment), however official advice is: "you will get more accurate results by surjecting to BAM and using a linear variant caller like DeepVariant"

	// Directives

	debug false
	tag "$meta.id"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/vg:1.59.0--92074ade48692ef2'

	// I/O & script

	input:
	path graph
	path snarls
	tuple val(meta), path(mapped_gam)

	output:
	path "${meta.id}.vg-genotype.vcf"

	script:
	"""

	# Pre-filter GAM file to remove unmapped reads, and FIXME: currently defaults to MAPQ filter 0

		vg filter -t ${task.cpus} -x ${graph} ${mapped_gam} -r ${params.minimumScorePrimaryAlign} -fu --only-mapped -q ${params.minimumMapQFilter} -D 999 -v > ${meta.id}.filtered.gam

	# Calculate depth

		depth=`vg depth -t ${task.cpus} --gam ${meta.id}.filtered.gam ${graph} | cut -f1 | sed 's/\\..*//'`

	# Compute read support

		vg pack -t ${task.cpus} -x ${graph} -g ${meta.id}.filtered.gam -o ${meta.id}.pack --expected-cov \$depth -Q 5

	# Genotype against the graph

		vg call -t ${task.cpus} ${graph} -k ${meta.id}.pack -r ${snarls} -s ${meta.id} --genotype-snarls --all-snarls --gbz --ploidy ${params.samplePloidy} > ${meta.id}.vg-genotype.vcf

	"""

}
