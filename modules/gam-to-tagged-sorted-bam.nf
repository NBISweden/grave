process GAM_TO_TAGGED_SORTED_BAM {

	// Projects GAM mappings to BAM against reference paths. If no user path files provided, uses vg defaults. If paths provided, each set is surjected to separately.

	// Directives

	debug false
	tag "${meta.read_group}"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/samtools_vg:7cf605b7343fd181'

	// I/O & script

	input:
	path graph
	path ref_path_files
	tuple val(meta), path(mapped_gam)

	output:
	tuple val(meta), path("${meta.read_group}*.bam"), emit: ch_surjected_bams
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions
	tuple val(task.process), val('samtools'), eval('samtools version | head -n 1 | sed "s/samtools //"'), topic: versions

	script:
	def args = task.ext.args ?: ''

	if (!params.multiRef && (meta.type == "ancient" || (meta.type == "modern" && meta.merged == true)))	// Default reference paths, GAM not interleaved
		"""

		# Surject GAM, add read group tags, sort by queryname

			vg surject -t ${task.cpus} -x ${graph} --bam-output ${mapped_gam} | \
			samtools addreplacerg --threads ${task.cpus} --output-fmt BAM -r '@RG\\tID:${meta.read_group}\\tLB:${meta.library}\\tSM:${meta.id}' - | \
			samtools sort --threads ${task.cpus} --output-fmt BAM - > \
			${meta.read_group}.bam

		"""

	else if (!params.multiRef && meta.type == "modern" && meta.merged == false)	// Default reference paths, GAM interleaved
		"""

		# Surject GAM, add read group tags, sort by queryname (interleaved)

			vg surject -t ${task.cpus} -x ${graph} --interleaved --bam-output ${mapped_gam} | \
			samtools addreplacerg --threads ${task.cpus} --output-fmt BAM -r '@RG\\tID:${meta.read_group}\\tLB:${meta.library}\\tSM:${meta.id}' - | \
			samtools sort --threads ${task.cpus} --output-fmt BAM - > \
			 ${meta.read_group}.bam

		"""

	else if (params.multiRef && (meta.type == "ancient" || (meta.type == "modern" && meta.merged == true)))	// User provided reference paths, GAM not interleaved
		"""

		# Surject GAM, add read group tags, sort by queryname (to each user provided list of reference paths)

			for i in *.paths
				do
					PREFIX=`echo \$i | sed 's/\\.paths//'`
					vg surject -t ${task.cpus} -x ${graph} --into-paths \$i --bam-output ${mapped_gam} | \
					samtools addreplacerg --threads ${task.cpus} --output-fmt BAM -r '@RG\\tID:${meta.read_group}\\tLB:${meta.library}\\tSM:${meta.id}' - | \
					samtools sort --threads ${task.cpus} --output-fmt BAM - > \
					${meta.read_group}.\$PREFIX.bam
				done

		"""

	else if  (params.multiRef && meta.type == "modern" && meta.merged == false)	// User provided reference paths, GAM interleaved
		"""

		# Surject GAM, add read group tags, sort by queryname (to each user provided list of reference paths, interleaved)

			for i in *.paths
				do
					PREFIX=`echo \$i | sed 's/\\.paths//'`
					vg surject -t ${task.cpus} -x ${graph} --into-paths \$i --interleaved --bam-output ${mapped_gam} | \
					samtools addreplacerg --threads ${task.cpus} --output-fmt BAM -r '@RG\\tID:${meta.read_group}\\tLB:${meta.library}\\tSM:${meta.id}' - | \
					samtools sort --threads ${task.cpus} --output-fmt BAM - > \
					${meta.read_group}.\$PREFIX.bam
				done

		"""

}
