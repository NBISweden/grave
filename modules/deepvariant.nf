process DEEPVARIANT {

	// Directives

	debug false
	tag "${meta.id}.${meta.repeat}"
	label 'process_high'
	container 'docker://google/deepvariant:1.6.1'
	publishDir path: 'output/quality_reports/deepvariant', mode: 'move', pattern: "*.html"

	// I/O & script

	input:
	path ref_path_files
	tuple path(reference_fasta), path(fasta_index)
	tuple val(meta), path(surjected_bam), path(bam_index)

	output:
	tuple val(meta), path("*.vcf"), emit: ch_raw_deepvariant_vcf
	tuple val(meta), path("*.html")
	tuple val(task.process), val('deepvariant'), eval('/opt/deepvariant/bin/run_deepvariant --version 2>/dev/null | sed "s/.*version //"'), topic: versions

	when:
	params.deepVariant == true

	script:
	if (!params.refPaths)	// Assume single reference sample
		"""

		# Run DeepVariant against the single reference sample

			/opt/deepvariant/bin/run_deepvariant \
				--num_shards ${task.cpus} \
				--sample_name ${meta.id}.${meta.repeat} \
				--ref ${reference_fasta} \
				--reads ${surjected_bam} \
				--output_vcf ${meta.id}.${meta.repeat}.raw.vcf \
				--model_type ${params.deepVariantModelType}

		"""

	else if (params.refPaths)
		"""

		# Get reference sample prefixes from '.paths' files

			for i in *.paths
				do
					prefix=`echo \$i | sed 's/\\.paths//'`
					echo \$prefix >> referenceSamplePrefixes.txt
				done

		# Run DeepVariant against each reference sample

			while read prefix

				do

					/opt/deepvariant/bin/run_deepvariant \
						--num_shards ${task.cpus} \
						--sample_name ${meta.id}.${meta.repeat} \
						--ref \$prefix.fasta \
						--reads ${meta.id}.${meta.repeat}.\$prefix.sort.bam \
						--output_vcf ${meta.id}.${meta.repeat}.\$prefix.raw.vcf \
						--model_type ${params.deepVariantModelType}

				done < referenceSamplePrefixes.txt

		"""

}
