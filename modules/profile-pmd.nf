process PROFILEPMD {

	// Directives

	debug false
	tag "${meta.id}.${meta.repeat}"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/damageprofiler_vg:accb8ffcbab94b7a'
	publishDir path: 'output/pmd_profiles', mode: 'move'

	// I/O & script

	input:
	tuple path(reference_fasta), path(index)
	tuple val(meta), path(surjected_bams)

	output:
	path "*_pmd"
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions
	tuple val(task.process), val('damageprofiler'), eval('damageprofiler -version | sed "s/.* v//"'), topic: versions

	when:
	meta.type == 'ancient'

	script:
	if (!params.refPaths)	// Assume single reference sample
		"""

		# Run PMD profiling

			damageprofiler -i ${meta.id}.${meta.repeat}.all_paths.bam -r ${reference_fasta} -o ${meta.id}_${meta.repeat}_pmd -t 20 -l 100 -yaxis_dp_max 0.3

		"""

	else if (params.refPaths)	// When multi ref samples, run damageprofiler on each specific pair
		"""

		# Extract path file basenames from the FASTA files

			for i in *.fasta
				do
					basename=`echo \$i | sed 's/\\.fasta//'`
					echo \$basename >> pathFileBaseNames.txt
				done

		# Use path file basenames as keys to pair surjected BAMs to relavant FASTAs

			while read line
				do
					damageprofiler -i ${meta.id}.${meta.repeat}.\$line.bam -r \$line.fasta -o ${meta.id}_${meta.repeat}_surjected_to_\${line}_pmd -t 20 -l 100 -yaxis_dp_max 0.3
				done < pathFileBaseNames.txt

		# Cleanup

			rm pathFileBaseNames.txt

		"""

}
