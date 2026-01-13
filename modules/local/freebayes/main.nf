process FREEBAYES {

	// Directives

	debug false
	tag "${meta.id}"
	label 'process_high'
	container 'oras://community.wave.seqera.io/library/bamtools_bcftools_freebayes_htslib:cf23d815667a73b4'

	// I/O & script

	input:
	path ref_path_files
	tuple path(reference_fasta), path(fasta_index)
	tuple val(meta), path(bams), path(indexes)

	output:
	path("*.norm.vcf.gz"), emit: ch_freebayes_norm_vcf
	path("*.raw.vcf.gz"), optional: true, emit: ch_freebayes_raw_vcf
	tuple val(task.process), val('bamtools'), eval('bamtools --version | head -n 2 | tail -n 1 | sed "s/bamtools //"'), topic: versions
	tuple val(task.process), val('freebayes'), eval('freebayes --version | sed "s/version.*v//"'), topic: versions
	tuple val(task.process), val('htslib'), eval('bgzip --version | head -n 1 | sed "s/.* //"'), topic: versions
	tuple val(task.process), val('bcftools'), eval('bcftools version | head -n 1 | sed "s/.* //"'), topic: versions

	when:
	params.freeBayes == true

	script:
	def args = task.ext.args ?: ''

	if (!params.multiRef)	// Assume single reference sample
		"""

		# Generate equal coverage regions for parallelization

			bamtools coverage -in ${bams} | coverage_to_regions.py ${fasta_index} 500 > ${reference_fasta}.regions

		# Run FreeBayes against the single reference sample

			freebayes-parallel ${reference_fasta}.regions \
				${task.cpus} \
				--genotype-qualities \
				--fasta-reference ${reference_fasta} \
				--min-alternate-count ${params.minimumAlleleSupport} \
				--min-alternate-fraction ${params.minFraction} \
				--ploidy ${params.samplePloidy} \
				--max-complex-gap ${params.maxComplexGap} \
				${bams} | \
				bgzip --threads ${task.cpus} > \
				${meta.id}.raw.vcf.gz

		# Norm and sort

			bcftools norm -f ${reference_fasta} ${meta.id}.raw.vcf.gz | bcftools sort | bgzip --threads ${task.cpus} > ${meta.id}.norm.vcf.gz

		# Clean up

			if [ "${params.keepRawVcf}" != "true" ]
				then
					rm ${meta.id}.raw.vcf.gz
			fi

			rm ${reference_fasta}.regions

		"""

	else if (params.multiRef)
		"""

		# Run FreeBayes workflow against each reference sample

			for i in *.paths

				do

					PREFIX=`echo \$i | sed 's/\\.paths//'`

					# Generate equal coverage regions for parallelization

						bamtools coverage -in ${meta.id}.\$PREFIX.dedup.bam | coverage_to_regions.py \$PREFIX.fasta.fai 500 > \$PREFIX.regions

					# Run FreeBayes

						freebayes-parallel \$PREFIX.regions \
							${task.cpus} \
							--genotype-qualities \
							--fasta-reference \$PREFIX.fasta \
							--min-alternate-count ${params.minimumAlleleSupport} \
							--min-alternate-fraction ${params.minFraction} \
							--ploidy ${params.samplePloidy} \
							--max-complex-gap ${params.maxComplexGap} \
							${meta.id}.\$PREFIX.dedup.bam | \
							bgzip --threads ${task.cpus} > \
							${meta.id}.\$PREFIX.raw.vcf.gz

					# Norm and sort

						bcftools norm -f \$PREFIX.fasta ${meta.id}.\$PREFIX.raw.vcf.gz | bcftools sort | bgzip --threads ${task.cpus} > ${meta.id}.\$PREFIX.norm.vcf.gz

					# Clean up

						if [ "${params.keepRawVcf}" != "true" ]
							then
								rm ${meta.id}.\$PREFIX.raw.vcf.gz
						fi

						rm \$PREFIX.regions

				done

		"""

}
