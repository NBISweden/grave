process VGSURJECT {

	// Projects GAM mappings to BAM against reference paths. If no user path files provided, uses vg defaults. If they are, each set of paths is surjected to separately.

	// Directives

	debug false
	tag "${meta.id}.${meta.repeat}"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/sambamba_samtools_vg:abc1a25a5c0cebba'
	publishDir path: 'output/mapped_files/bams', mode: 'copy', pattern: "*.sort.dedup.bam"

	// I/O & script

	input:
	path graph
	path ref_path_files
	tuple val(meta), path(mapped_gam)

	output:
	tuple val(meta), path("${meta.id}.${meta.repeat}*.sort.dedup.bam"), path ("${meta.id}.${meta.repeat}*.sort.dedup.bam.bai"), emit: ch_surjected_bams
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions
	tuple val(task.process), val('samtools'), eval('samtools version | head -n 1 | sed "s/samtools //"'), topic: versions
	tuple val(task.process), val('sambamba'), eval('sambamba --version 2>&1 | head -n 2 | tail -n 1 | sed "s/sambamba //"'), topic: versions

	script:
	if (!params.refPaths && meta.type == "ancient")	// Default reference paths, GAM not interleaved
		"""

		# Surject GAM to all reference paths

			vg surject -t ${task.cpus} -x ${graph} --sample ${meta.id}.${meta.repeat} --bam-output ${mapped_gam} | samtools sort > ${meta.id}.${meta.repeat}.sort.bam

		# Mark duplicates

			sambamba markdup --remove-duplicates -t ${task.cpus} ${meta.id}.${meta.repeat}.sort.bam ${meta.id}.${meta.repeat}.sort.dedup.bam

		"""

	else if (params.refPaths && meta.type == "ancient" )	// User provided reference paths, GAM not interleaved
		"""

		# Surject GAM to each user provided list of reference paths

			for i in *.paths
				do
					prefix=`echo \$i | sed 's/\\.paths//'`
					vg surject -t ${task.cpus} -x ${graph} --into-paths \$i --sample ${meta.id}.${meta.repeat} --bam-output ${mapped_gam} | samtools sort > ${meta.id}.${meta.repeat}.\$prefix.sort.bam
					sambamba markdup --remove-duplicates -t ${task.cpus} ${meta.id}.${meta.repeat}.\$prefix.sort.bam ${meta.id}.${meta.repeat}.\$prefix.sort.dedup.bam
				done

		"""

	else if (!params.refPaths && meta.type == "modern" && meta.merged == false)	// Default reference paths, GAM interleaved
		"""

		# Surject GAM to all reference paths, interleave

			vg surject -t ${task.cpus} -x ${graph} --sample ${meta.id}.${meta.repeat} --interleaved --bam-output ${mapped_gam} | samtools sort > ${meta.id}.${meta.repeat}.sort.bam

		# Mark duplicates

			sambamba markdup --remove-duplicates -t ${task.cpus} ${meta.id}.${meta.repeat}.sort.bam ${meta.id}.${meta.repeat}.sort.dedup.bam

		"""

	else if  (params.refPaths && meta.type == "modern" && meta.merged == false)	// User provided reference paths, GAM interleaved
		"""

		# Surject GAM to each user provided list of reference paths, interleave

			for i in *.paths
				do
					prefix=`echo \$i | sed 's/\\.paths//'`
					vg surject -t ${task.cpus} -x ${graph} --into-paths \$i --sample ${meta.id}.${meta.repeat} --interleaved --bam-output ${mapped_gam} | samtools sort > ${meta.id}.${meta.repeat}.\$prefix.sort.bam
					sambamba markdup --remove-duplicates -t ${task.cpus} ${meta.id}.${meta.repeat}.\$prefix.sort.bam ${meta.id}.${meta.repeat}.\$prefix.sort.dedup.bam
				done

		"""

	else if (!params.refPaths && meta.type == "modern" && meta.merged == true)	// Default reference paths, GAM not interleaved
		"""

		# Surject GAM to all reference paths

			vg surject -t ${task.cpus} -x ${graph} --sample ${meta.id}.${meta.repeat} --bam-output ${mapped_gam} | samtools sort > ${meta.id}.${meta.repeat}.sort.bam

		# Mark duplicates

			sambamba markdup --remove-duplicates -t ${task.cpus} ${meta.id}.${meta.repeat}.sort.bam ${meta.id}.${meta.repeat}.sort.dedup.bam

		"""

	else if  (params.refPaths && meta.type == "modern" && meta.merged == true)	// User provided reference paths, GAM not interleaved
		"""

		# Surject GAM to each user provided list of reference paths

			for i in *.paths
				do
					prefix=`echo \$i | sed 's/\\.paths//'`
					vg surject -t ${task.cpus} -x ${graph} --into-paths \$i --sample ${meta.id}.${meta.repeat} --bam-output ${mapped_gam} | samtools sort > ${meta.id}.${meta.repeat}.\$prefix.sort.bam
					sambamba markdup --remove-duplicates -t ${task.cpus} ${meta.id}.${meta.repeat}.\$prefix.sort.bam ${meta.id}.${meta.repeat}.\$prefix.sort.dedup.bam
				done

		"""

}
