process VGMAPCALL {

	// Genotypes each mapped sample against variants present in the graph (not novel read variants)

	// Directives

	debug false
	tag "${meta.id}.${meta.repeat}"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/bcftools_vcfbub_htslib_vg:51f916c955092403'
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

		# Pre-filter GAM file to remove unmapped reads, apply MAPQ filter, minimum primary alignment score, and defray ambiguous alignment ends

			vg filter -t ${task.cpus} -x ${graph} ${mapped_gam} -r ${params.minimumScorePrimaryAlign} -fu --only-mapped -q ${params.minimumMapQFilter} -D 999 -v > ${meta.id}.${meta.repeat}.filtered.gam

		# Calculate depth

			depth=`vg depth -t ${task.cpus} --gam ${meta.id}.${meta.repeat}.filtered.gam ${graph} | cut -f1 | sed 's/\\..*//'`

		# Compute read support

			vg pack -t ${task.cpus} -x ${graph} -g ${meta.id}.${meta.repeat}.filtered.gam -o ${meta.id}.${meta.repeat}.filtered.pack --expected-cov \$depth -Q 5

		# Genotype against all reference paths in the graph
				# FIXME: Opened issue with vgteam -> `call` behaviour differs to `deconstruct`: strips the path info, leaving just contig name. Precludes using PanSN format. Would need to do contig names only instead, so that the reference remains compatible with the vcfs.

			vg call -t ${task.cpus} ${graph} --pack ${meta.id}.${meta.repeat}.filtered.pack --min-support ${params.minimumAlleleSupport},${params.minimumSiteSupport} --baseline-error ${params.baselineErrorSmallVariants},${params.baselineErrorLargeVariants} --snarls ${snarls} --sample ${meta.id}.${meta.repeat} --genotype-snarls --all-snarls --gbz-translation --gbz --ploidy ${params.samplePloidy} | bgzip --threads ${task.cpus} > ${meta.id}.${meta.repeat}.raw.vcf.gz

		# Index raw VCF

			tabix -p vcf ${meta.id}.${meta.repeat}.raw.vcf.gz

		# Pop bubbles 
				# FIXME: when above issue is fixed, establish whether this is required here. Are there any nested variants in the vcf?

			vcfbub --input ${meta.id}.${meta.repeat}.raw.vcf.gz --max-level ${params.maxNestLevel} --max-ref-length ${params.maxRefLength} | bcftools norm -f ${reference_fasta} | bcftools sort | bgzip --threads ${task.cpus} > ${meta.id}.${meta.repeat}.filtered.vcf.gz

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
