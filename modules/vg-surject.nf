process VGSURJECT {

	// Projects GAM mappings to BAM against reference paths. If no user path files provided, uses vg defaults. If paths provided, each set is surjected to separately.

	// Directives

	debug false
	tag "${meta.id}"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/samtools_vg:8f930d468758b80f'

	// I/O & script

	input:
	path graph
	path ref_path_files
	tuple val(meta), path(mapped_gam)

	output:
	tuple val(meta), path("${meta.id}*.sort.bam"), emit: ch_surjected_bams
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions
	tuple val(task.process), val('samtools'), eval('samtools version | head -n 1 | sed "s/samtools //"'), topic: versions

	script:
	if (!params.multiRef && meta.type == "ancient")	// Default reference paths, GAM not interleaved
		"""

		# Surject GAM to all reference paths

			vg surject -t ${task.cpus} -x ${graph} --sample ${meta.id} --bam-output ${mapped_gam} | samtools sort > ${meta.id}.sort.bam

		"""

	else if (params.multiRef && meta.type == "ancient" )	// User provided reference paths, GAM not interleaved
		"""

		# Surject GAM to each user provided list of reference paths

			for i in *.paths
				do
					prefix=`echo \$i | sed 's/\\.paths//'`
					vg surject -t ${task.cpus} -x ${graph} --into-paths \$i --sample ${meta.id} --bam-output ${mapped_gam} | samtools sort > ${meta.id}.\$prefix.sort.bam
				done

		"""

	else if (!params.multiRef && meta.type == "modern" && meta.merged == false)	// Default reference paths, GAM interleaved
		"""

		# Surject GAM to all reference paths, interleave

			vg surject -t ${task.cpus} -x ${graph} --sample ${meta.id} --interleaved --bam-output ${mapped_gam} | samtools sort > ${meta.id}.sort.bam

		"""

	else if  (params.multiRef && meta.type == "modern" && meta.merged == false)	// User provided reference paths, GAM interleaved
		"""

		# Surject GAM to each user provided list of reference paths, interleave

			for i in *.paths
				do
					prefix=`echo \$i | sed 's/\\.paths//'`
					vg surject -t ${task.cpus} -x ${graph} --into-paths \$i --sample ${meta.id} --interleaved --bam-output ${mapped_gam} | samtools sort > ${meta.id}.\$prefix.sort.bam
				done

		"""

	else if (!params.multiRef && meta.type == "modern" && meta.merged == true)	// Default reference paths, GAM not interleaved
		"""

		# Surject GAM to all reference paths

			vg surject -t ${task.cpus} -x ${graph} --sample ${meta.id} --bam-output ${mapped_gam} | samtools sort > ${meta.id}.sort.bam

		"""

	else if  (params.multiRef && meta.type == "modern" && meta.merged == true)	// User provided reference paths, GAM not interleaved
		"""

		# Surject GAM to each user provided list of reference paths

			for i in *.paths
				do
					prefix=`echo \$i | sed 's/\\.paths//'`
					vg surject -t ${task.cpus} -x ${graph} --into-paths \$i --sample ${meta.id} --bam-output ${mapped_gam} | samtools sort > ${meta.id}.\$prefix.sort.bam
				done

		"""

}
