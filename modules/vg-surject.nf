process VGSURJECT {

	// Projects GAM mappings to BAM against reference paths. If no user path files provided, uses vg defaults. If they are, each set of paths is surjected to separately.

	// Directives

	debug false
	tag "$meta.id"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/vg:1.60.0--e90f97d844d42049'

	// I/O & script

	input:
	path graph
	path ref_path_files
	tuple val(meta), path(mapped_gam)

	output:
	// TODO: BAMS
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

	script:
	if (!params.providePathsFiles && meta.type == "ancient")	// Default paths, GAM not interleaved
		"""

		# Surject GAM to all reference paths

			vg surject -t ${task.cpus} -x ${graph} --sample ${meta.id} --bam-output ${mapped_gam} > ${meta.id}.all_paths.bam

		"""

	else if (!params.providePathsFiles && meta.type == "modern")	// Default paths, GAM interleaved
		"""

		# Surject GAM to all reference paths, interleave

			vg surject -t ${task.cpus} -x ${graph} --sample ${meta.id} --interleaved --bam-output ${mapped_gam} > ${meta.id}.all_paths.bam

		"""

	else if (params.providePathsFiles && meta.type == "ancient" )	// User provided paths, GAM not interleaved
		"""

		# Surject GAM to each user provided list of reference paths

			for i in *.paths
				do
					basename=`echo \$i | sed 's/\\.paths//'`
					vg surject -t ${task.cpus} -x ${graph} --into-paths \$i --sample ${meta.id} --bam-output ${mapped_gam} > ${meta.id}.\$basename.bam
				done

		"""

	else if  (params.providePathsFiles && meta.type == "modern")	// User provided paths, GAM interleaved
		"""

		# Surject GAM to each user provided list of reference paths, interleave

			for i in *.paths
				do
					basename=`echo \$i | sed 's/\\.paths//'`
					vg surject -t ${task.cpus} -x ${graph} --into-paths \$i --sample ${meta.id} --interleaved --bam-output ${mapped_gam} > ${meta.id}.\$basename.bam
				done

		"""

}
