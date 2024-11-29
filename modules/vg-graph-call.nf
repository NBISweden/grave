process VGGRAPHCALL {

	// Output variants in the graph as VCF, relative to selected paths

	// Directives

	debug false
	tag "${graph.baseName}_graph"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/bcftools_htslib_samtools_vcfbub_vg:c247a9f35d75b27d'
	publishDir path: 'output/variant_calling/graph', mode: 'move'

	// I/O & script

	input:
	path graph
	path snarls
	path ref_path_files
	tuple path(reference_fasta), path(index)

	output:
	path "*.vcf.gz"
	tuple val(task.process), val('bcftools'), eval('bcftools version | head -n 1 | sed "s/.* //"'), topic: versions
	tuple val(task.process), val('htslib'), eval('tabix --version | head -n 1 | sed "s/.* //"'), topic: versions
	tuple val(task.process), val('vcfbub'), eval('vcfbub --version | sed "s/.* //"'), topic: versions
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

	when:
	params.graphCall == true

	script:
	def basename = graph.baseName - '.gbz'

	if (!params.refPaths)  // Default reference paths
		"""

		# Make raw VCF of graph snarls relative to all reference paths

			vg deconstruct -t ${task.cpus} ${graph} --snarls ${snarls} --all-snarls --gbz-translation | bgzip --threads ${task.cpus} > ${basename}.raw.vcf.gz

		# Index raw VCF

			tabix -p vcf ${basename}.raw.vcf.gz

		# Pop bubbles (remove nested variants with nest level over 'maxNestLevel', plus any over 'maxRefLength' in length, then normalise VCF

			vcfbub --input ${basename}.raw.vcf.gz --max-level ${params.maxNestLevel} --max-ref-length ${params.maxRefLength} | bcftools norm -f ${reference_fasta} | bcftools sort | bgzip --threads ${task.cpus} > ${basename}.filtered.vcf.gz

		"""

	else if (params.refPaths)  // User reference paths
		"""

		# Get reference sample prefixes from '.paths' files

			for i in *.paths
				do
					prefix=`echo \$i | sed 's/\\.paths//'`
					echo \$prefix >> referenceSamplePrefixes.txt
				done

		# Make raw VCFs relative to each provided reference sample

			while read prefix
				do
					vg deconstruct -t ${task.cpus} ${graph} --snarls ${snarls} --path-prefix \$prefix --all-snarls --gbz-translation | bgzip --threads ${task.cpus} > ${basename}.\$prefix.raw.vcf.gz
				done < referenceSamplePrefixes.txt

		# Index raw VCFs

			for i in *.raw.vcf.gz
				do
					tabix -p vcf \$i
				done

		# Pop bubbles

			while read prefix
				do
					vcfbub --input ${basename}.\$prefix.raw.vcf.gz --max-level ${params.maxNestLevel} --max-ref-length ${params.maxRefLength} | bcftools norm -f \$prefix.fasta | bcftools sort | bgzip --threads ${task.cpus} > ${basename}.\$prefix.filtered.vcf.gz
				done < referenceSamplePrefixes.txt

		"""

}
