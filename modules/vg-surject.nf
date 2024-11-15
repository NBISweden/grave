process VGSURJECT {

	// Projects GAM mappings to BAM against reference paths. If no user path files provided, uses vg defaults. If they are, each set of paths is surjected to separately.

	// Directives

	debug false
	tag "${meta.id}.${meta.repeat}"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/vg:1.60.0--e90f97d844d42049'

	// I/O & script

	input:
	path graph
	path ref_path_files
	tuple val(meta), path(mapped_gam)

	output:
	tuple val(meta), path("*.bam"), emit: ch_surjected_bams
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

	script:
	if (!params.refPaths && meta.type == "ancient")	// Default reference paths, GAM not interleaved
		"""

		# Surject GAM to all reference paths

			vg surject -t ${task.cpus} -x ${graph} --sample ${meta.id}.${meta.repeat} --bam-output ${mapped_gam} > ${meta.id}.${meta.repeat}.all_paths.bam

		"""

	else if (!params.refPaths && meta.type == "modern")	// Default reference paths, GAM interleaved
		"""

		# Surject GAM to all reference paths, interleave

			vg surject -t ${task.cpus} -x ${graph} --sample ${meta.id}.${meta.repeat} --interleaved --bam-output ${mapped_gam} > ${meta.id}.${meta.repeat}.all_paths.bam

		"""

	else if (params.refPaths && meta.type == "ancient" )	// User provided reference paths, GAM not interleaved
		"""

		# Surject GAM to each user provided list of reference paths

			for i in *.paths
				do
					basename=`echo \$i | sed 's/\\.paths//'`
					vg surject -t ${task.cpus} -x ${graph} --into-paths \$i --sample ${meta.id}.${meta.repeat} --bam-output ${mapped_gam} > ${meta.id}.${meta.repeat}.\$basename.bam
				done

		"""

	else if  (params.refPaths && meta.type == "modern")	// User provided reference paths, GAM interleaved
		"""

		# Surject GAM to each user provided list of reference paths, interleave

			for i in *.paths
				do
					basename=`echo \$i | sed 's/\\.paths//'`
					vg surject -t ${task.cpus} -x ${graph} --into-paths \$i --sample ${meta.id}.${meta.repeat} --interleaved --bam-output ${mapped_gam} > ${meta.id}.${meta.repeat}.\$basename.bam
				done

		"""

}
