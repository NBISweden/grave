process DEEPVARIANT {

	// Directives

	debug false
	tag "${meta.id}"
	label 'process_high'
	container 'docker://google/deepvariant:1.6.1'
	publishDir path: 'output/quality_reports/deepvariant', mode: 'copy', pattern: "*.html"

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
	if (!params.multiRef)	// Assume single reference sample
		"""

		# Run DeepVariant against the single reference sample

			/opt/deepvariant/bin/run_deepvariant \
				--num_shards ${task.cpus} \
				--sample_name ${meta.id} \
				--ref ${reference_fasta} \
				--reads ${surjected_bam} \
				--output_vcf ${meta.id}.raw.vcf \
				--model_type ${params.deepVariantModelType}

		"""

	else if (params.multiRef)
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
						--sample_name ${meta.id} \
						--ref \$prefix.fasta \
						--reads ${meta.id}.\$prefix.sort.dedup.bam \
						--output_vcf ${meta.id}.\$prefix.raw.vcf \
						--model_type ${params.deepVariantModelType}

				done < referenceSamplePrefixes.txt

		# Clean up

			rm referenceSamplePrefixes.txt

		"""

}
