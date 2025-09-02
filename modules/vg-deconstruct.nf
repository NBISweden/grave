process VG_DECONSTRUCT {

	// Output variants in the graph as VCF

	// Directives

	debug false
	tag "${graph.baseName}_graph"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/bcftools_htslib_samtools_vcfbub_vg:67444bca9edbce2a'

	// I/O & script

	input:
	path graph
	path snarls
	path ref_path_files
	tuple path(reference_fasta), path(index)

	output:
	path "*.filtered.vcf.gz", emit: ch_vg_deconstruct_filtered_vcf
	path "*.raw.vcf.gz", optional: true, emit: ch_vg_deconstruct_raw_vcf
	tuple val(task.process), val('bcftools'), eval('bcftools version | head -n 1 | sed "s/.* //"'), topic: versions
	tuple val(task.process), val('htslib'), eval('tabix --version | head -n 1 | sed "s/.* //"'), topic: versions
	tuple val(task.process), val('vcfbub'), eval('vcfbub --version | sed "s/.* //"'), topic: versions
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

	when:
	params.graphDeconstruct == true

	script:
	def args = task.ext.args ?: ''
	def basename = graph.baseName - '.gbz'

	if (!params.multiRef)  // Default reference paths
		"""

		# Make raw VCF of graph snarls relative to all reference paths

			vg deconstruct -t ${task.cpus} ${graph} --snarls ${snarls} ${args} --gbz-translation | bgzip --threads ${task.cpus} > ${basename}.raw.vcf.gz

		# Index raw VCF

			tabix -p vcf ${basename}.raw.vcf.gz

		# Pop bubbles (remove nested variants with nest level over 'maxNestLevel', plus any over 'maxRefLength' in length, then normalise VCF

			vcfbub --input ${basename}.raw.vcf.gz --max-level ${params.maxNestLevel} --max-ref-length ${params.maxRefLength} | bcftools norm -f ${reference_fasta} | bcftools sort | bgzip --threads ${task.cpus} > ${basename}.filtered.vcf.gz

		# Remove raw VCF + index unless overridden

			if [ "${params.keepRawVcf}" != "true" ]
				then
					rm ${basename}.raw.vcf.gz ${basename}.raw.vcf.gz.tbi
				else
					rm ${basename}.raw.vcf.gz.tbi
			fi

		"""

	else if (params.multiRef)  // User reference paths
		"""

		# Get reference sample prefixes from '.paths' files

			for i in *.paths
				do
					PREFIX=`echo \$i | sed 's/\\.paths//'`
					echo \$PREFIX >> referenceSamplePrefixes.txt
				done

		# Make raw VCFs relative to each provided reference sample

			while read line
				do
					vg deconstruct -t ${task.cpus} ${graph} --snarls ${snarls} ${args} --path-prefix \$line --gbz-translation | bgzip --threads ${task.cpus} > ${basename}.\$line.raw.vcf.gz
				done < referenceSamplePrefixes.txt

		# Index raw VCFs

			for i in *.raw.vcf.gz
				do
					tabix -p vcf \$i
				done

		# Pop bubbles and clean up raw VCF unless overridden

			while read line

				do

					vcfbub --input ${basename}.\$line.raw.vcf.gz --max-level ${params.maxNestLevel} --max-ref-length ${params.maxRefLength} | bcftools norm -f \$line.fasta | bcftools sort | bgzip --threads ${task.cpus} > ${basename}.\$line.filtered.vcf.gz

					if [ "${params.keepRawVcf}" != "true" ]
						then
							rm ${basename}.\$line.raw.vcf.gz ${basename}.\$line.raw.vcf.gz.tbi
						else
							rm ${basename}.\$line.raw.vcf.gz.tbi
					fi

				done < referenceSamplePrefixes.txt

		# Clean up

			rm referenceSamplePrefixes.txt

		"""

}
