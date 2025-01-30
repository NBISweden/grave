process PROFILEPMD {

	// Directives

	debug false
	tag "${meta.id}"
	label 'process_low'
	container 'oras://community.wave.seqera.io/library/damageprofiler_vg:accb8ffcbab94b7a'
	publishDir path: 'output/pmd_profiles', mode: 'copy'

	// I/O & script

	input:
	path ref_path_files
	tuple path(reference_fasta), path(fasta_index)
	tuple val(meta), path(surjected_bam), path(bam_index)

	output:
	path "*_pmd"
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions
	tuple val(task.process), val('damageprofiler'), eval('damageprofiler -version | sed "s/.* v//"'), topic: versions

	when:
	meta.type == 'ancient'

	script:
	if (!params.multiRef)	// Assume single reference sample
		"""

		# Find system Java max heap size & convert to GB

			max_heap_bytes=\$(java -XX:+PrintFlagsFinal 2>/dev/null | grep MaxHeapSize | grep -v Soft | awk '{print \$4}')

			max_heap_gb=\$(expr \$max_heap_bytes / 1024 / 1024 / 1024)

		# Run PMD profiling

			damageprofiler -Xms2g -Xmx\${max_heap_gb}g -i ${meta.id}.sort.dedup.bam -r ${reference_fasta} -o ${meta.id}_pmd -t 20 -l 100 -yaxis_dp_max 0.3

		"""

	else if (params.multiRef)	// When multi ref samples, run damageprofiler on each specific pair
		"""

		# Get reference sample prefixes from '.paths' files

			for i in *.paths
				do
					prefix=`echo \$i | sed 's/\\.paths//'`
					echo \$prefix >> referenceSamplePrefixes.txt
				done

		# Use path file basenames as keys to pair surjected BAMs to relevant FASTAs

			while read prefix
				do
					damageprofiler -i ${meta.id}.\$prefix.sort.dedup.bam -r \$prefix.fasta -o ${meta.id}_surjected_to_\${prefix}_pmd -t 20 -l 100 -yaxis_dp_max 0.3
				done < referenceSamplePrefixes.txt

		"""

}
