process VGMAPCALL {

	// Genotypes each mapped sample against variants present in the graph (not novel read variants)

	// Directives

	debug false
	tag "${meta.id}"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/bcftools_htslib_samtools_vcfbub_vg:c247a9f35d75b27d'
	publishDir path: 'output/variant_calling/mapped_samples/vg-call', mode: 'copy'

	// I/O & script

	input:
	path graph
	path snarls
	path ref_path_files
	tuple path(reference_fasta), path(index)
	tuple val(meta), path(mapped_gam)

	output:
	path "*.filtered.vcf.gz"
	tuple val(task.process), val('bcftools'), eval('bcftools version | head -n 1 | sed "s/.* //"'), topic: versions
	tuple val(task.process), val('htslib'), eval('tabix --version | head -n 1 | sed "s/.* //"'), topic: versions
	tuple val(task.process), val('samtools'), eval('samtools version | head -n 1 | sed "s/samtools //"'), topic: versions
	tuple val(task.process), val('vcfbub'), eval('vcfbub --version | sed "s/.* //"'), topic: versions
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

	when:
	params.vgMapCall == true

	script:
	if (!params.multiRef)  // Default reference paths
		"""

		# Compute read support

			vg pack -t ${task.cpus} -x ${graph} -g ${mapped_gam} -o ${meta.id}.filtered.pack -Q 5

		# Reference will have PanSN format, raw VCF produced by vg call won't. Convert reference to align with VCF naming & reindex

			sed -i 's/.*#/>/g' ${reference_fasta}

		# Remove link to original index & recreate

			rm *.fai && samtools faidx reference.fasta

		# Genotype against all reference paths in the graph

			vg call -t ${task.cpus} ${graph} --pack ${meta.id}.filtered.pack --min-support ${params.minimumAlleleSupport},${params.minimumSiteSupport} --baseline-error ${params.baselineErrorSmallVariants},${params.baselineErrorLargeVariants} --snarls ${snarls} --sample ${meta.id} --genotype-snarls --all-snarls --gbz-translation --gbz --ploidy ${params.samplePloidy} | bgzip --threads ${task.cpus} > ${meta.id}.raw.vcf.gz

		# Index raw VCF

			tabix -p vcf ${meta.id}.raw.vcf.gz

		# Pop bubbles

			vcfbub --input ${meta.id}.raw.vcf.gz --max-level ${params.maxNestLevel} --max-ref-length ${params.maxRefLength} | bcftools norm -f reference.fasta | bcftools sort | bgzip --threads ${task.cpus} > ${meta.id}.filtered.vcf.gz

		# Clean up

			rm reference.fasta*
			rm *.filtered.pack

		"""

	else if (params.multiRef)  // User reference paths
		"""

		# Get reference sample prefixes from '.paths' files

			for i in *.paths
				do
					prefix=`echo \$i | sed 's/\\.paths//'`
					echo \$prefix >> referenceSamplePrefixes.txt
				done

		# Compute read support

			vg pack -t ${task.cpus} -x ${graph} -g ${mapped_gam} -o ${meta.id}.filtered.pack -Q 5

		# Loop through each reference sample

			while read prefix

				do

					# References will have PanSN format, raw VCFs produced by vg call won't. Convert references to align with VCF naming & reindex

						sed -i 's/.*#/>/g' \$prefix.fasta

					# Remove link to original index & recreate

						rm \$prefix.fasta.fai && samtools faidx \$prefix.fasta

					# Genotype against a specific reference sample in the graph

						vg call -t ${task.cpus} ${graph} --pack ${meta.id}.filtered.pack --ref-sample \$prefix --min-support ${params.minimumAlleleSupport},${params.minimumSiteSupport} --baseline-error ${params.baselineErrorSmallVariants},${params.baselineErrorLargeVariants} --snarls ${snarls} --sample ${meta.id} --genotype-snarls --all-snarls --gbz-translation --gbz --ploidy ${params.samplePloidy} | bgzip --threads ${task.cpus} > ${meta.id}.\$prefix.raw.vcf.gz

					# Index raw VCF

						tabix -p vcf ${meta.id}.\$prefix.raw.vcf.gz

					# Pop bubbles

						vcfbub --input ${meta.id}.\$prefix.raw.vcf.gz --max-level ${params.maxNestLevel} --max-ref-length ${params.maxRefLength} | bcftools norm -f \$prefix.fasta | bcftools sort | bgzip --threads ${task.cpus} > ${meta.id}.\$prefix.filtered.vcf.gz

					# Clean up

						rm \$prefix.fasta*

				done < referenceSamplePrefixes.txt

		# Clean up outside of loop

			rm *.filtered.pack

		"""

}
