process PROFILEPMD {

	// Directives

	debug false
	tag "$meta.id"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/damageprofiler_vg:accb8ffcbab94b7a'
	publishDir path: 'output/pmd_profiles', mode: 'move'

	// I/O & script

	input:
	path graph
	tuple path(reference_fasta), path(index)
	tuple val(meta), path(mapped_gam)

	output:
	path "${meta.id}_pmd"
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions
	tuple val(task.process), val('damageprofiler'), eval('damageprofiler -version | sed "s/.* v//"'), topic: versions

	when:
	meta.type == 'ancient'

	script:
	"""

	# Surject gam to reference path (by default)
	# FIXME: probably remove this, as surjection is now done upstream

		vg surject -t ${task.cpus} -x ${graph} --bam-output ${mapped_gam} > ${meta.id}.ref.bam

	# Run PMD profiling

		damageprofiler -i ${meta.id}.ref.bam -r ${reference_fasta} -o ${meta.id}_pmd -t 20 -l 100 -yaxis_dp_max 0.3

	"""

}
