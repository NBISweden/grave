process PROFILEPMD {

	// Directives

	debug false
	tag "$meta.id"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/damageprofiler_vg:ee253f4846be614b'

	// I/O & script

	input:
	path graph
	tuple path(reference_fasta), path(index)
	tuple val(meta), path(mapped_gam)

	output:
	path ("${meta.id}_pmd"), optional: true

	when:
    meta.type == 'ancient'

	script:
	"""

	# Surject gam to reference path

		vg surject -x ${graph} --bam-output ${mapped_gam} > ${meta.id}.ref.bam

	# Run PMD profiling

		damageprofiler -i ${meta.id}.ref.bam -r ${reference_fasta} -o ${meta.id}_pmd -t 20 -l 100 -yaxis_dp_max 0.3

	"""

}
