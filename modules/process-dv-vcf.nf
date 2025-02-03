process DVPROCESSVCF {

	// Directives

	debug false
	tag "${meta.id}"
	label 'process_low'
	container 'oras://community.wave.seqera.io/library/bcftools_htslib_samtools_vcfbub_vg:c247a9f35d75b27d'
	publishDir path: 'output/variant_calling/mapped_samples/deepvariant', mode: 'copy'

	// I/O & script

	input:
	path ref_path_files
	tuple path(reference_fasta), path(index)
	tuple val(meta), path(deepvariant_vcf)

	output:
	path "*.norm.vcf.gz"
	tuple val(task.process), val('bcftools'), eval('bcftools version | head -n 1 | sed "s/.* //"'), topic: versions
	tuple val(task.process), val('htslib'), eval('bgzip --version | head -n 1 | sed "s/.* //"'), topic: versions

	when:
	params.deepVariant == true

	script:
	if (!params.multiRef)	// Assume single reference sample
		"""

		# Zip raw VCF

			bgzip --threads ${task.cpus} ${deepvariant_vcf}

		# Normalise and sort (no bubbles to pop in DeepVariant VC)

			bcftools norm -f ${reference_fasta} ${meta.id}.raw.vcf.gz | bcftools sort | bgzip --threads ${task.cpus} > ${meta.id}.norm.vcf.gz

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

				done < referenceSamplePrefixes.txt

		# Clean up

			rm referenceSamplePrefixes.txt

		"""

}
