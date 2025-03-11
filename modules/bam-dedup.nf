process BAM_DEDUP {

	// Secondary BAM deduplication

	// Directives

	debug false
	tag "${meta.id}"
	label 'process_low'
	container 'oras://community.wave.seqera.io/library/sambamba:53411ce753701297'

	// I/O & script

	input:
	path ref_path_files
	tuple val(meta), path(surjected_bams)

	output:
	path "*.sort.dedup.bam", emit: ch_sample_dedup_bams
	tuple val(meta), path("${meta.id}*.sort.dedup.bam"), path ("${meta.id}*.sort.dedup.bam.bai"), emit: ch_sample_dedup_indexed_bams
	tuple val(task.process), val('sambamba'), eval('sambamba --version 2>&1 | head -n 2 | tail -n 1 | sed "s/sambamba //"'), topic: versions

	script:
	if (!params.multiRef) // One reference sample
		"""

		# Deduplicate

			sambamba markdup --remove-duplicates -t ${task.cpus} ${meta.id}.sort.bam ${meta.id}.sort.dedup.bam

		"""

	else if (params.multiRef) // Multiple reference samples

		"""

		# Loop over reference samples

			for i in *.paths
				do
					prefix=`echo \$i | sed 's/\\.paths//'`
					sambamba markdup --remove-duplicates -t ${task.cpus} ${meta.id}.\$prefix.sort.bam ${meta.id}.\$prefix.sort.dedup.bam
				done

		"""

}
