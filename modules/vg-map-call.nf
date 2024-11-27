process VGMAPCALL {

	// Genotypes each mapped sample against variants present in the graph (not novel read variants)

	// Directives

	debug false
	tag "${meta.id}.${meta.repeat}"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/bcftools_htslib_samtools_vcfbub_vg:c247a9f35d75b27d'
	publishDir path: 'output/variant_calling/mapped_samples/vg-call', mode: 'move'

	// I/O & script

	input:
	path graph
	path snarls
	path ref_path_files
	tuple path(reference_fasta), path(index)
	tuple val(meta), path(mapped_gam)

	output:
	path "*.vcf.gz"
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

	script:
	if (!params.refPaths)  // Default reference paths
		"""

		# Calculate depth

			depth=`vg depth -t ${task.cpus} --gam ${mapped_gam} ${graph} | cut -f1 | sed 's/\\..*//'`

		# Compute read support

			vg pack -t ${task.cpus} -x ${graph} -g ${mapped_gam} -o ${meta.id}.${meta.repeat}.filtered.pack --expected-cov \$depth -Q 5

		# Reference will have PanSN format, raw VCF produced by vg call won't. Convert reference to align with VCF naming & reindex

			sed -i 's/.*#/>/g' ${reference_fasta}

			rm *.fai && samtools faidx reference.fasta

		# Genotype against all reference paths in the graph

			vg call -t ${task.cpus} ${graph} --pack ${meta.id}.${meta.repeat}.filtered.pack --min-support ${params.minimumAlleleSupport},${params.minimumSiteSupport} --baseline-error ${params.baselineErrorSmallVariants},${params.baselineErrorLargeVariants} --snarls ${snarls} --sample ${meta.id}.${meta.repeat} --genotype-snarls --all-snarls --gbz-translation --gbz --ploidy ${params.samplePloidy} | bgzip --threads ${task.cpus} > ${meta.id}.${meta.repeat}.raw.vcf.gz

		# Index raw VCF

			tabix -p vcf ${meta.id}.${meta.repeat}.raw.vcf.gz

		# Pop bubbles

			vcfbub --input ${meta.id}.${meta.repeat}.raw.vcf.gz --max-level ${params.maxNestLevel} --max-ref-length ${params.maxRefLength} | bcftools norm -f reference.fasta | bcftools sort | bgzip --threads ${task.cpus} > ${meta.id}.${meta.repeat}.filtered.vcf.gz

		# Clean up

			rm reference.fasta

		"""

	else if (params.refPaths)  // User reference paths
		"""

		# pass test runs

			touch PLACEHOLDER.vcf.gz

		# TODO: waiting for response to GitHub issue. Based on that, refactor the above to cycle through respective paths files
			# Strip ref-sample name from *.paths
				#meta.id}.meta.repeat}.\$prefix.raw.vcf.gz
				#meta.id}.meta.repeat}.\$prefix.filtered.vcf.gz

    		# -S, --ref-sample NAME   Call on all paths with given sample name (cannot be used with -p)

		"""

}
