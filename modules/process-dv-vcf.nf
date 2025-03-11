process PROCESS_DEEPVARIANT {

	// Directives

	debug false
	tag "${meta.id}"
	label 'process_low'
	container 'oras://community.wave.seqera.io/library/bcftools_htslib_samtools_vcfbub_vg:5fc5e308ca96cd58'

	// I/O & script

	input:
	path ref_path_files
	tuple path(reference_fasta), path(index)
	tuple val(meta), path(deepvariant_vcf)

	output:
	path "*.norm.vcf.gz", emit: ch_deepvariant_norm_vcf
	path "*.raw.vcf.gz", optional: true, emit: ch_deepvariant_raw_vcf
	tuple val(task.process), val('bcftools'), eval('bcftools version | head -n 1 | sed "s/.* //"'), topic: versions
	tuple val(task.process), val('htslib'), eval('bgzip --version | head -n 1 | sed "s/.* //"'), topic: versions

	when:
	params.deepVariant == true

	script:
	def args = task.ext.args ?: ''

	if (!params.multiRef)	// Assume single reference sample
		"""

		# Zip raw VCF

			bgzip --threads ${task.cpus} ${deepvariant_vcf}

		# Normalise and sort (no bubbles to pop in DeepVariant VC)

			bcftools norm -f ${reference_fasta} ${meta.id}.raw.vcf.gz | bcftools sort | bgzip --threads ${task.cpus} > ${meta.id}.norm.vcf.gz

		# Clean up

			if [ "${params.keepRawVcf}" != "true" ]
				then
					rm ${meta.id}.raw.vcf.gz
			fi

		"""

	else if (params.multiRef)
		"""

		# Get reference sample prefixes from '.paths' files

			for i in *.paths
				do
					prefix=`echo \$i | sed 's/\\.paths//'`
					echo \$prefix >> referenceSamplePrefixes.txt
				done

		# Loop through each reference sample

			while read prefix

				do
	
					# Zip raw VCF

						bgzip --threads ${task.cpus} ${meta.id}.\$prefix.raw.vcf

					# Normalise and sort (no bubbles to pop in DeepVariant VC)

						bcftools norm -f \$prefix.fasta ${meta.id}.\$prefix.raw.vcf.gz | bcftools sort | bgzip --threads ${task.cpus} > ${meta.id}.\$prefix.norm.vcf.gz

					# Clean up

						if [ "${params.keepRawVcf}" != "true" ]
							then
								rm ${meta.id}.\$prefix.raw.vcf.gz
						fi

				done < referenceSamplePrefixes.txt

		# Clean up

			rm referenceSamplePrefixes.txt

		"""

}
